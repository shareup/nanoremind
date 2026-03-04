# nanoremind Integration Tests

Run these tests manually using the built binary. Each test describes what to
run, what to check, and when to ask the user for help.

Use `nanoremind` from `~/bin/nanoremind` (the installed release build).

## Setup

Before starting, verify the binary is installed and working:

```bash
nanoremind help
```

Expect: usage text listing all commands (lists, list, show, search, create,
complete, uncomplete, update, delete, due, help) and global options (--json, --ids).

---

## 1. Lists

### 1a. Default text output

```bash
nanoremind lists
```

Check:
- Columnar output: LIST, INCOMPLETE
- At least one list shown
- Incomplete counts are numbers
- No raw JSON

### 1b. JSON output

```bash
nanoremind lists --json
```

Check:
- Valid JSON array
- Each object has: identifier (string), title (string), color (string starting with #), incompleteCount (number)

---

## 2. List

### 2a. Default text output (incomplete)

Pick a list name from the lists output.

```bash
nanoremind list -l "<ListName>"
```

Check:
- Shows reminders with `[ ]` for incomplete
- Each reminder shows title and [ListName]
- Due dates shown where applicable
- Priority shown in parentheses where applicable (high, medium, low)
- No raw JSON
- No reminder IDs shown by default

### 2b. JSON output

```bash
nanoremind list -l "<ListName>" --json
```

Check:
- Valid JSON array
- Each object has: id, title, isCompleted (boolean), priority (number), flagged (boolean), list (string)
- dueDate present when set (ISO 8601 with fractional seconds)

### 2c. Completed reminders

```bash
nanoremind list -l "<ListName>" --completed
```

Check:
- Shows reminders with `[x]` for completed
- Different results from 2a

### 2d. Pagination

```bash
nanoremind list -l "<ListName>" --limit 2
nanoremind list -l "<ListName>" --limit 2 --offset 2
```

Check:
- First returns at most 2 reminders
- Second returns different reminders (no overlap)
- If fewer than 4 reminders, ask the user to create a few test reminders

### 2e. IDs flag

```bash
nanoremind list -l "<ListName>" --ids
```

Check:
- Same output as 2a but each reminder has an indented "ID: <uuid>" line below it

---

## 3. Show

### 3a. Show reminder details

Pick a reminder ID (use `--ids` or `--json` to get the `id` field).

```bash
nanoremind show --id "<REMINDER-ID>"
```

Check:
- Shows title, status, list, and ID
- Shows due date, priority, notes, URL, recurrence where applicable
- Shows creation date

### 3b. Positional ID

```bash
nanoremind show "<REMINDER-ID>"
```

Check:
- Same behavior as `--id <REMINDER-ID>`

### 3c. JSON output

```bash
nanoremind show --id "<REMINDER-ID>" --json
```

Check:
- Valid JSON object
- Has all fields: id, title, isCompleted, priority, priorityLabel, flagged, list, creationDate
- Optional fields present when applicable: dueDate, completionDate, notes, url, recurrence

### 3d. Invalid ID

```bash
nanoremind show --id "nonexistent-id-12345" 2>&1
```

Check:
- Error on stderr: "nanoremind: reminder not found: nonexistent-id-12345"
- Non-zero exit code

---

## 4. Search

### 4a. Basic search

Pick a word that appears in at least one reminder title.

```bash
nanoremind search "<word>"
```

Check:
- All results contain the search term in the title (case-insensitive)
- Shows reminder list, due date, priority where applicable

### 4b. Search within a list

```bash
nanoremind search "<word>" -l "<ListName>"
```

Check:
- All results are from the specified list only

### 4c. No matches

```bash
nanoremind search "xyzzy_nonexistent_string_12345"
```

Check:
- Output: "No reminders found."
- No errors

### 4d. Pagination

```bash
nanoremind search "<common word>" --limit 2
nanoremind search "<common word>" --limit 2 --offset 2
```

Check:
- First returns at most 2 results
- Second returns different results

---

## 5. Due

### 5a. Default (7 days)

```bash
nanoremind due
```

Check:
- Shows incomplete reminders due within the next 7 days
- Includes overdue reminders (if any)
- Sorted by due date

### 5b. Custom days

```bash
nanoremind due --days 30
```

Check:
- May include more reminders than the 7-day default

### 5c. Filter by list

```bash
nanoremind due -l "<ListName>"
```

Check:
- Only reminders from the specified list

### 5d. JSON output

```bash
nanoremind due --json
```

Check:
- Valid JSON array of reminder summaries

---

## 6. Create (skip unless user approves)

**Only run these if the user explicitly approves creating test reminders.**

### 6a. Missing required args

```bash
nanoremind create 2>&1
nanoremind create -l "Reminders" 2>&1
```

Check:
- First errors about missing -l
- Second errors about missing --title

### 6b. Create reminder (if approved)

Ask the user for a list name to create test reminders in.

```bash
nanoremind create -l "<ListName>" --title "nanoremind test reminder" --due "2026-12-25" --priority 5 --notes "Created by test"
```

Check:
- Output: "Created: nanoremind test reminder" with due date and list
- Save the reminder ID for later tests (use --json to get it)

### 6c. JSON create

```bash
nanoremind create -l "<ListName>" --title "nanoremind JSON test" --json
```

Check:
- Valid JSON with reminder summary fields

---

## 7. Complete/Uncomplete (skip unless create test ran)

### 7a. Complete

Use a reminder ID from the create test.

```bash
nanoremind complete --id "<REMINDER-ID>"
```

Check:
- Output: "Completed: nanoremind test reminder"

### 7b. Verify completion

```bash
nanoremind show --id "<REMINDER-ID>"
```

Check:
- Status shows "completed"
- Completion date is shown

### 7c. Uncomplete

```bash
nanoremind uncomplete --id "<REMINDER-ID>"
```

Check:
- Output: "Uncompleted: nanoremind test reminder"

---

## 8. Update (skip unless create test ran)

### 8a. Update reminder

```bash
nanoremind update --id "<REMINDER-ID>" --title "nanoremind UPDATED test" --priority 1
```

Check:
- Output: "Updated: nanoremind UPDATED test" with list info

### 8b. Missing ID

```bash
nanoremind update --title "test" 2>&1
```

Check:
- Error: "nanoremind: update requires --id"

---

## 9. Delete (skip unless create test ran)

### 9a. Delete reminder

Use the reminder IDs from the create tests.

```bash
nanoremind delete --id "<REMINDER-ID>"
```

Check:
- Output: "Deleted: <REMINDER-ID>"

### 9b. Verify deletion

```bash
nanoremind show --id "<REMINDER-ID>" 2>&1
```

Check:
- Error: "nanoremind: reminder not found: <REMINDER-ID>"

### 9c. Missing ID

```bash
nanoremind delete 2>&1
```

Check:
- Error: "nanoremind: delete requires --id"

---

## 10. Help

### 10a. Global help

```bash
nanoremind help
```

Check:
- Lists all commands
- Shows --json and --ids as global options

### 10b. Per-command help

```bash
nanoremind help list
nanoremind help create
nanoremind help due
```

Check:
- Each shows usage, description, and options
- `list` mentions -l, --completed, --incomplete, --limit, --offset, --ids
- `create` mentions -l, --title, --due, --priority, --flagged, --notes
- `due` mentions --days, -l, --limit, --offset

### 10c. Help aliases

```bash
nanoremind --help
nanoremind -h
```

Check:
- Both show the same global help as `nanoremind help`

---

## 11. Edge cases

### 11a. No arguments

```bash
nanoremind
```

Check:
- Shows usage help (same as `nanoremind help`)

### 11b. Unknown command

```bash
nanoremind foobar 2>&1
```

Check:
- Error on stderr: "nanoremind: unknown command: foobar"
- Exit code is non-zero

### 11c. Missing list name

```bash
nanoremind list 2>&1
```

Check:
- Error: "nanoremind: list requires -l <list>"

### 11d. Missing search query

```bash
nanoremind search 2>&1
```

Check:
- Error: "nanoremind: search requires a query"
