import Foundation
@preconcurrency import EventKit
import CoreGraphics

// MARK: - Arg parsing

struct ParsedArgs: Sendable {
    var flags: [String: String] = [:]
    var positional: [String] = []
}

func looksLikeFlag(_ arg: String) -> Bool {
    if arg.hasPrefix("--") { return true }
    if arg.hasPrefix("-") && arg.count == 2 && arg.last!.isLetter { return true }
    return false
}

private let booleanFlags: Set<String> = [
    "json", "ids", "completed", "incomplete", "flagged", "help", "h"
]

func parseArgs(_ args: [String]) -> ParsedArgs {
    var result = ParsedArgs()
    var i = 0
    while i < args.count {
        let arg = args[i]
        if arg == "--" {
            result.positional.append(contentsOf: args[(i + 1)...])
            break
        }
        if looksLikeFlag(arg) {
            let key: String
            if arg.hasPrefix("--") {
                key = String(arg.dropFirst(2))
            } else {
                key = String(arg.dropFirst(1))
            }
            if booleanFlags.contains(key) {
                result.flags[key] = "true"
            } else if i + 1 < args.count && !looksLikeFlag(args[i + 1]) {
                i += 1
                result.flags[key] = args[i]
            } else {
                die("flag --\(key) requires a value")
            }
        } else {
            result.positional.append(arg)
        }
        i += 1
    }
    return result
}

// MARK: - Date parsing

func parseDate(_ string: String) -> Date? {
    let iso = ISO8601DateFormatter()
    iso.formatOptions = [.withInternetDateTime]
    if let d = iso.date(from: string) { return d }

    let localDT = DateFormatter()
    localDT.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    localDT.timeZone = .current
    if let d = localDT.date(from: string) { return d }

    let dateOnly = DateFormatter()
    dateOnly.dateFormat = "yyyy-MM-dd"
    dateOnly.timeZone = .current
    if let d = dateOnly.date(from: string) { return d }

    return nil
}

// MARK: - Output helpers

nonisolated(unsafe) let isoFormatter: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    f.timeZone = .current
    return f
}()

func printJSON<T: Encodable>(_ value: T) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .custom { date, encoder in
        var container = encoder.singleValueContainer()
        try container.encode(isoFormatter.string(from: date))
    }
    guard let data = try? encoder.encode(value),
          let str = String(data: data, encoding: .utf8) else {
        die("JSON encoding failed")
    }
    print(str)
}

func die(_ message: String) -> Never {
    FileHandle.standardError.write(Data("nanoremind: \(message)\n".utf8))
    exit(1)
}

// MARK: - Reminder list lookup

func findReminderList(store: EKEventStore, name: String) -> EKCalendar {
    let cals = store.calendars(for: .reminder)
    if let cal = cals.first(where: { $0.title.caseInsensitiveCompare(name) == .orderedSame }) {
        return cal
    }
    let available = cals.map { $0.title }.joined(separator: ", ")
    die("list not found: \(name)\nAvailable: \(available)")
}

// MARK: - Color helper

func hexColor(_ color: CGColor) -> String {
    guard let rgb = color.converted(to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil),
          let c = rgb.components, c.count >= 3 else {
        return "#000000"
    }
    return String(format: "#%02X%02X%02X", Int(c[0] * 255), Int(c[1] * 255), Int(c[2] * 255))
}

// MARK: - Async fetch bridge

func fetchReminders(store: EKEventStore, matching predicate: NSPredicate) async -> [EKReminder] {
    await withCheckedContinuation { continuation in
        store.fetchReminders(matching: predicate) { reminders in
            nonisolated(unsafe) let result = reminders ?? []
            continuation.resume(returning: result)
        }
    }
}

// MARK: - Date component helpers

func dateFromComponents(_ components: DateComponents?) -> Date? {
    guard let c = components else { return nil }
    return Calendar.current.date(from: c)
}

func dateComponentsFrom(_ date: Date) -> DateComponents {
    Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
}

func startOfDay(_ date: Date = Date()) -> Date {
    Calendar.current.startOfDay(for: date)
}

// MARK: - Output types

struct ReminderListInfo: Encodable {
    let identifier: String
    let title: String
    let color: String
    let incompleteCount: Int
}

struct ReminderSummary: Encodable {
    let id: String
    let title: String
    let isCompleted: Bool
    let dueDate: Date?
    let priority: Int
    let flagged: Bool
    let list: String
}

struct ReminderDetail: Encodable {
    let id: String
    let title: String
    let isCompleted: Bool
    let completionDate: Date?
    let dueDate: Date?
    let priority: Int
    let priorityLabel: String
    let flagged: Bool
    let notes: String?
    let url: String?
    let list: String
    let creationDate: Date?
    let lastModifiedDate: Date?
    let recurrence: String?
}

// MARK: - Reminder conversion

func reminderSummary(_ reminder: EKReminder) -> ReminderSummary {
    ReminderSummary(
        id: reminder.calendarItemIdentifier,
        title: reminder.title ?? "(no title)",
        isCompleted: reminder.isCompleted,
        dueDate: dateFromComponents(reminder.dueDateComponents),
        priority: reminder.priority,
        flagged: reminder.priority >= 1 && reminder.priority <= 4,
        list: reminder.calendar.title
    )
}

func reminderDetail(_ reminder: EKReminder) -> ReminderDetail {
    let recurrence: String? = reminder.recurrenceRules?.first.map { rule in
        let unit = frequencyString(rule.frequency)
        var desc: String
        if rule.interval == 1 {
            desc = "every \(unit)"
        } else {
            desc = "every \(rule.interval) \(unit)s"
        }
        if let end = rule.recurrenceEnd {
            if let date = end.endDate {
                let fmt = DateFormatter()
                fmt.dateFormat = "yyyy-MM-dd"
                desc += " until \(fmt.string(from: date))"
            } else if end.occurrenceCount > 0 {
                desc += " (\(end.occurrenceCount) times)"
            }
        }
        return desc
    }

    return ReminderDetail(
        id: reminder.calendarItemIdentifier,
        title: reminder.title ?? "(no title)",
        isCompleted: reminder.isCompleted,
        completionDate: reminder.completionDate,
        dueDate: dateFromComponents(reminder.dueDateComponents),
        priority: reminder.priority,
        priorityLabel: priorityLabel(reminder.priority),
        flagged: reminder.priority >= 1 && reminder.priority <= 4,
        notes: reminder.notes,
        url: reminder.url?.absoluteString,
        list: reminder.calendar.title,
        creationDate: reminder.creationDate,
        lastModifiedDate: reminder.lastModifiedDate,
        recurrence: recurrence
    )
}

func priorityLabel(_ priority: Int) -> String {
    switch priority {
    case 0: return "none"
    case 1...4: return "high"
    case 5: return "medium"
    case 6...9: return "low"
    default: return "none"
    }
}

func frequencyString(_ freq: EKRecurrenceFrequency) -> String {
    switch freq {
    case .daily: return "day"
    case .weekly: return "week"
    case .monthly: return "month"
    case .yearly: return "year"
    @unknown default: return "unknown"
    }
}

// MARK: - Pagination

func paginate<T>(_ items: [T], args: ParsedArgs) -> [T] {
    var result = items
    let offset = Int(args.flags["offset"] ?? "0") ?? 0
    if offset > 0 {
        result = Array(result.dropFirst(offset))
    }
    if let limitStr = args.flags["limit"], let limit = Int(limitStr), limit > 0 {
        result = Array(result.prefix(limit))
    }
    return result
}
