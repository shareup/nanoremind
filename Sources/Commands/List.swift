import Foundation
@preconcurrency import EventKit

func cmdList(store: EKEventStore, args: ParsedArgs, json: Bool) async {
    guard let name = args.flags["l"] else { die("list requires -l <list>") }
    let cal = findReminderList(store: store, name: name)

    let showCompleted = args.flags["completed"] == "true"
    let showIncomplete = args.flags["incomplete"] == "true" || !showCompleted

    var reminders: [EKReminder]

    if showIncomplete && showCompleted {
        let predicate = store.predicateForReminders(in: [cal])
        reminders = await fetchReminders(store: store, matching: predicate)
    } else if showCompleted {
        let predicate = store.predicateForCompletedReminders(
            withCompletionDateStarting: nil, ending: nil, calendars: [cal])
        reminders = await fetchReminders(store: store, matching: predicate)
    } else {
        let predicate = store.predicateForIncompleteReminders(
            withDueDateStarting: nil, ending: nil, calendars: [cal])
        reminders = await fetchReminders(store: store, matching: predicate)
    }

    reminders.sort { a, b in
        let aDue = dateFromComponents(a.dueDateComponents)
        let bDue = dateFromComponents(b.dueDateComponents)
        if let ad = aDue, let bd = bDue { return ad < bd }
        if aDue != nil { return true }
        if bDue != nil { return false }
        return (a.title ?? "") < (b.title ?? "")
    }

    reminders = paginate(reminders, args: args)
    let summaries = reminders.map(reminderSummary)

    if json {
        printJSON(summaries)
    } else {
        printRemindersText(summaries, showIds: args.flags["ids"] == "true")
    }
}
