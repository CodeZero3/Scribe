import Foundation
@preconcurrency import SQLite3

struct DictationRecord: Identifiable, Sendable {
    let id: String
    let text: String
    let timestamp: Date
    let duration: TimeInterval
    let wordCount: Int
    let parentId: String?
    let optimizationMode: String?
}

/// Box holding the raw SQLite pointer, kept outside @Observable tracking.
/// Marked @unchecked Sendable so it can be accessed from nonisolated deinit.
/// In practice, all access is from MainActor except the final close in deinit.
private final class SQLiteHandle: @unchecked Sendable {
    var db: OpaquePointer?

    func open(path: String) {
        if sqlite3_open(path, &db) != SQLITE_OK {
            print("[HistoryStore] Failed to open database at \(path)")
        }
    }

    func close() {
        sqlite3_close(db)
        db = nil
    }
}

@Observable
@MainActor
final class HistoryStore {
    var records: [DictationRecord] = []
    private var allRecords: [DictationRecord] = []

    /// Database handle kept in a separate box so deinit can close it safely.
    @ObservationIgnored
    private let handle = SQLiteHandle()

    /// Convenience accessor
    private var db: OpaquePointer? { handle.db }

    init() {
        openDatabase()
        createTable()
        loadRecords()
    }

    private func openDatabase() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        let scribeDir = appSupport.appendingPathComponent("Scribe")
        try? FileManager.default.createDirectory(at: scribeDir, withIntermediateDirectories: true)
        let dbPath = scribeDir.appendingPathComponent("history.db").path

        handle.open(path: dbPath)
    }

    private func createTable() {
        let sql = """
            CREATE TABLE IF NOT EXISTS dictations (
                id TEXT PRIMARY KEY,
                text TEXT NOT NULL,
                timestamp REAL NOT NULL,
                duration REAL NOT NULL,
                word_count INTEGER NOT NULL,
                parent_id TEXT,
                optimization_mode TEXT
            )
        """
        sqlite3_exec(db, sql, nil, nil, nil)

        // Migration: add columns for existing databases
        sqlite3_exec(db, "ALTER TABLE dictations ADD COLUMN parent_id TEXT", nil, nil, nil)
        sqlite3_exec(db, "ALTER TABLE dictations ADD COLUMN optimization_mode TEXT", nil, nil, nil)
    }

    func addRecord(text: String, duration: TimeInterval) {
        let id = UUID().uuidString
        let timestamp = Date().timeIntervalSince1970
        let wordCount = text.split(separator: " ").count

        let sql = "INSERT INTO dictations (id, text, timestamp, duration, word_count) VALUES (?, ?, ?, ?, ?)"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (id as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (text as NSString).utf8String, -1, nil)
            sqlite3_bind_double(stmt, 3, timestamp)
            sqlite3_bind_double(stmt, 4, duration)
            sqlite3_bind_int(stmt, 5, Int32(wordCount))
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
        loadRecords()
    }

    @discardableResult
    func addOptimizedRecord(text: String, parentId: String, mode: String) -> DictationRecord {
        let id = UUID().uuidString
        let timestamp = Date().timeIntervalSince1970
        let wordCount = text.split(separator: " ").count

        let sql = "INSERT INTO dictations (id, text, timestamp, duration, word_count, parent_id, optimization_mode) VALUES (?, ?, ?, 0, ?, ?, ?)"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (id as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (text as NSString).utf8String, -1, nil)
            sqlite3_bind_double(stmt, 3, timestamp)
            sqlite3_bind_int(stmt, 4, Int32(wordCount))
            sqlite3_bind_text(stmt, 5, (parentId as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 6, (mode as NSString).utf8String, -1, nil)
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
        loadRecords()
        return DictationRecord(
            id: id, text: text, timestamp: Date(),
            duration: 0, wordCount: wordCount,
            parentId: parentId, optimizationMode: mode
        )
    }

    func optimizations(for parentId: String) -> [DictationRecord] {
        return allRecords.filter { $0.parentId == parentId }
    }

    func deleteRecord(_ record: DictationRecord) {
        // Delete child optimizations first
        let childSql = "DELETE FROM dictations WHERE parent_id = ?"
        var childStmt: OpaquePointer?
        if sqlite3_prepare_v2(db, childSql, -1, &childStmt, nil) == SQLITE_OK {
            sqlite3_bind_text(childStmt, 1, (record.id as NSString).utf8String, -1, nil)
            sqlite3_step(childStmt)
        }
        sqlite3_finalize(childStmt)

        // Delete the record itself
        let sql = "DELETE FROM dictations WHERE id = ?"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (record.id as NSString).utf8String, -1, nil)
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
        loadRecords()
    }

    func clearAll() {
        let sql = "DELETE FROM dictations"
        sqlite3_exec(db, sql, nil, nil, nil)
        loadRecords()
    }

    func search(query: String) -> [DictationRecord] {
        if query.isEmpty { return records }
        return records.filter { $0.text.localizedCaseInsensitiveContains(query) }
    }

    private func loadRecords() {
        var results: [DictationRecord] = []
        let sql = "SELECT id, text, timestamp, duration, word_count, parent_id, optimization_mode FROM dictations ORDER BY timestamp DESC"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                guard let idPtr = sqlite3_column_text(stmt, 0),
                      let textPtr = sqlite3_column_text(stmt, 1) else {
                    continue
                }
                let id = String(cString: idPtr)
                let text = String(cString: textPtr)
                let timestamp = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 2))
                let duration = sqlite3_column_double(stmt, 3)
                let wordCount = Int(sqlite3_column_int(stmt, 4))
                let parentId: String? = sqlite3_column_text(stmt, 5).map { String(cString: $0) }
                let optimizationMode: String? = sqlite3_column_text(stmt, 6).map { String(cString: $0) }
                results.append(DictationRecord(
                    id: id, text: text, timestamp: timestamp,
                    duration: duration, wordCount: wordCount,
                    parentId: parentId, optimizationMode: optimizationMode
                ))
            }
        }
        sqlite3_finalize(stmt)
        allRecords = results
        // Only show top-level records (not optimization children)
        records = results.filter { $0.parentId == nil }
    }

    deinit {
        // handle is a reference type; safe to access from nonisolated deinit
        handle.close()
    }
}
