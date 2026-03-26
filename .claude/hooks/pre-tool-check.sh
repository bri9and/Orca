#!/bin/bash
# Pre-tool-use hook: block dangerous commands
# Receives JSON on stdin with tool_name and tool_input
# Exit 0 = allow, Exit 2 = block (stderr shown to Claude)

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Block destructive bash commands
if [ "$TOOL_NAME" = "Bash" ]; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

  # Block rm -rf on project root or home
  if echo "$COMMAND" | grep -qE 'rm\s+-rf\s+(/Users|/home|~|\$HOME|/projects)\b'; then
    echo "Blocked: destructive rm -rf on protected path" >&2
    exit 2
  fi

  # Block force push to main/master
  if echo "$COMMAND" | grep -qE 'git\s+push\s+.*--force.*(main|master)'; then
    echo "Blocked: force push to main/master" >&2
    exit 2
  fi

  # Block dropping database tables
  if echo "$COMMAND" | grep -qiE 'drop\s+(table|database)'; then
    echo "Blocked: DROP TABLE/DATABASE requires manual confirmation" >&2
    exit 2
  fi
fi

# Block writes to .env files
if [ "$TOOL_NAME" = "Write" ] || [ "$TOOL_NAME" = "Edit" ]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
  if echo "$FILE_PATH" | grep -qE '\.env(\.local|\.production|\.staging)?$'; then
    echo "Blocked: direct write to env file — use environment variables" >&2
    exit 2
  fi
fi

exit 0
