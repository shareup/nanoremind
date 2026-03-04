# nanoremind

**_Experimental. Shouldn't be considered production ready yet._**

A Swift CLI for reading and managing Apple Reminders on macOS.

Uses EventKit for full reminders access. Human-readable text by default, `--json` for structured output.

## Install

```bash
./install.sh
```

This builds a release binary and symlinks it to `~/bin/nanoremind`.

### Requirements

- macOS 14 (Sonoma) or later
- Swift 6.0+ (included with Xcode 16+)
- `~/bin` in your `PATH`

### Permissions

Grant your terminal app in **System Settings > Privacy & Security**:

- **Reminders** — full access (prompted on first run)

## Commands

```bash
# List all reminder lists
nanoremind lists

# List reminders in a list (default: incomplete)
nanoremind list -l "Reminders" --limit 10
nanoremind list -l "Reminders" --completed

# Full reminder details
nanoremind show --id "REMINDER-UUID"

# Search by title
nanoremind search "grocery"
nanoremind search "meeting" -l "Work"

# Reminders due today (includes overdue)
nanoremind today

# Next few reminders per list
nanoremind next
nanoremind next --count 5 -l "Work"

# Reminders due within N days (includes overdue)
nanoremind due --days 7

# Create a reminder
nanoremind create -l "Reminders" --title "Buy groceries" --due "2026-02-15"

# Mark complete/incomplete
nanoremind complete --id "REMINDER-UUID"
nanoremind uncomplete --id "REMINDER-UUID"

# Update a reminder
nanoremind update --id "REMINDER-UUID" --title "New title" --due "2026-02-20"

# Delete a reminder
nanoremind delete --id "REMINDER-UUID"

# Per-command help
nanoremind help list
```

## Global options

| Flag | Description |
|------|-------------|
| `--json` | Output JSON instead of human-readable text |
| `--ids` | Show reminder IDs in text output |
| `--limit N` | Max results to return |
| `--offset N` | Skip first N results (pagination) |

## Output format

Default output is human-readable text with relative dates ("Today", "Tomorrow", "Mar 14, 2026"). Use `--json` for structured JSON with ISO 8601 dates.

JSON shapes:

- **lists**: `identifier`, `title`, `color`, `incompleteCount`
- **list/search/due/today/next**: `id`, `title`, `isCompleted`, `dueDate`, `priority`, `flagged`, `list`
- **show**: all above plus `completionDate`, `priorityLabel`, `notes`, `url`, `creationDate`, `lastModifiedDate`, `recurrence`
- **create/complete/uncomplete**: returns reminder summary
- **update**: returns full reminder detail
- **delete**: `{"deleted": "<id>"}`

Priority values: `0`=none, `1`=high, `5`=medium, `9`=low.

## Testing

`TEST.md` contains integration test instructions designed to be run by a coding agent (like Claude Code). To run them:

```
claude -p "Read TEST.md and run all the tests. Report pass/fail for each."
```

## Use as a Claude Code skill

Symlink this repo into your project's `.claude/skills/`:

```bash
ln -s /path/to/nanoremind /your/project/.claude/skills/nanoremind
```

The repo root contains a `SKILL.md` that teaches Claude Code how to use nanoremind for reminders access.

## License

MIT
