# SPDX-License-Identifier: GPL-3.0-or-later
#
# Helpers for driving BooBoard on an emulator/device. Dot-source it:
#   . .\tool\adb_ime.ps1
#   Install-BooBoard; Enable-BooBoard; Open-Testbed -Field text; Send-Taps ...; Get-TestbedText text
$ErrorActionPreference = 'Stop'
$script:Adb = Join-Path $env:ANDROID_HOME 'platform-tools\adb.exe'
$script:Pkg = 'io.github.knandu18.booboard'
$script:ImeId = "$script:Pkg/app.booboard.keyboard.ime.BooBoardImeService"  # full class name: the namespace differs from the id

function Invoke-Adb { & $script:Adb @args }

function Wait-Device {
    Invoke-Adb wait-for-device | Out-Null
    while ((Invoke-Adb shell getprop sys.boot_completed 2>$null).Trim() -ne '1') { Start-Sleep -Milliseconds 500 }
}

function Install-BooBoard([string]$Apk = 'build\app\outputs\flutter-apk\app-debug.apk') {
    Invoke-Adb install -r -t $Apk | Select-Object -Last 1
}

function Enable-BooBoard {
    Invoke-Adb shell ime enable $script:ImeId | Out-Null
    Invoke-Adb shell ime set $script:ImeId | Out-Null
    (Invoke-Adb shell settings get secure default_input_method).Trim()
}

function Open-Testbed([string]$Field = 'text', [switch]$Keep) {
    $clear = if ($Keep) { 'false' } else { 'true' }
    Invoke-Adb shell am start -n "$script:Pkg/app.booboard.keyboard.testbed.TestbedActivity" --es focus $Field --ez clear $clear | Out-Null
}

function Clear-TestbedLog { Invoke-Adb logcat -c }

# Latest logged value of a testbed field.
function Get-TestbedText([string]$Field = 'text') {
    $lines = Invoke-Adb logcat -d -s BooBoardTestbed:I | Select-String -SimpleMatch " $Field="
    if (-not $lines) { return $null }
    $json = ($lines[-1].Line -split " $Field=", 2)[1]
    return ($json | ConvertFrom-Json)
}

function Send-Tap([int]$X, [int]$Y) { Invoke-Adb shell input tap $X $Y }

function Send-Swipe([int]$X1, [int]$Y1, [int]$X2, [int]$Y2, [int]$Ms = 300) {
    Invoke-Adb shell input swipe $X1 $Y1 $X2 $Y2 $Ms
}

function Save-Screen([string]$Path) {
    $remote = '/sdcard/booboard_screen.png'
    Invoke-Adb shell screencap -p $remote | Out-Null
    Invoke-Adb pull $remote $Path | Out-Null
    Invoke-Adb shell rm $remote | Out-Null
}

# Bounds [x1,y1][x2,y2] of the IME window, from dumpsys.
function Get-ImeFrame {
    $dump = Invoke-Adb shell dumpsys window InputMethod
    $m = [regex]::Match(($dump -join "`n"), 'mFrame=\[(\d+),(\d+)\]\[(\d+),(\d+)\]')
    if (-not $m.Success) { return $null }
    [pscustomobject]@{ Left = [int]$m.Groups[1].Value; Top = [int]$m.Groups[2].Value; Right = [int]$m.Groups[3].Value; Bottom = [int]$m.Groups[4].Value }
}
