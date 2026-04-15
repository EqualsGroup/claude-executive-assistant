#!/usr/bin/env bash
# Detect the EA memory root across environments:
# - Cowork: mounted folder at /sessions/*/mnt/{FolderName}/
# - Claude Code / local dev: ~/claude-executive-assistant/ (shared across all projects)

# 1. Check if we're in Cowork first (before any $HOME fallback)
if [ -d "/sessions" ]; then
  # Enable nullglob so unmatched globs expand to nothing
  shopt -s nullglob
  for dir in /sessions/*/mnt/*/; do
    b=$(basename "$dir")
    if [ "$b" != "outputs" ] && [ "$b" != "uploads" ]; then
      # Found a user-mounted folder
      if [ -d "${dir}claude-executive-assistant" ]; then
        EA_ROOT="${dir}claude-executive-assistant"
      else
        # Mount exists but no claude-executive-assistant/ yet — use it as parent
        EA_ROOT="${dir}claude-executive-assistant"
        NEEDS_SETUP=1
      fi
      MOUNT_DIR="$dir"
      break
    fi
  done
  shopt -u nullglob

  if [ -z "$MOUNT_DIR" ]; then
    # We're in Cowork but no mounted folder — Task session
    echo "EA requires a Cowork Project session with a folder selected."
    echo "Please create a new Project and select your EA folder."
    exit 0
  fi
else
  # 2. Local dev / Claude Code — shared location
  EA_ROOT="$HOME/claude-executive-assistant"
  if [ ! -d "$HOME/claude-executive-assistant/memory" ]; then
    NEEDS_SETUP=1
  fi

  # 3. Check if current directory has EA files (legacy clone setup)
  #    Signal this to Claude so setup can offer migration
  if [ "$PWD" != "$HOME/claude-executive-assistant" ] && [ -d "$PWD/memory" ] && [ -f "$PWD/CLAUDE.md" ]; then
    LOCAL_EA="$PWD"
  fi
fi

# 4. Output the root path for Claude to parse
echo "EA_ROOT=$EA_ROOT"
if [ -n "$LOCAL_EA" ]; then
  echo "LOCAL_EA=$LOCAL_EA"
fi
echo ""

# 5. Output CLAUDE.md or setup prompt
if [ -f "$EA_ROOT/CLAUDE.md" ]; then
  cat "$EA_ROOT/CLAUDE.md"
elif [ "$NEEDS_SETUP" = "1" ]; then
  echo "EA memory not initialized. Run /ea:setup to get started."
else
  echo "EA folder exists at $EA_ROOT but CLAUDE.md is missing."
  echo "Run /ea:setup to repair, or check that your files are intact."
fi
