#!/usr/bin/env bash
# PostToolUse: lint the Swift file Claude just wrote with the repo's .swift-format.
# Exit 2 hands the findings back to Claude; the write itself is already done.

input=$(cat)

file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""')
case "$file" in
  *.swift) ;;
  *) exit 0 ;;
esac
[ -f "$file" ] || exit 0

config="$CLAUDE_PROJECT_DIR/.swift-format"
findings=$(xcrun swift-format lint --strict --configuration "$config" "$file" 2>&1)

if [ -n "$findings" ]; then
  printf 'swift-format found issues in %s — fix them before moving on:\n%s\n' "$(basename "$file")" "$findings" >&2
  exit 2
fi

exit 0
