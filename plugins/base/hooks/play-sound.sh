#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUNDS_DIR="${CLAUDE_PLUGIN_ROOT:+${CLAUDE_PLUGIN_ROOT}/hooks/sounds}"
SOUNDS_DIR="${SOUNDS_DIR:-$SCRIPT_DIR/sounds}"

if [ $# -eq 0 ]; then
  echo "No sound file specified. Provide one or more .wav filenames as arguments." >&2
  exit 1
fi

ARGS=("$@")
SOUND="${SOUNDS_DIR}/${ARGS[$((RANDOM % $#))]}"

if [ ! -f "$SOUND" ]; then
  echo "Sound file not found: $SOUND" >&2
  exit 1
fi

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*|Windows_NT)
    if ! command -v cygpath &>/dev/null; then
      echo "cygpath not found. Install Git for Windows which includes it." >&2
      exit 1
    fi
    WIN_SOUND="$(cygpath -w "$SOUND")"
    powershell -NoProfile -NonInteractive -c "(New-Object System.Media.SoundPlayer '${WIN_SOUND//\'/\'\'}').PlaySync()"
    ;;
  Darwin*)
    if ! command -v afplay &>/dev/null; then
      echo "afplay not found. It should be included with macOS by default." >&2
      exit 1
    fi
    afplay "$SOUND"
    ;;
  Linux*)
    if command -v aplay &>/dev/null; then
      aplay -q "$SOUND"
    elif command -v paplay &>/dev/null; then
      paplay "$SOUND"
    else
      echo "No audio player found. Install alsa-utils (aplay) or pulseaudio-utils (paplay)." >&2
      exit 1
    fi
    ;;
  *)
    echo "Unsupported OS: $(uname -s)" >&2
    exit 1
    ;;
esac
