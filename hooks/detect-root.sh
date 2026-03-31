#!/usr/bin/env bash
# Detect the EA memory root across environments:
# - Cowork: mounted folder at /sessions/*/mnt/{FolderName}/
# - Claude Code / local dev: ~/secretary/ (shared across all projects)

# 1. Check if we're in Cowork first (before any $HOME fallback)
if [ -d "/sessions" ]; then
  # Enable nullglob so unmatched globs expand to nothing
  shopt -s nullglob
  for dir in /sessions/*/mnt/*/; do
    b=$(basename "$dir")
    if [ "$b" != "outputs" ] && [ "$b" != "uploads" ]; then
      # Found a user-mounted folder
      if [ -d "${dir}secretary" ]; then
        SECRETARY_ROOT="${dir}secretary"
      else
        # Mount exists but no secretary/ yet — use it as parent
        SECRETARY_ROOT="${dir}secretary"
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
  SECRETARY_ROOT="$HOME/secretary"
  if [ ! -d "$HOME/secretary/memory" ]; then
    NEEDS_SETUP=1
  fi

  # 3. Check if current directory has secretary files (legacy clone setup)
  #    Signal this to Claude so setup can offer migration
  if [ "$PWD" != "$HOME/secretary" ] && [ -d "$PWD/memory" ] && [ -f "$PWD/CLAUDE.md" ]; then
    LOCAL_SECRETARY="$PWD"
  fi
fi

# 4. Output the root path for Claude to parse
echo "SECRETARY_ROOT=$SECRETARY_ROOT"
if [ -n "$LOCAL_SECRETARY" ]; then
  echo "LOCAL_SECRETARY=$LOCAL_SECRETARY"
fi
echo ""

# 5. Output CLAUDE.md or setup prompt
if [ -f "$SECRETARY_ROOT/CLAUDE.md" ]; then
  cat "$SECRETARY_ROOT/CLAUDE.md"
elif [ "$NEEDS_SETUP" = "1" ]; then
  echo "EA memory not initialized. Run /ea:setup to get started."
else
  echo "EA folder exists at $SECRETARY_ROOT but CLAUDE.md is missing."
  echo "Run /ea:setup to repair, or check that your files are intact."
fi
