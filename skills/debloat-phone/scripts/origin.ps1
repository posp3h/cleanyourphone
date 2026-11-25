<#
Делит сторонние (не системные) приложения на «поставил телефон» и «поставил пользователь».
  .\origin.ps1 -Serial 192.168.1.50:37123 [-Out backups\...\origin.tsv]

Признаки:
  - installer (кто поставил): com.android.vending = Play Маркет; пусто/android/com.xiaomi.mipicks/
    com.miui.cotaservice/com.xiaomi.discover/com.facebook.appmanager = прошивка или автоустановка;
    com.google.android.packageinstaller / com.miui.packageinstaller = файл APK, установленный руками.
  - codePath в /product, /system, /vendor, /preload = лежит в прошивке.
  - firstInstallTime в первые 2 часа после самой ранней установки = ставилось при первой настройке
    (сюда же попадают приложения, которые Play сам докачал при настройке — PAI/«рекомендуемые приложения»).
Итог в колонке origin: preinstalled / setup-autoinstall / user / sideload / unknown.
Это ПОДСКАЗКА для человека, а не приговор: спорные — спросить.
#>
param([Parameter(Mandatory)][string]$Serial, [string]$Out)
$pkgs = (& adb -s $Serial shell pm list packages -3 -i) | ForEach-Object {
  if ($_ -match '^package:(\S+)\s+installer=(\S*)') { [pscustomobject]@{ Pkg = $Matches[1]; Installer = $Matches[2] } }
}
if (-not $pkgs) { Write-Error "Телефон $Serial не отвечает"; exit 3 }
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
if ($Out) { $res | Export-Csv $Out -Delimiter "`t" -NoTypeInformation -Encoding UTF8; "Сохранено: $Out" }
