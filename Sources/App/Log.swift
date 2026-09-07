import os

/// An agent app has no window to print into, so anything worth diagnosing has
/// to go somewhere you can read it:
///
///     log stream --predicate 'subsystem == "com.soloproc.knotch"' --level debug
enum Log {
    static let usage = Logger(subsystem: "com.soloproc.knotch", category: "usage")
    static let sessions = Logger(subsystem: "com.soloproc.knotch", category: "sessions")
}
