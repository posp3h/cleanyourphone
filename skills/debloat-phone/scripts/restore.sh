#!/bin/sh
# Возвращает всё, что сделал apply.sh, по его журналу.
#   ./restore.sh <serial> <uninstall-log.tsv> [com.one.package]
set -eu
SERIAL=$1; LOG=$2; ONLY=${3:-}
tail -n +2 "$LOG" | while IFS="$(printf '\t')" read -r p req res msg; do
  [ -n "$ONLY" ] && [ "$p" != "$ONLY" ] && continue
  case $res in
    uninstalled) out=$(adb -s "$SERIAL" shell cmd package install-existing "$p" </dev/null);;
    disabled)    out=$(adb -s "$SERIAL" shell pm enable --user 0 "$p" </dev/null);;
    *) continue;;
  esac
  printf '%-50s %s\n' "$p" "$out"
done
