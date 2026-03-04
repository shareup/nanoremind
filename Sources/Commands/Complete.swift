import Foundation
@preconcurrency import EventKit

func cmdComplete(store: EKEventStore, args: ParsedArgs, json: Bool) {
    guard let id = args.flags["id"] else { die("complete requires --id") }
    guard let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else {
        die("reminder not found: \(id)")
    }
    guard reminder.calendar.allowsContentModifications else {
        die("list is read-only: \(reminder.calendar.title)")
    }

    reminder.isCompleted = true
    reminder.completionDate = Date()

    do {
        try store.save(reminder, commit: true)
        let summary = reminderSummary(reminder)
        if json {
            printJSON(summary)
        } else {
            printReminderCompletedText(summary)
        }
    } catch {
        die("failed to complete reminder: \(error.localizedDescription)")
    }
}

func cmdUncomplete(store: EKEventStore, args: ParsedArgs, json: Bool) {
    guard let id = args.flags["id"] else { die("uncomplete requires --id") }
    guard let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else {
        die("reminder not found: \(id)")
    }
    guard reminder.calendar.allowsContentModifications else {
        die("list is read-only: \(reminder.calendar.title)")
    }

    reminder.isCompleted = false
    reminder.completionDate = nil

    do {
        try store.save(reminder, commit: true)
        let summary = reminderSummary(reminder)
        if json {
            printJSON(summary)
        } else {
            printReminderUncompletedText(summary)
        }
    } catch {
        die("failed to uncomplete reminder: \(error.localizedDescription)")
    }
}
