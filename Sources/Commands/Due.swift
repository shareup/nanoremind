import Foundation
@preconcurrency import EventKit

func cmdDue(store: EKEventStore, args: ParsedArgs, json: Bool) async {
    let days = Int(args.flags["days"] ?? "7") ?? 7
    guard let to = Calendar.current.date(byAdding: .day, value: days, to: startOfDay()) else {
        die("failed to compute date range")
    }

    var calendars: [EKCalendar]? = nil
    if let name = args.flags["l"] {
        calendars = [findReminderList(store: store, name: name)]
    }

    let predicate = store.predicateForIncompleteReminders(
        withDueDateStarting: Date.distantPast, ending: to, calendars: calendars)
    var reminders = await fetchReminders(store: store, matching: predicate)

    reminders.sort { a, b in
        let aDue = dateFromComponents(a.dueDateComponents)
        let bDue = dateFromComponents(b.dueDateComponents)
        if let ad = aDue, let bd = bDue { return ad < bd }
        if aDue != nil { return true }
        if bDue != nil { return false }
        return (a.title ?? "") < (b.title ?? "")
    }

    let summaries = paginate(reminders, args: args).map(reminderSummary)

    if json {
        printJSON(summaries)
    } else {
        printRemindersText(summaries, showIds: args.flags["ids"] == "true")
    }
}
