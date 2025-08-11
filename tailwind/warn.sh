#!/bin/bash

# Warn-only scanner for Tailwind major upgrades
# Usage:
#   ./warn.sh v1-to-v2
#   ./warn.sh v2-to-v3
#   ./warn.sh path/to/custom-warn-rules.txt
#
# Rule file format:
#   <pattern> <message describing what to check>
# - First token is a grep pattern (basic regex). The rest of the line is the message.
# - Lines starting with # and blank lines are ignored.

set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: ./warn.sh [v1-to-v2|v2-to-v3|path/to/rules.txt]" 1>&2
  exit 1
fi

arg="$1"
base_dir="$(cd "$(dirname "$0")" && pwd)"
project_root="$(cd "$base_dir/.." && pwd)"

case "$arg" in
  v1-to-v2)
    rules_file="$base_dir/v1-to-v2.warn.txt"
    ;;
  v2-to-v3)
    rules_file="$base_dir/v2-to-v3.warn.txt"
    ;;
  *)
    rules_file="$arg"
    ;;
esac

if [ ! -f "$rules_file" ]; then
  echo "Rules file not found: $rules_file" 1>&2
  exit 1
fi

# Directories to scan (relative to project root where this toolkit is used)
dirs=("./src" "./templates")
# File types to scan inside ./src
types=(css sass scss pcss)
# Additional config files to scan if present
config_candidates=(
  ./tailwind.config.js
  ./tailwind.config.cjs
  ./tailwind.config.mjs
  ./tailwind.config.ts
)

cd "$project_root"

# Build file list for src types
build_src_file_list() {
  local -a files=()
  for t in "${types[@]}"; do
    while IFS= read -r -d '' f; do
      files+=("$f")
    done < <(find ./src -type f -name "*.$t" -print0 2>/dev/null || true)
  done
  if [ ${#files[@]} -gt 0 ]; then
    printf '%s\n' "${files[@]}"
  fi
}

# Build templates file list (all files)
build_templates_file_list() {
  if [ -d ./templates ]; then
    find ./templates -type f 2>/dev/null || true
  fi
}

# Build config file list
build_config_file_list() {
  local -a files=()
  for c in "${config_candidates[@]}"; do
    if [ -f "$c" ]; then
      files+=("$c")
    fi
  done
  if [ ${#files[@]} -gt 0 ]; then
    printf '%s\n' "${files[@]}"
  fi
}

print_header() {
  echo "========================================"
  echo "$1"
  echo "========================================"
}

scan_files() {
  local pattern="$1"
  local message="$2"

  local any_hit=0
  # src typed files
  if [ -d ./src ]; then
    while IFS= read -r src_file; do
      if [ -n "$src_file" ]; then
        if grep -nH -E "$pattern" "$src_file" >/dev/null 2>&1; then
          if [ $any_hit -eq 0 ]; then
            print_header "WARN pattern: $pattern"
            echo "Hint: $message"
          fi
          any_hit=1
          grep -nH -E "$pattern" "$src_file" | sed 's/^/  /'
        fi
      fi
    done < <(build_src_file_list)
  fi

  # templates (all files)
  if [ -d ./templates ]; then
    if grep -RIn -E "$pattern" ./templates >/dev/null 2>&1; then
      if [ $any_hit -eq 0 ]; then
        print_header "WARN pattern: $pattern"
        echo "Hint: $message"
      fi
      any_hit=1
      grep -RIn -E "$pattern" ./templates | sed 's/^/  /'
    fi
  fi

  # tailwind config files
  local cfg_list
  cfg_list=$(build_config_file_list || true)
  if [ -n "${cfg_list:-}" ]; then
    while IFS= read -r cfg; do
      [ -n "$cfg" ] || continue
      if grep -nH -E "$pattern" "$cfg" >/dev/null 2>&1; then
        if [ $any_hit -eq 0 ]; then
          print_header "WARN pattern: $pattern"
          echo "Hint: $message"
        fi
        any_hit=1
        grep -nH -E "$pattern" "$cfg" | sed 's/^/  /'
      fi
    done <<< "$cfg_list"
  fi

  if [ $any_hit -eq 1 ]; then
    echo
  fi
}

# Read rules and scan
while IFS= read -r line; do
  # Trim leading/trailing whitespace
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"

  # Skip comments/blank lines
  if [ -z "$line" ] || [ "${line#\#}" != "$line" ]; then
    continue
  fi

  # First token is pattern; rest is message
  pattern=$(printf "%s" "$line" | awk '{print $1}')
  message=$(printf "%s" "$line" | cut -d ' ' -f 2-)
  if [ -z "$pattern" ] || [ -z "$message" ]; then
    continue
  fi

  scan_files "$pattern" "$message"

done < "$rules_file"

echo "Done scanning with: $rules_file"