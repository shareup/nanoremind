@preconcurrency import EventKit

func cmdReminderDelete(store: EKEventStore, args: ParsedArgs, json: Bool) {
    guard let id = args.flags["id"] else { die("delete requires --id") }
    guard let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else {
        die("reminder not found: \(id)")
    }
    guard reminder.calendar.allowsContentModifications else {
        die("list is read-only: \(reminder.calendar.title)")
    }

    do {
        try store.remove(reminder, commit: true)
        if json {
            printJSON(["deleted": id])
        } else {
            printDeletedText(id)
        }
    } catch {
        die("failed to delete reminder: \(error.localizedDescription)")
    }
}
