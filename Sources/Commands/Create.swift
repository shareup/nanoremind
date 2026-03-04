import Foundation
@preconcurrency import EventKit

func cmdReminderCreate(store: EKEventStore, args: ParsedArgs, json: Bool) {
    guard let listName = args.flags["l"] else { die("create requires -l <list>") }
    guard let title = args.flags["title"] else { die("create requires --title") }

    let cal = findReminderList(store: store, name: listName)
    guard cal.allowsContentModifications else { die("list is read-only: \(listName)") }

    let reminder = EKReminder(eventStore: store)
    reminder.title = title
    reminder.calendar = cal

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
        let summary = reminderSummary(reminder)
        if json {
            printJSON(summary)
        } else {
            printReminderCreatedText(summary)
        }
    } catch {
        die("failed to create reminder: \(error.localizedDescription)")
    }
}
