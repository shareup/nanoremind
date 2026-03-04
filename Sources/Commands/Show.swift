@preconcurrency import EventKit

func cmdShow(store: EKEventStore, args: ParsedArgs, json: Bool) {
    let id = args.flags["id"] ?? args.positional.first
    guard let id = id else {
        die("show requires --id <id>")
    }
    guard let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else {
        die("reminder not found: \(id)")
    }
    let detail = reminderDetail(reminder)
    if json {
        printJSON(detail)
    } else {
        printReminderDetailText(detail)
    }
}
