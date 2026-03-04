import Foundation
@preconcurrency import EventKit

func run() async {
    let rawArgs = Array(CommandLine.arguments.dropFirst())
    let command = rawArgs.first

    if command == nil || command == "--help" || command == "-h" {
        printUsage()
        exit(0)
    }

    if command == "help" {
        let sub = rawArgs.dropFirst().first
        if let sub = sub {
            printCommandHelp(sub)
        } else {
            printUsage()
        }
        exit(0)
    }

    let validCommands: Set = ["lists", "list", "show", "search", "create",
                               "complete", "uncomplete", "update", "delete", "due",
                               "today", "next"]
    guard validCommands.contains(command!) else {
        die("unknown command: \(command!)")
    }

    let parsed = parseArgs(Array(rawArgs.dropFirst()))
    let store = EKEventStore()

    do {
        let granted = try await store.requestFullAccessToReminders()
        guard granted else {
            die("Reminders access denied. Grant in System Settings > Privacy & Security > Reminders.")
        }
    } catch {
        die("Access request failed: \(error.localizedDescription)")
    }

    let json = parsed.flags["json"] == "true"

    switch command {
    case "lists":      await cmdLists(store: store, json: json)
    case "list":       await cmdList(store: store, args: parsed, json: json)
    case "show":       cmdShow(store: store, args: parsed, json: json)
    case "search":     await cmdSearch(store: store, args: parsed, json: json)
    case "create":     cmdReminderCreate(store: store, args: parsed, json: json)
    case "complete":   cmdComplete(store: store, args: parsed, json: json)
    case "uncomplete": cmdUncomplete(store: store, args: parsed, json: json)
    case "update":     cmdReminderUpdate(store: store, args: parsed, json: json)
    case "delete":     cmdReminderDelete(store: store, args: parsed, json: json)
    case "due":        await cmdDue(store: store, args: parsed, json: json)
    case "today":      await cmdToday(store: store, args: parsed, json: json)
    case "next":       await cmdNext(store: store, args: parsed, json: json)
    default:           die("unknown command: \(command!)")
    }
}

func printUsage() {
    print("""
    Usage: nanoremind <command> [options]

    Commands:
      lists         List reminder lists
      list          List reminders in a list
      show          Full reminder details
      search        Search reminders by title
      create        Create a reminder
      complete      Mark reminder complete
      uncomplete    Mark reminder incomplete
      update        Update a reminder
      delete        Delete a reminder
      due           Reminders due within N days
      today         Reminders due today (includes overdue)
      next          Next few reminders per list
      help          Show help for a command

    Global options:
      --json        Output JSON instead of human-readable text
      --ids         Show reminder IDs in text output

    Run 'nanoremind help <command>' for details.
    """)
}

func printCommandHelp(_ command: String) {
    switch command {
    case "lists":
        print("""
        Usage: nanoremind lists [--json]

        List all reminder lists with incomplete count.
        """)
    case "list":
        print("""
        Usage: nanoremind list -l <list> [options]

        List reminders in a list. Shows incomplete reminders by default.

        Options:
          -l <list>         List name (required, case-insensitive)
          --completed       Show completed reminders
          --incomplete      Show incomplete reminders (default)
          --limit <n>       Max reminders to return
          --offset <n>      Skip first N reminders
          --ids             Show reminder IDs
          --json            Output JSON
        """)
    case "show":
        print("""
        Usage: nanoremind show --id <id> [--json]
               nanoremind show <id> [--json]

        Show full details for a reminder.
        """)
    case "search":
        print("""
        Usage: nanoremind search <query> [options]

        Search reminders by title (case-insensitive, diacritic-insensitive).

        Options:
          -l <list>         Filter by list name (case-insensitive)
          --limit <n>       Max results to return
          --offset <n>      Skip first N results
          --ids             Show reminder IDs
          --json            Output JSON
        """)
    case "create":
        print("""
        Usage: nanoremind create -l <list> --title <title> [options]

        Create a new reminder.

        Options:
          -l <list>         List name (required, case-insensitive)
          --title <title>   Reminder title (required)
          --due <date>      Due date
          --priority <n>    Priority: 0=none, 1=high, 5=medium, 9=low
          --flagged         Shortcut for --priority 1
          --notes <text>    Reminder notes
          --json            Output JSON
        """)
    case "complete":
        print("""
        Usage: nanoremind complete --id <id> [--json]

        Mark a reminder as complete.
        """)
    case "uncomplete":
        print("""
        Usage: nanoremind uncomplete --id <id> [--json]

        Mark a reminder as incomplete.
        """)
    case "update":
        print("""
        Usage: nanoremind update --id <id> [options]

        Update a reminder. Only specified fields are changed.

        Options:
          --id <id>         Reminder ID (required)
          --title <title>   New title
          --due <date>      New due date
          --priority <n>    Priority: 0=none, 1=high, 5=medium, 9=low
          --flagged         Shortcut for --priority 1
          --notes <text>    New notes
          --json            Output JSON
        """)
    case "delete":
        print("""
        Usage: nanoremind delete --id <id> [--json]

        Delete a reminder.
        """)
    case "due":
        print("""
        Usage: nanoremind due [options]

        List incomplete reminders due within N days (default 7).
        Includes overdue reminders.

        Options:
          --days <n>        Number of days ahead (default: 7)
          -l <list>         Filter by list name (case-insensitive)
          --limit <n>       Max results to return
          --offset <n>      Skip first N results
          --ids             Show reminder IDs
          --json            Output JSON
        """)
    case "today":
        print("""
        Usage: nanoremind today [options]

        List incomplete reminders due today, including overdue.

        Options:
          -l <list>         Filter by list name (case-insensitive)
          --limit <n>       Max results to return
          --offset <n>      Skip first N results
          --ids             Show reminder IDs
          --json            Output JSON
        """)
    case "next":
        print("""
        Usage: nanoremind next [options]

        Show the next few incomplete reminders per list (default 3).
        Sorted by due date within each list.

        Options:
          --count <n>       Reminders per list (default: 3)
          -l <list>         Filter to a single list
          --ids             Show reminder IDs
          --json            Output JSON
        """)
    default:
        die("unknown command: \(command)")
    }
}

await run()
