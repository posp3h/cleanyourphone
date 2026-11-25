#!/bin/sh
# Applies an approved debloat plan to the phone.
#   ./apply.sh <serial> <plan.txt> [--disable-only] [--dry-run]
# Plan: "com.pkg", "com.pkg disable" or lines from lists/*.txt ("L2<TAB>uninstall<TAB>com.pkg<TAB># ...").
# Writes uninstall-log.tsv next to the plan. Refuses to run with protected packages (lists/protected.txt).
set -eu
SERIAL=$1; PLAN=$2; shift 2
DISABLE_ONLY=0; DRY=0
for a in "$@"; do case $a in --disable-only) DISABLE_ONLY=1;; --dry-run) DRY=1;; esac; done
HERE=$(cd "$(dirname "$0")" && pwd)
PROT="$HERE/../lists/protected.txt"
LOG="$(dirname "$PLAN")/uninstall-log.tsv"

is_protected() {
  sed 's/#.*//' "$PROT" | while read -r x; do
    [ -z "$x" ] && continue
    case $x in
      *\*) case $1 in "${x%\*}"*) echo yes; return;; esac;;
      *) [ "$1" = "$x" ] && { echo yes; return; };;
    esac
  done
}

ITEMS=$(sed 's/#.*//' "$PLAN" | awk 'NF { if ($1 ~ /^L[1-4]$/) print $3, $2; else print $1, (NF>1 ? $2 : "uninstall") }')

BAD=""
for p in $(echo "$ITEMS" | awk '{print $1}'); do [ -n "$(is_protected "$p")" ] && BAD="$BAD $p"; done
[ -n "$BAD" ] && { echo "The plan contains protected packages, nothing was done:$BAD" >&2; exit 2; }

INSTALLED=$(adb -s "$SERIAL" shell pm list packages | sed 's/^package://' | tr -d '\r')
[ -z "$INSTALLED" ] && { echo "Phone $SERIAL is not responding" >&2; exit 3; }
[ -f "$LOG" ] || printf 'package\trequested\tresult\tmessage\n' > "$LOG"

U=0; D=0; F=0; A=0
echo "$ITEMS" | while read -r p act; do
  [ "$DISABLE_ONLY" = 1 ] && act=disable
  echo "$INSTALLED" | grep -qx "$p" || continue
  if [ "$DRY" = 1 ]; then printf '%-10s %s\n' "$act" "$p"; continue; fi
  res=""; msg=""
  if [ "$act" = uninstall ]; then
    msg=$(adb -s "$SERIAL" shell pm uninstall -k --user 0 "$p" 2>&1 | tr -d '\r' | tr '\n' ' ')
    case $msg in *Success*) res=uninstalled;; esac
  fi
  if [ -z "$res" ]; then
    m2=$(adb -s "$SERIAL" shell pm disable-user --user 0 "$p" 2>&1 | tr -d '\r' | tr '\n' ' ')
    case $m2 in *disabled*) res=disabled;; *) res=failed;; esac
    msg="$msg $m2"
  fi
  printf '%s\t%s\t%s\t%s\n' "$p" "$act" "$res" "$msg" >> "$LOG"
  printf '%-12s %s\n' "$res" "$p"
done
[ "$DRY" = 1 ] || echo "Log: $LOG"
