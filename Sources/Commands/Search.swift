import Foundation
@preconcurrency import EventKit

func cmdSearch(store: EKEventStore, args: ParsedArgs, json: Bool) async {
    guard let query = args.positional.first else { die("search requires a query") }

    var calendars: [EKCalendar]? = nil
    if let name = args.flags["l"] {
        calendars = [findReminderList(store: store, name: name)]
    }

    let predicate = store.predicateForReminders(in: calendars)
    let all = await fetchReminders(store: store, matching: predicate)
    let filtered = all.filter {
        ($0.title ?? "").range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }
    let summaries = paginate(filtered, args: args).map(reminderSummary)

    if json {
        printJSON(summaries)
    } else {
        printRemindersText(summaries, showIds: args.flags["ids"] == "true")
    }
}
