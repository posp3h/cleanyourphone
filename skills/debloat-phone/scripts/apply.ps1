<#
Applies an approved debloat plan to the phone.
  .\apply.ps1 -Serial 192.168.1.50:37123 -Plan backups\redmi-2026-11-24\plan.txt [-DisableOnly] [-DryRun]

Plan: one package per line. Both formats work:
  com.example.pkg                  -> uninstall
  com.example.pkg   disable        -> disable
  L2<TAB>uninstall<TAB>com.example.pkg<TAB># comment   (lines from lists/*.txt)
'#' starts a comment. -DisableOnly (level 1): everything is only disabled.
Writes uninstall-log.tsv next to the plan. Refuses to run if the plan contains a package from lists/protected.txt.
#>
param(
  [Parameter(Mandatory)] [string]$Serial,
  [Parameter(Mandatory)] [string]$Plan,
  [switch]$DisableOnly,
  [switch]$DryRun
)
$ErrorActionPreference = 'Stop'
$protFile = Join-Path $PSScriptRoot '..\lists\protected.txt'
$protected = Get-Content $protFile -Encoding UTF8 | ForEach-Object { ($_ -replace '#.*$','').Trim() } | Where-Object { $_ }

function Test-Protected([string]$p) {
  foreach ($x in $protected) {
    if ($x.EndsWith('*')) { if ($p.StartsWith($x.TrimEnd('*'))) { return $true } }
    elseif ($p -eq $x) { return $true }
  }
  return $false
}

$items = foreach ($line in Get-Content $Plan -Encoding UTF8) {
  $t = ($line -replace '#.*$','').Trim()
  if (-not $t) { continue }
  $tok = $t -split '\s+'
  if ($tok[0] -match '^L[1-4]$') { $pkg = $tok[2]; $act = $tok[1] } else { $pkg = $tok[0]; $act = if ($tok.Count -gt 1) { $tok[1] } else { 'uninstall' } }
  if ($DisableOnly) { $act = 'disable' }
  [pscustomobject]@{ Pkg = $pkg; Action = $act }
}

$bad = $items | Where-Object { Test-Protected $_.Pkg }
if ($bad) { Write-Error ("The plan contains protected packages, nothing was done: " + (($bad.Pkg) -join ', ')); exit 2 }

$installed = (& adb -s $Serial shell pm list packages) -replace '^package:','' | ForEach-Object { $_.Trim() }
if (-not $installed) { Write-Error "Phone $Serial is not responding (check adb devices)"; exit 3 }

$log = Join-Path (Split-Path $Plan -Parent) 'uninstall-log.tsv'
if (-not (Test-Path $log)) { "package`trequested`tresult`tmessage" | Out-File $log -Encoding utf8 }

$n = @{ uninstalled = 0; disabled = 0; failed = 0; absent = 0 }
foreach ($it in $items) {
  $p = $it.Pkg
  if ($installed -notcontains $p) { $n.absent++; continue }
  if ($DryRun) { "{0,-10} {1}" -f $it.Action, $p; continue }
  $result = ''; $msg = ''
  if ($it.Action -eq 'uninstall') {
    $msg = ((& adb -s $Serial shell pm uninstall -k --user 0 $p) 2>&1 | Out-String).Trim()
    if ($msg -match 'Success') { $result = 'uninstalled' }
  }
  if (-not $result) {
    $m2 = ((& adb -s $Serial shell pm disable-user --user 0 $p) 2>&1 | Out-String).Trim()
    if ($m2 -match 'disabled') { $result = 'disabled'; $msg = ($msg + ' | ' + $m2).Trim(' |') } else { $result = 'failed'; $msg = ($msg + ' | ' + $m2).Trim(' |') }
  }
  $n[$result]++
  "$p`t$($it.Action)`t$result`t$($msg -replace '\s+',' ')" | Out-File $log -Append -Encoding utf8
  "{0,-12} {1}" -f $result, $p
}
""
"Removed: $($n.uninstalled)  Disabled: $($n.disabled)  Failed: $($n.failed)  Not on this phone: $($n.absent)"
if (-not $DryRun) { "Log: $log" }
