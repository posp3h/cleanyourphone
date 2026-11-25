<#
Undoes everything apply.ps1 did, using its log.
  .\restore.ps1 -Serial 192.168.1.50:37123 -Log backups\redmi-2026-11-24\uninstall-log.tsv [-Package com.example.pkg]
-Package restores a single package only.
#>
param(
  [Parameter(Mandatory)] [string]$Serial,
  [Parameter(Mandatory)] [string]$Log,
  [string]$Package
)
$rows = Import-Csv $Log -Delimiter "`t" -Encoding UTF8 | Where-Object { -not $Package -or $_.package -eq $Package }
foreach ($r in $rows) {
  switch ($r.result) {
    'uninstalled' { $m = (& adb -s $Serial shell cmd package install-existing $r.package) -join ' ' }
    'disabled'    { $m = (& adb -s $Serial shell pm enable --user 0 $r.package) -join ' ' }
    default       { continue }
  }
  "{0,-50} {1}" -f $r.package, $m
}
