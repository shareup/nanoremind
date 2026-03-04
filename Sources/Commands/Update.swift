import Foundation
@preconcurrency import EventKit

func cmdReminderUpdate(store: EKEventStore, args: ParsedArgs, json: Bool) {
    guard let id = args.flags["id"] else { die("update requires --id") }
    guard let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else {
        die("reminder not found: \(id)")
    }
    guard reminder.calendar.allowsContentModifications else {
        die("list is read-only: \(reminder.calendar.title)")
    }

    if let title = args.flags["title"] { reminder.title = title }
    if let dueStr = args.flags["due"] {
        guard let dueDate = parseDate(dueStr) else { die("invalid --due date: \(dueStr)") }
        reminder.dueDateComponents = dateComponentsFrom(dueDate)
    }
    if let priorityStr = args.flags["priority"], let p = Int(priorityStr) {
        reminder.priority = p
    }
    if args.flags["flagged"] == "true" {
        reminder.priority = 1
    }
    if let notes = args.flags["notes"] { reminder.notes = notes }

    do {
        try store.save(reminder, commit: true)
        let detail = reminderDetail(reminder)
        if json {
            printJSON(detail)
        } else {
            printReminderUpdatedText(detail)
        }
    } catch {
        die("failed to update reminder: \(error.localizedDescription)")
    }
}
