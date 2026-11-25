<#
Splits non-system apps into "shipped with the phone" and "installed by the user".
  .\origin.ps1 -Serial 192.168.1.50:37123 [-Out backups\...\origin.tsv]

Signals:
  - installer (who installed it): com.android.vending = Play Store; empty/android/com.xiaomi.mipicks/
    com.miui.cotaservice/com.xiaomi.discover/com.facebook.appmanager = firmware or auto-install;
    com.google.android.packageinstaller / com.miui.packageinstaller = an APK file installed by hand.
  - codePath under /product, /system, /vendor, /preload = shipped in the firmware.
  - firstInstallTime within 2 hours of the earliest install = installed during first setup
    (this also catches apps Play pulled in during setup: PAI / "recommended apps").
Result in the origin column: preinstalled / setup-autoinstall / user / sideload / unknown.
This is a HINT for the person, not a verdict: ask about anything debatable.
#>
param([Parameter(Mandatory)][string]$Serial, [string]$Out)
$pkgs = (& adb -s $Serial shell pm list packages -3 -i) | ForEach-Object {
  if ($_ -match '^package:(\S+)\s+installer=(\S*)') { [pscustomobject]@{ Pkg = $Matches[1]; Installer = $Matches[2] } }
}
if (-not $pkgs) { Write-Error "Phone $Serial is not responding"; exit 3 }
$rows = foreach ($p in $pkgs) {
  $d = (& adb -s $Serial shell dumpsys package $p.Pkg) -join "`n"
  $first = if ($d -match 'firstInstallTime=([0-9-]+ [0-9:]+)') { [datetime]$Matches[1] } else { $null }
  $code  = if ($d -match 'codePath=(\S+)') { $Matches[1] } else { '' }
  $init  = if ($d -match 'initiatingPackageName=(\S+)') { $Matches[1] } else { '' }
  $label = if ($d -match 'versionName=(\S+)') { $Matches[1] } else { '' }
  [pscustomobject]@{ Pkg = $p.Pkg; Installer = $p.Installer; Initiating = $init; CodePath = $code; FirstInstall = $first; Version = $label }
}
$t0 = ($rows | Where-Object FirstInstall | Measure-Object FirstInstall -Minimum).Minimum
$auto = 'null','','android','com.xiaomi.mipicks','com.miui.cotaservice','com.xiaomi.discover','com.facebook.appmanager','com.android.preinstall','com.google.android.apps.restore'
$res = foreach ($r in $rows) {
  $origin =
    if ($r.CodePath -match '^/(product|system|vendor|preload|system_ext)/') { 'preinstalled' }
    elseif ($auto -contains $r.Installer) { 'preinstalled' }
    elseif ($r.FirstInstall -and $t0 -and ($r.FirstInstall - $t0).TotalHours -lt 2) { 'setup-autoinstall' }
    elseif ($r.Installer -eq 'com.android.vending') { 'user' }
    elseif ($r.Installer -match 'packageinstaller') { 'sideload' }
    else { 'unknown' }
  $r | Add-Member origin $origin -PassThru
}
$res = $res | Sort-Object origin, Pkg
$res | Format-Table origin, Pkg, Installer, FirstInstall -AutoSize | Out-String -Width 200
if ($Out) { $res | Export-Csv $Out -Delimiter "`t" -NoTypeInformation -Encoding UTF8; "Saved: $Out" }
