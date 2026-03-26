#!/bin/bash
# Post-tool-use hook: verify after file edits
# Runs lint/typecheck on the affected project after Edit/Write
# Exit 0 = ok, non-zero stderr = feedback to Claude

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

# Only run after file edits
if [ "$TOOL_NAME" != "Edit" ] && [ "$TOOL_NAME" != "Write" ]; then
  exit 0
fi

# Find the nearest package.json
DIR=$(dirname "$FILE_PATH")
while [ "$DIR" != "/" ] && [ ! -f "$DIR/package.json" ]; do
  DIR=$(dirname "$DIR")
done

if [ ! -f "$DIR/package.json" ]; then
  exit 0
fi

# Run typecheck if available
if grep -q '"typecheck"' "$DIR/package.json"; then
  OUTPUT=$(cd "$DIR" && npm run typecheck 2>&1)
  if [ $? -ne 0 ]; then
    echo "Typecheck failed after editing $FILE_PATH:" >&2
    echo "$OUTPUT" | tail -20 >&2
    exit 0  # Don't block, just inform
  fi
fi

exit 0
