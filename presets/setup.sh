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
    *)                  echo "Unknown option: $1" >&2; exit 1 ;;
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

# prompt_choice VARNAME default "key:label" "key:label" ...
prompt_choice() {
  local varname="$1"; shift
  local default="$1"; shift
  local entries=("$@")

  if $NON_INTERACTIVE || $DRY_RUN; then
    printf -v "$varname" '%s' "$default"
    return
  fi

  local keys=()
  local i=1
  for entry in "${entries[@]}"; do
    local key="${entry%%:*}"
    local label="${entry#*:}"
    keys+=("$key")
    echo -e "  $i) $label"
    (( i++ ))
  done
  read -rp "Choose [1-${#entries[@]}]: " choice

  if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#keys[@]} )); then
    printf -v "$varname" '%s' "${keys[$((choice - 1))]}"
  else
    printf -v "$varname" '%s' "$default"
  fi
}

backup() {
  local file="$1"
  [[ -f "$file" ]] || return 0

  local bak
  bak="${file}.bak.$(date +%Y%m%d%H%M%S)"

  if $DRY_RUN; then
    info "[dry-run] Would backup $file -> $bak"
    return
  fi

  cp "$file" "$bak"
  info "Backup saved -> $bak"
}

validate_json() {
  local file="$1"
  if ! jq empty "$file" 2>/dev/null; then
    error "Invalid JSON: $file"
    return 1
  fi
}

# $1 = base (lower priority), $2 = overlay (wins), $3 = dest
deep_merge() {
  local base="$1" overlay="$2" dest="$3"

  if [[ ! -s "$base" ]]; then
    [[ "$(realpath "$overlay")" != "$(realpath "$dest")" ]] && cp "$overlay" "$dest"
    return
  fi
  if [[ ! -s "$overlay" ]]; then
    [[ "$(realpath "$base")" != "$(realpath "$dest")" ]] && cp "$base" "$dest"
    return
  fi

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

  warn "jq is not installed -- required for merge"

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

  read -rp "Install jq via $mgr? [y/N] " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    warn "jq installation declined -- merge unavailable"
    return 1
  fi

  info "Installing jq via $mgr ..."

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
    warn "jq installed but not yet in PATH -- re-run in a new terminal"
    return 1
  fi

  info "jq installed successfully"
}

# install_file SRC DEST [--mergeable]
install_file() {
  local src="" dest="" mergeable=false
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --mergeable) mergeable=true; shift ;;
      *)
        if [[ -z "$src" ]]; then src="$1"
        else dest="$1"
        fi
        shift ;;
    esac
  done

  local filename
  filename="$(basename "$dest")"

  if [[ ! -f "$src" ]]; then
    error "Source not found: $src"
    return 1
  fi

  mkdir -p "$(dirname "$dest")"

  if [[ ! -f "$dest" ]]; then
    if $DRY_RUN; then
      info "[dry-run] Would install $filename -> $dest"
    else
      cp "$src" "$dest"
      info "$filename installed -> $dest"
    fi
    return
  fi

  warn "$dest already exists"

  if $FORCE_OVERWRITE; then
    backup "$dest"
    if ! $DRY_RUN; then cp "$src" "$dest"; fi
    info "$filename overwritten"
    return
  fi

  local strategy="overwrite-or-skip"
  if $mergeable && [[ "$filename" == *.json ]]; then
    if command -v jq &>/dev/null; then
      strategy="merge-ready"
    else
      strategy="merge-needs-jq"
    fi
  fi

  local action
  case "$strategy" in
    merge-ready)
      prompt_choice action "skip" \
        "merge:${GREEN}Merge${NC} (your settings win, preset fills gaps)" \
        "overwrite:${YELLOW}Overwrite${NC} (replace with preset)" \
        "skip:${RED}Skip${NC}"
      ;;
    merge-needs-jq)
      prompt_choice action "skip" \
        "install-jq:${GREEN}Install jq${NC} then merge" \
        "overwrite:${YELLOW}Overwrite${NC} (replace with preset)" \
        "skip:${RED}Skip${NC}"
      ;;
    *)
      prompt_choice action "skip" \
        "overwrite:${YELLOW}Overwrite${NC} (replace with preset)" \
        "skip:${RED}Skip${NC}"
      ;;
  esac

  case "$action" in
    merge)
      backup "$dest"
      if $DRY_RUN; then
        info "[dry-run] Would deep-merge $filename"
      else
        deep_merge "$src" "$dest" "$dest"
        info "$filename merged into $dest"
      fi
      ;;
    install-jq)
      if ensure_jq; then
        backup "$dest"
        if ! $DRY_RUN; then
          deep_merge "$src" "$dest" "$dest"
          info "$filename merged into $dest"
        fi
      else
        warn "Merge unavailable -- skipping $filename"
      fi
      ;;
    overwrite)
      backup "$dest"
      if ! $DRY_RUN; then cp "$src" "$dest"; fi
      info "$filename overwritten"
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
$DRY_RUN && echo "  (dry-run mode -- no files will be changed)"
echo ""

install_ccstatusline() {
  local src="$PRESETS_DIR/statusline.json"
  local dest="$HOME/.config/ccstatusline/settings.json"

  if [[ ! -f "$src" ]]; then
    return
  fi

  info "Setting up ccstatusline..."
  install_file "$src" "$dest"
}

install_file "$PRESETS_DIR/settings.json" "$CLAUDE_DIR/settings.json" --mergeable
install_ccstatusline

echo ""
info "Done!"
