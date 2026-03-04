import Foundation

// MARK: - Sanitization

func sanitize(_ text: String) -> String {
    var result = ""
    var i = text.startIndex
    while i < text.endIndex {
        let c = text[i]
        if c == "\u{1B}" {
            let next = text.index(after: i)
            if next < text.endIndex && text[next] == "[" {
                var j = text.index(after: next)
                while j < text.endIndex {
                    let ch = text[j]
                    if (ch >= "A" && ch <= "Z") || (ch >= "a" && ch <= "z") {
                        i = text.index(after: j)
                        break
                    }
                    j = text.index(after: j)
                }
                if j >= text.endIndex { i = j }
                continue
            }
            i = next
            continue
        }
        let scalar = c.unicodeScalars.first!.value
        if scalar < 0x20 && c != "\n" && c != "\t" {
            i = text.index(after: i)
            continue
        }
        if (0x7F...0x9F).contains(scalar) {
            i = text.index(after: i)
            continue
        }
        if c.unicodeScalars.first!.properties.isDefaultIgnorableCodePoint {
            i = text.index(after: i)
            continue
        }
        result.append(c)
        i = text.index(after: i)
    }
    return result
}

// MARK: - Date formatting

let relDateFmt: DateFormatter = {
    let f = DateFormatter()
    f.doesRelativeDateFormatting = true
    f.dateStyle = .medium
    f.timeStyle = .none
    return f
}()

let weekdayDateFmt: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "EEEE, MMM d, yyyy"
    return f
}()

let fullDateFmt: DateFormatter = {
    let f = DateFormatter()
    f.doesRelativeDateFormatting = true
    f.dateStyle = .medium
    f.timeStyle = .short
    return f
}()

func formatDate(_ date: Date) -> String {
    relDateFmt.string(from: date)
}

func formatDayHeader(_ date: Date) -> String {
    let rel = relDateFmt.string(from: date)
    let full = weekdayDateFmt.string(from: date)
    let cal = Calendar.current
    if cal.isDateInToday(date) || cal.isDateInTomorrow(date) || cal.isDateInYesterday(date) {
        return "\(rel), \(full)"
    }
    return full
}

func formatDateTime(_ date: Date) -> String {
    fullDateFmt.string(from: date)
}

// MARK: - Lists text

func printListsText(_ lists: [ReminderListInfo]) {
    if lists.isEmpty {
        print("No reminder lists found.")
        return
    }
    let nameWidth = max(4, lists.map { $0.title.count }.max()!)

    print("\("LIST".padding(toLength: nameWidth, withPad: " ", startingAt: 0))  INCOMPLETE")
    for list in lists {
        let name = sanitize(list.title).padding(toLength: nameWidth, withPad: " ", startingAt: 0)
        print("\(name)  \(list.incompleteCount)")
    }
}

// MARK: - Reminders text

func printRemindersText(_ reminders: [ReminderSummary], showIds: Bool = false) {
    if reminders.isEmpty {
        print("No reminders found.")
        return
    }
    for r in reminders {
        let check = r.isCompleted ? "[x]" : "[ ]"
        let title = sanitize(r.title)
        var line = "\(check) \(title)  [\(sanitize(r.list))]"
        if let due = r.dueDate {
            line += "  Due: \(formatDate(due))"
        }
        let label = priorityLabel(r.priority)
        if label != "none" {
            line += "  (\(label))"
        }
        print(line)
        if showIds {
            print("    ID: \(r.id)")
        }
    }
}

// MARK: - Next (grouped by list)

func printNextText(_ reminders: [ReminderSummary], showIds: Bool = false) {
    if reminders.isEmpty {
        print("No reminders found.")
        return
    }
    var currentList = ""
    for r in reminders {
        if r.list != currentList {
            if !currentList.isEmpty { print("") }
            currentList = r.list
            print(sanitize(currentList))
        }
        let title = sanitize(r.title)
        var line = "  [ ] \(title)"
        if let due = r.dueDate {
            line += "  Due: \(formatDate(due))"
        }
        let label = priorityLabel(r.priority)
        if label != "none" {
            line += "  (\(label))"
        }
        print(line)
        if showIds {
            print("      ID: \(r.id)")
        }
    }
}

// MARK: - Reminder detail text

func printReminderDetailText(_ detail: ReminderDetail) {
    print(sanitize(detail.title))
    print("  Status:       \(detail.isCompleted ? "completed" : "incomplete")")
    if let due = detail.dueDate {
        print("  Due:          \(formatDate(due))")
    }
    if detail.priorityLabel != "none" {
        print("  Priority:     \(detail.priorityLabel)")
    }
    if detail.flagged {
        print("  Flagged:      yes")
    }
    print("  List:         \(sanitize(detail.list))")
    if let notes = detail.notes, !notes.isEmpty {
        print("  Notes:        \(sanitize(notes).replacingOccurrences(of: "\n", with: ", "))")
    }
    if let url = detail.url, !url.isEmpty {
        print("  URL:          \(url)")
    }
    if let completed = detail.completionDate {
        print("  Completed:    \(formatDate(completed))")
    }
    if let rec = detail.recurrence, !rec.isEmpty {
        print("  Recurrence:   \(rec)")
    }
    if let created = detail.creationDate {
        print("  Created:      \(formatDate(created))")
    }
    print("  ID:           \(detail.id)")
}

// MARK: - Create/Complete/Update result text

func printReminderCreatedText(_ r: ReminderSummary) {
    print("Created: \(sanitize(r.title))")
    if let due = r.dueDate {
        print("  Due:  \(formatDate(due))")
    }
    print("  List: \(sanitize(r.list))")
}

func printReminderCompletedText(_ r: ReminderSummary) {
    print("Completed: \(sanitize(r.title))")
}

func printReminderUncompletedText(_ r: ReminderSummary) {
    print("Uncompleted: \(sanitize(r.title))")
}

func printReminderUpdatedText(_ detail: ReminderDetail) {
    print("Updated: \(sanitize(detail.title))")
    if let due = detail.dueDate {
        print("  Due:  \(formatDate(due))")
    }
    print("  List: \(sanitize(detail.list))")
}

// MARK: - Delete result text

func printDeletedText(_ id: String) {
    print("Deleted: \(id)")
}
