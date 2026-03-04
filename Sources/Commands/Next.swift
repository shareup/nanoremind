import Foundation
@preconcurrency import EventKit

func cmdNext(store: EKEventStore, args: ParsedArgs, json: Bool) async {
    let perList = Int(args.flags["count"] ?? "3") ?? 3

    var calendars = store.calendars(for: .reminder)
    if let name = args.flags["l"] {
        calendars = [findReminderList(store: store, name: name)]
    }

    let predicate = store.predicateForIncompleteReminders(
        withDueDateStarting: nil, ending: nil, calendars: calendars)
    let allReminders = await fetchReminders(store: store, matching: predicate)

    let byList = Dictionary(grouping: allReminders, by: { $0.calendar.calendarIdentifier })

    var result: [ReminderSummary] = []
    for cal in calendars {
        guard var items = byList[cal.calendarIdentifier], !items.isEmpty else { continue }

        items.sort { a, b in
            let aDue = dateFromComponents(a.dueDateComponents)
            let bDue = dateFromComponents(b.dueDateComponents)
            if let ad = aDue, let bd = bDue { return ad < bd }
            if aDue != nil { return true }
            if bDue != nil { return false }
            return (a.title ?? "") < (b.title ?? "")
        }

        result.append(contentsOf: items.prefix(perList).map(reminderSummary))
    }

    if json {
        printJSON(result)
    } else {
        let showIds = args.flags["ids"] == "true"
        printNextText(result, showIds: showIds)
    }
}
