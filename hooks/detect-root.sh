#!/usr/bin/env bash
# Detect the EA memory root across environments.
#
# IMPORTANT: where this hook runs matters.
# - Cowork runs SessionStart hooks on the HOST machine (macOS/Windows), NOT
#   inside the Linux sandbox — /sessions does NOT exist here even in Cowork.
# - Claude Code / local dev runs it wherever the CLI runs.
#
# Environments handled:
# 1. Linux sandbox (defensive, in case hooks ever run there)
# 2. Cowork host — resolve the mounted project folder, or hand off to Claude
# 3. Claude Code / local dev — ~/claude-executive-assistant/ (shared)

FOLDER_NAME="claude-executive-assistant"
SETUP_CMD="/ea:setup"

# Sets EA_ROOT if $1 contains (or is) an EA folder
try_candidate() {
  local d="$1"
  [ -n "$d" ] && [ -d "$d" ] || return 1
  if [ -f "$d/$FOLDER_NAME/CLAUDE.md" ]; then
    EA_ROOT="$d/$FOLDER_NAME"
    return 0
  fi
  if [ -f "$d/CLAUDE.md" ] && [ -d "$d/memory" ]; then
    EA_ROOT="$d"
    return 0
  fi
  return 1
}

print_root_and_claude_md() {
  echo "EA_ROOT=$EA_ROOT"
  if [ -n "$LOCAL_EA" ]; then
    echo "LOCAL_EA=$LOCAL_EA"
  fi
  echo ""
  if [ -f "$EA_ROOT/CLAUDE.md" ]; then
    cat "$EA_ROOT/CLAUDE.md"
  elif [ "$NEEDS_SETUP" = "1" ]; then
    echo "EA memory not initialized. Run $SETUP_CMD to get started."
  else
    echo "EA folder exists at $EA_ROOT but CLAUDE.md is missing."
    echo "Run $SETUP_CMD to repair, or check that your files are intact."
  fi
}

# ---------------------------------------------------------------------------
# 1. Linux sandbox
if [ -d "/sessions" ]; then
  shopt -s nullglob
  for dir in /sessions/*/mnt/*/; do
    b=$(basename "$dir")
    if [ "$b" != "outputs" ] && [ "$b" != "uploads" ] && [ "$b" != ".claude" ]; then
      EA_ROOT="${dir}${FOLDER_NAME}"
      [ -d "$EA_ROOT" ] || NEEDS_SETUP=1
      MOUNT_DIR="$dir"
      break
    fi
  done
  shopt -u nullglob

  if [ -z "$MOUNT_DIR" ]; then
    echo "EA requires a Cowork Project session with a folder selected."
    echo "Please create a new Project and select your EA folder."
    exit 0
  fi
  print_root_and_claude_md
  exit 0
fi

# ---------------------------------------------------------------------------
# 2. Cowork HOST — /sessions doesn't exist here. Detect Cowork by the
#    session/plugin cache paths.
case "${CLAUDE_PLUGIN_ROOT:-}:$PWD" in
  *local-agent-mode-sessions*|*claude-code-sessions*)
    IN_COWORK_HOST=1
    ;;
esac

if [ -n "$IN_COWORK_HOST" ]; then
  # 2a. Obvious candidates for the mounted project folder
  for cand in "${CLAUDE_PROJECT_DIR:-}" "$PWD"; do
    if try_candidate "$cand"; then
      print_root_and_claude_md
      exit 0
    fi
  done

  # 2b. Scan the default Cowork projects location; accept only an
  #     unambiguous match.
  shopt -s nullglob
  matches=()
  for d in "$HOME/Documents/Claude/Projects"/*/"$FOLDER_NAME"; do
    [ -f "$d/CLAUDE.md" ] && matches+=("$d")
  done
  shopt -u nullglob
  if [ "${#matches[@]}" -eq 1 ]; then
    EA_ROOT="${matches[0]}"
    print_root_and_claude_md
    exit 0
  fi

  # 2c. Hand off to Claude, which always knows the mounted folder from its
  #     own context. NEVER fall back to $HOME in Cowork — paths under $HOME
  #     are not the user's project folder.
  echo "EA_ROOT=UNRESOLVED"
  echo ""
  echo "Cowork detected, but this hook (running on the host) could not locate"
  echo "the mounted project folder. Claude: resolve it now —"
  echo "1. Take the project folder the user selected from your own context."
  echo "2. Use EA_ROOT=<that folder>/$FOLDER_NAME for all file operations."
  echo "3. Immediately read EA_ROOT/CLAUDE.md and follow it."
  echo "4. If that file doesn't exist, suggest running $SETUP_CMD."
  echo "If no folder is selected, this is a Task session — EA needs a Project"
  echo "session with a folder selected."
  exit 0
fi

# ---------------------------------------------------------------------------
# 3. Claude Code / local dev — shared location
EA_ROOT="$HOME/$FOLDER_NAME"
if [ ! -d "$EA_ROOT/memory" ]; then
  NEEDS_SETUP=1
fi

# Legacy clone setup in the current directory — signal so setup can offer
# migration
if [ "$PWD" != "$EA_ROOT" ] && [ -d "$PWD/memory" ] && [ -f "$PWD/CLAUDE.md" ]; then
  LOCAL_EA="$PWD"
fi

print_root_and_claude_md
