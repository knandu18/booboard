# Smoke-test helpers on top of tool/adb_ime.ps1 (uiautomator text dumps, no screenshots).
$env:ANDROID_SERIAL = 'emulator-5554'
. (Join-Path $PSScriptRoot 'adb_ime.ps1')

function Get-Ui {
    Invoke-Adb shell uiautomator dump --windows /sdcard/ui.xml | Out-Null
    $raw = (Invoke-Adb shell cat /sdcard/ui.xml) -join ''
    [xml]$x = $raw
    $x.SelectNodes('//node') | ForEach-Object {
        $b = [regex]::Match($_.bounds, '\[(\d+),(\d+)\]\[(\d+),(\d+)\]')
        [pscustomobject]@{
            Text = $_.text; Desc = $_.'content-desc'; Pkg = $_.package; Cls = $_.class
            X = [int](([int]$b.Groups[1].Value + [int]$b.Groups[3].Value) / 2)
            Y = [int](([int]$b.Groups[2].Value + [int]$b.Groups[4].Value) / 2)
        }
    }
}

# Short list of labelled nodes.
function Show-Ui([string]$Filter = '') {
    Get-Ui | Where-Object { ($_.Text -or $_.Desc) -and ("$($_.Text) $($_.Desc)" -match $Filter) } |
        ForEach-Object { '{0} | {1} @ {2},{3}' -f $_.Text, $_.Desc, $_.X, $_.Y }
}

# Tap the first node whose text or description matches the regex.
function Tap-Ui([string]$Pattern, [object[]]$Ui = $null) {
    if (-not $Ui) { $Ui = Get-Ui }
    $n = $Ui | Where-Object { $_.Text -match $Pattern -or $_.Desc -match $Pattern } | Select-Object -First 1
    if (-not $n) { throw "no node matches $Pattern" }
    Send-Tap $n.X $n.Y
    Start-Sleep -Milliseconds 350
}

# Type with the on-screen keyboard: each character's key found by its description.
function Type-Keys([string]$Text) {
    $ui = Get-Ui
    foreach ($ch in $Text.ToCharArray()) {
        $s = [string]$ch
        $n = if ($s -eq ' ') { $ui | Where-Object { $_.Desc -match '^Space' } | Select-Object -First 1 }
             else { $ui | Where-Object { $_.Desc -ceq $s -or $_.Desc -ceq $s.ToUpper() } | Select-Object -First 1 }
        if (-not $n) { throw "no key for '$s'" }
        Send-Tap $n.X $n.Y
        Start-Sleep -Milliseconds 120
    }
}
