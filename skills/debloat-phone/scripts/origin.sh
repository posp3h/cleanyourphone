#!/bin/sh
# Splits non-system apps into "shipped with the phone" and "installed by the user". Same rules as origin.ps1.
#   ./origin.sh <serial>   -> TSV: origin  package  installer  firstInstallTime  codePath
set -eu
S=$1
adb -s "$S" shell pm list packages -3 -i | tr -d '\r' | sed -n 's/^package:\([^ ]*\) *installer=\(.*\)$/\1 \2/p' |
while read -r pkg inst; do
  d=$(adb -s "$S" shell dumpsys package "$pkg" </dev/null | tr -d '\r')
  first=$(echo "$d" | sed -n 's/.*firstInstallTime=\([0-9-]* [0-9:]*\).*/\1/p' | head -1)
  code=$(echo "$d" | sed -n 's/.*codePath=\([^ ]*\).*/\1/p' | head -1)
  printf '%s\t%s\t%s\t%s\n' "$pkg" "${inst:-null}" "$first" "$code"
done | sort -t "$(printf '\t')" -k3 | awk -F '\t' '
  function mins(s,  x) { split(s, x, /[- :]/); return ((x[1]*12 + x[2])*31 + x[3])*1440 + x[4]*60 + x[5] }
  NR==1 { t0 = mins($3) }
  { dt = (mins($3) - t0) / 60
    o = "unknown"
    if ($4 ~ /^\/(product|system|vendor|preload|system_ext)\//) o = "preinstalled"
    else if ($2 ~ /^(null|android|com\.xiaomi\.mipicks|com\.miui\.cotaservice|com\.xiaomi\.discover|com\.facebook\.appmanager|com\.android\.preinstall|com\.google\.android\.apps\.restore)$/) o = "preinstalled"
    else if (dt < 2) o = "setup-autoinstall"
    else if ($2 == "com.android.vending") o = "user"
    else if ($2 ~ /packageinstaller/) o = "sideload"
    printf "%s\t%s\t%s\t%s\t%s\n", o, $1, $2, $3, $4 }' | sort
