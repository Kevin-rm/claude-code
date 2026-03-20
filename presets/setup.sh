#!/usr/bin/env bash
set -euo pipefail

PRESETS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

FORCE_OVERWRITE=false
DRY_RUN=false
NON_INTERACTIVE=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Install Claude Code preset files into ~/.claude

Options:
  --force-overwrite   Overwrite existing files without prompting
  --non-interactive   Skip prompts; existing files are left untouched unless --force-overwrite
  --dry-run           Show what would be done without making changes
  -h, --help          Show this help message
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force-overwrite)  FORCE_OVERWRITE=true; shift ;;
    --non-interactive)  NON_INTERACTIVE=true; shift ;;
    --dry-run)          DRY_RUN=true; shift ;;
    -h|--help)          usage ;;
    *)                  echo "Unknown option: $1"; usage ;;
  esac
done

if [[ ! -t 0 ]]; then
  NON_INTERACTIVE=true
fi

if [[ -t 1 ]]; then
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  RED='\033[0;31m'
  BOLD='\033[1m'
  NC='\033[0m'
else
  GREEN='' YELLOW='' RED='' BOLD='' NC=''
fi

info()  { printf '%b[OK]%b %s\n'   "$GREEN"  "$NC" "$1"; }
warn()  { printf '%b[WARN]%b %s\n' "$YELLOW" "$NC" "$1"; }
error() { printf '%b[ERR]%b %s\n'  "$RED"    "$NC" "$1"; }

TMPFILES=()

cleanup() {
  for f in "${TMPFILES[@]}"; do
    [[ -f "$f" ]] && rm -f "$f"
  done
}
trap cleanup EXIT

make_tmp() {
  local t
  t=$(mktemp)
  TMPFILES+=("$t")
  echo "$t"
}

# prompt_choice VARNAME default "label1" "label2" ...
prompt_choice() {
  local varname="$1"; shift
  local default="$1"; shift
  local options=("$@")

  if $NON_INTERACTIVE || $DRY_RUN; then
    printf -v "$varname" '%s' "$default"
    return
  fi

  local i=1
  for opt in "${options[@]}"; do
    echo -e "  $i) $opt"
    (( i++ ))
  done
  read -rp "Choose [1-${#options[@]}]: " choice
  printf -v "$varname" '%s' "${choice:-$default}"
}

backup() {
  local file="$1"
  [[ -f "$file" ]] || return 0

  local bak
  bak="${file}.bak.$(date +%Y%m%d%H%M%S)"

  if $DRY_RUN; then
    info "[dry-run] Would backup $file → $bak"
    return
  fi

  cp "$file" "$bak"
  info "Backup saved → $bak"
}

validate_json() {
  local file="$1"
  if ! jq empty "$file" 2>/dev/null; then
    error "Invalid JSON: $file"
    return 1
  fi
}

# $1 = base (lower priority), $2 = overlay (wins)
deep_merge() {
  local base="$1" overlay="$2" dest="$3"

  validate_json "$base"
  validate_json "$overlay"

  local tmp
  tmp=$(make_tmp)

  jq -s '
    def deepmerge:
      if (.[0] | type) == "object" and (.[1] | type) == "object" then
        .[0] as $a | .[1] as $b |
        ($a | keys_unsorted) + ($b | keys_unsorted) | unique |
        map(. as $k |
          if ($a | has($k)) and ($b | has($k))
          then { ($k): ([$a[$k], $b[$k]] | deepmerge) }
          elif ($b | has($k))
          then { ($k): $b[$k] }
          else { ($k): $a[$k] }
          end
        ) | add // {}
      else
        .[1]  # overlay wins for non-object values
      end;
    [.[0], .[1]] | deepmerge
  ' "$base" "$overlay" > "$tmp" && mv "$tmp" "$dest"
}

ensure_jq() {
  command -v jq &>/dev/null && return 0

  warn "jq is not installed — required for merge"

  if $NON_INTERACTIVE; then
    error "Cannot install jq in non-interactive mode"
    return 1
  fi

  if $DRY_RUN; then
    info "[dry-run] Would attempt to install jq"
    return 1
  fi

  local mgr=""
  if   command -v brew    &>/dev/null; then mgr="brew"
  elif command -v apt-get &>/dev/null; then mgr="apt-get"
  elif command -v winget  &>/dev/null; then mgr="winget"
  elif command -v scoop   &>/dev/null; then mgr="scoop"
  fi

  if [[ -z "$mgr" ]]; then
    error "No supported package manager found (brew, apt-get, winget, scoop)"
    warn "Install jq manually then re-run this script"
    return 1
  fi

  info "Installing jq via $mgr …"

  case "$mgr" in
    brew)     brew install jq ;;
    apt-get)
      if [[ $EUID -eq 0 ]]; then
        apt-get update -qq && apt-get install -yq jq
      elif command -v sudo &>/dev/null; then
        sudo apt-get update -qq && sudo apt-get install -yq jq
      else
        error "apt-get requires root or sudo"; return 1
      fi
      ;;
    winget)   winget install jqlang.jq --accept-package-agreements --accept-source-agreements ;;
    scoop)    scoop install jq ;;
  esac

  hash -r 2>/dev/null

  if ! command -v jq &>/dev/null; then
    warn "jq installed but not yet in PATH — re-run in a new terminal"
    return 1
  fi

  info "jq installed successfully"
}

install_preset() {
  local src="$1"
  local filename
  filename="$(basename "$src")"
  local dest="$CLAUDE_DIR/$filename"

  if [[ ! -f "$src" ]]; then
    error "Source not found: $src"
    return 1
  fi

  mkdir -p "$CLAUDE_DIR"

  if [[ ! -f "$dest" ]]; then
    if $DRY_RUN; then
      info "[dry-run] Would install $filename → $dest"
    else
      cp "$src" "$dest"
      info "$filename installed → $dest"
    fi
    return
  fi

  warn "$dest already exists"

  if $FORCE_OVERWRITE; then
    backup "$dest"
    if ! $DRY_RUN; then
      cp "$src" "$dest"
    fi
    info "$filename overwritten"
    return
  fi

  local is_json=false
  [[ "$filename" == *.json ]] && is_json=true

  local can_merge=false
  if $is_json && command -v jq &>/dev/null; then
    can_merge=true
  fi

  local choice
  if $can_merge; then
    prompt_choice choice "3" \
      "${GREEN}Merge${NC} (your settings win, preset fills gaps)" \
      "${YELLOW}Overwrite${NC} (replace with preset)" \
      "${RED}Skip${NC}"
  elif $is_json; then
    prompt_choice choice "3" \
      "${GREEN}Install jq${NC} then merge" \
      "${YELLOW}Overwrite${NC} (replace with preset)" \
      "${RED}Skip${NC}"
  else
    prompt_choice choice "2" \
      "${YELLOW}Overwrite${NC} (replace with preset)" \
      "${RED}Skip${NC}"
  fi

  case "$choice" in
    1)
      if $can_merge; then
        backup "$dest"
        if $DRY_RUN; then
          info "[dry-run] Would deep-merge $filename"
        else
          deep_merge "$src" "$dest" "$dest"
          info "$filename merged into $dest"
        fi
      elif $is_json; then
        if ensure_jq; then
          backup "$dest"
          if ! $DRY_RUN; then
            deep_merge "$src" "$dest" "$dest"
            info "$filename merged into $dest"
          fi
        else
          warn "Merge unavailable — skipping $filename"
        fi
      else
        backup "$dest"
        if ! $DRY_RUN; then cp "$src" "$dest"; fi
        info "$filename overwritten"
      fi
      ;;
    2)
      if $can_merge || $is_json; then
        backup "$dest"
        if ! $DRY_RUN; then cp "$src" "$dest"; fi
        info "$filename overwritten"
      else
        warn "Skipped $filename"
      fi
      ;;
    *)
      warn "Skipped $filename"
      ;;
  esac
}

echo ""
printf '%b======================================%b\n' "$BOLD" "$NC"
printf '%b  Claude Code Presets -- Setup%b\n' "$BOLD" "$NC"
printf '%b======================================%b\n' "$BOLD" "$NC"
$DRY_RUN && echo "  (dry-run mode — no files will be changed)"
echo ""

installed=0
for src in "$PRESETS_DIR"/*.json "$PRESETS_DIR"/*.yaml "$PRESETS_DIR"/*.yml; do
  [[ -f "$src" ]] || continue
  [[ "$(basename "$src")" == "$(basename "${BASH_SOURCE[0]}")" ]] && continue

  install_preset "$src"
  (( installed++ ))
done

if [[ $installed -eq 0 ]]; then
  warn "No preset files found in $PRESETS_DIR"
fi

echo ""
info "Done! ($installed file(s) processed)"
