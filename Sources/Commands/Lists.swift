import Foundation
@preconcurrency import EventKit

func cmdLists(store: EKEventStore, json: Bool) async {
    let cals = store.calendars(for: .reminder)

    let predicate = store.predicateForIncompleteReminders(
        withDueDateStarting: nil, ending: nil, calendars: nil)
    let incomplete = await fetchReminders(store: store, matching: predicate)
    let countsByCalId = Dictionary(grouping: incomplete, by: { $0.calendar.calendarIdentifier })
        .mapValues { $0.count }

    let result = cals.map { cal in
        ReminderListInfo(
            identifier: cal.calendarIdentifier,
            title: cal.title,
            color: hexColor(cal.cgColor),
            incompleteCount: countsByCalId[cal.calendarIdentifier] ?? 0
        )
    }
    if json {
        printJSON(result)
    } else {
        printListsText(result)
    }
}
