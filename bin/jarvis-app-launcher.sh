#!/usr/bin/env bash
set -euo pipefail

DASHBOARD_DIR="/Users/cbas-mini/projects/orchestrator/dashboard"
PORT=3001
LOG_FILE="$HOME/.jarvis.log"
PID_FILE="$HOME/.jarvis.pid"

# Source user profile for PATH, node, npm, env vars
if [[ -f "$HOME/.zprofile" ]]; then
  source "$HOME/.zprofile" 2>/dev/null || true
fi
if [[ -f "$HOME/.zshrc" ]]; then
  source "$HOME/.zshrc" 2>/dev/null || true
fi

# Check if already running
if [[ -f "$PID_FILE" ]]; then
  EXISTING_PID=$(cat "$PID_FILE")
  if kill -0 "$EXISTING_PID" 2>/dev/null; then
    open "http://localhost:$PORT"
    exit 0
  else
    rm -f "$PID_FILE"
  fi
fi

# Preflight: check node
if ! command -v node &>/dev/null; then
  osascript -e 'display dialog "Node.js is not installed.\n\nInstall it from https://nodejs.org or:\n  brew install node" buttons {"OK"} default button "OK" with title "Jarvis" with icon stop'
  exit 1
fi

# Preflight: check dashboard
if [[ ! -d "$DASHBOARD_DIR" ]]; then
  osascript -e 'display dialog "Dashboard not found.\n\nRun: git submodule update --init" buttons {"OK"} default button "OK" with title "Jarvis" with icon stop'
  exit 1
fi

# Install deps if needed
if [[ ! -d "$DASHBOARD_DIR/node_modules" ]]; then
  cd "$DASHBOARD_DIR" && npm install >> "$LOG_FILE" 2>&1
fi

# Clean stale lock
rm -f "$DASHBOARD_DIR/.next/dev/lock"

# Start the server in background
cd "$DASHBOARD_DIR"
npx next dev --port "$PORT" >> "$LOG_FILE" 2>&1 &
SERVER_PID=$!
echo "$SERVER_PID" > "$PID_FILE"

# Wait for server to be ready (up to 30s)
for i in {1..60}; do
  if curl -s "http://localhost:$PORT" > /dev/null 2>&1; then
    break
  fi
  sleep 0.5
done

# Open browser
open "http://localhost:$PORT"

# Keep running — clean up on exit
cleanup() {
  if [[ -f "$PID_FILE" ]]; then
    kill $(cat "$PID_FILE") 2>/dev/null || true
    rm -f "$PID_FILE"
  fi
  exit 0
}
trap cleanup SIGINT SIGTERM EXIT
wait "$SERVER_PID" 2>/dev/null || true
