#!/usr/bin/env bash
# PreToolUse guard for Write|Edit|MultiEdit on .swift files.
# Denies text that breaks a CleanLog convention a grep can see; everything else is the reviewer's job.
# Rules: .claude/conventions/architecture.md and code-style.md.

input=$(cat)

file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""')
case "$file" in
  *.swift) ;;
  *) exit 0 ;;
esac

text=$(printf '%s' "$input" | jq -r '
  [ .tool_input.content,
    .tool_input.new_string,
    ( .tool_input.edits[]?.new_string ) ]
  | map(select(. != null)) | join("\n")')

[ -z "$text" ] && exit 0

base=$(basename "$file")
violations=""

add() { violations="${violations}"$'\n'"  • $1"; }

# Fixed-string match.
has() { printf '%s' "$text" | grep -Fq -- "$1"; }
# Extended-regex match.
matches() { printf '%s' "$text" | grep -Eq -- "$1"; }

in_dir() { case "$file" in */CleanLog/"$1"/*) return 0 ;; *) return 1 ;; esac; }

# Observation, not Combine-era state.
has 'ObservableObject'    && add 'ObservableObject -> @Observable @MainActor final class'
has '@Published'          && add '@Published -> plain var in an @Observable class'
has '@StateObject'        && add '@StateObject -> @State private var viewModel'
has '@ObservedObject'     && add '@ObservedObject -> pass the @Observable model or a Bindable'
has '@EnvironmentObject'  && add '@EnvironmentObject -> @Environment(Type.self)'
matches '^import Combine' && add 'Combine -> async/await and AsyncStream'

# Concurrency.
has 'DispatchQueue'       && add 'DispatchQueue -> async/await, Task, MainActor'

# Safety and diagnostics.
has 'try!'                && add 'try! -> handle the error (or preconditionFailure with a reason)'
matches '(^|[^A-Za-z0-9_.])print\(' && add 'print( -> Logger from os'

# No comments in code.
matches '^[[:space:]]*//' && add 'comment line -> no comments in code; say it with a name or put the why in the commit'

# Deprecated or discouraged SwiftUI.
has 'NavigationView'      && add 'NavigationView -> NavigationStack'
has '.foregroundColor('   && add '.foregroundColor( -> .foregroundStyle('
has '.cornerRadius('      && add '.cornerRadius( -> .clipShape(.rect(cornerRadius:))'
has '.tabItem'            && add '.tabItem -> Tab(_:systemImage:value:)'
has 'AnyView'             && add 'AnyView -> @ViewBuilder or a concrete generic'

# Typography and colour.
has '.font(.system(size'  && add '.font(.system(size:)) -> a Dynamic Type text style'
has '.bold()'             && add '.bold() -> .weight(_:) on the text style'
matches 'Color\((red|hex|white):' && add 'inline colour -> a colorset token (Color.ink, …)'

# Formatters live in Formatting/.
if ! in_dir 'Formatting'; then
  has 'DateFormatter('    && add 'DateFormatter -> Formatting/'
  has 'NumberFormatter('  && add 'NumberFormatter -> Formatting/'
fi

# Layering.
if ! in_dir 'Persistence' && ! in_dir 'App' && ! in_dir 'CleanLogTests/Persistence'; then
  matches '^import SwiftData' && add 'import SwiftData outside Persistence/ and App/ -> go through a repository protocol'
  has '@Model'              && add '@Model outside Persistence/ -> domain value type in Models/'
fi
if in_dir 'Models' || in_dir 'Repositories' || in_dir 'Persistence' || in_dir 'Formatting'; then
  matches '^import (SwiftUI|UIKit)' && add "import SwiftUI/UIKit in $(dirname "$file" | xargs basename)/ -> this layer stays UI-free"
fi
if ! in_dir 'UICommons'; then
  has '.glassEffect('     && add '.glassEffect -> .glassSurface(_:) from UICommons/ (the only #available for glass)'
fi

if [ -n "$violations" ]; then
  reason="CleanLog convention violation in ${base}:${violations}"
  jq -n --arg r "$reason" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
fi

exit 0
