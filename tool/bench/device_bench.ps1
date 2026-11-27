# SPDX-License-Identifier: GPL-3.0-or-later
#
# On-device benchmark for BooBoard (Wave 4-D). The ORCHESTRATOR runs this, on the emulator only.
# It refuses to run unless the emulator-5554 is attached and it is the only device, because a
# personal phone is plugged into this PC.
#
# Measures (against the budgets in docs/perf/budgets.md):
#   - first show after a cold start, and later shows: the [Boot] / [Keyboard] / [dict] timings the app logs;
#   - key -> commit: host-side time of `input tap` on each key, plus the [Keyboard] timings;
#   - memory: `dumpsys meminfo` TOTAL PSS;
#   - jank: `dumpsys gfxinfo` janky frames while it types.
#
# Usage (the text field must already be focused with BooBoard as the active keyboard):
#   powershell -ExecutionPolicy Bypass -File tool\bench\device_bench.ps1 -Phase latin
#   powershell -ExecutionPolicy Bypass -File tool\bench\device_bench.ps1 -Phase voice   # after voice is loaded
# The script prints a Markdown results table for docs/perf/budgets.md. It writes nothing else.
param(
  [ValidateSet('latin', 'voice')][string]$Phase = 'latin',
  [string]$Package = 'io.github.knandu18.booboard',
  [int]$TapX = 540,
  [int]$TapY = 1800,
  [string]$Text = 'the quick brown fox jumps over the lazy dog',
  [int]$KeyDelayMs = 150
)

$ErrorActionPreference = 'Stop'
$serial = 'emulator-5554'
$env:ANDROID_SERIAL = $serial

# Refuse any device but the emulator.
$attached = @(& adb devices | Select-Object -Skip 1 |
    Where-Object { $_ -match "`tdevice$" } |
    ForEach-Object { ($_ -split "`t")[0].Trim() })
if ($attached -notcontains $serial) { throw "emulator $serial is not attached (found: $($attached -join ', '))" }
$others = @($attached | Where-Object { $_ -ne $serial })
if ($others.Count -gt 0) { throw "refusing to run: other devices attached ($($others -join ', ')). Detach them first." }

function Invoke-Adb {
  param([string[]]$Arguments)
  & adb -s $serial @Arguments
}

function Get-BooBoardTimings {
  # Lines the app logs as "[Boot] ...", "[Keyboard] ..." and "[dict] ...", with the ms they report.
  $lines = Invoke-Adb -Arguments @('logcat', '-d')
  return @($lines | Where-Object { $_ -match '\[(Boot|Keyboard|dict)\]' })
}

function Get-TotalPssMb {
  $line = Invoke-Adb -Arguments @('shell', 'dumpsys', 'meminfo', $Package) |
      Where-Object { $_ -match '^\s*TOTAL PSS:' } | Select-Object -First 1
  if (-not $line) { return $null }
  $kb = [int](($line -replace '[^0-9]+(\d+).*', '$1'))
  return [math]::Round($kb / 1024, 1)
}

function Get-JankyFrames {
  $out = Invoke-Adb -Arguments @('shell', 'dumpsys', 'gfxinfo', $Package)
  $line = $out | Where-Object { $_ -match 'Janky frames' } | Select-Object -First 1
  if ($line -match 'Janky frames:\s*(\d+)\s*\(([\d.]+)%\)') { return "$($Matches[1]) ($($Matches[2])%)" }
  return 'n/a'
}

# Cold start: force-stop the app so the next show loads the engine from scratch.
Invoke-Adb -Arguments @('shell', 'am', 'force-stop', $Package) | Out-Null
Invoke-Adb -Arguments @('logcat', '-c') | Out-Null
Invoke-Adb -Arguments @('shell', 'input', 'tap', "$TapX", "$TapY") | Out-Null
Start-Sleep -Milliseconds 1500
$coldLines = Get-BooBoardTimings

# Later show: hide the keyboard and show it again by tapping the field.
Invoke-Adb -Arguments @('shell', 'input', 'keyevent', 'KEYCODE_BACK') | Out-Null
Start-Sleep -Milliseconds 300
Invoke-Adb -Arguments @('logcat', '-c') | Out-Null
Invoke-Adb -Arguments @('shell', 'input', 'tap', "$TapX", "$TapY") | Out-Null
Start-Sleep -Milliseconds 800
$warmLines = Get-BooBoardTimings

# Typing: reset jank stats, type the sentence key by key, time each tap on the host.
Invoke-Adb -Arguments @('shell', 'dumpsys', 'gfxinfo', $Package, 'reset') | Out-Null
$taps = New-Object System.Collections.Generic.List[double]
$sw = [System.Diagnostics.Stopwatch]::new()
foreach ($ch in $Text.ToCharArray()) {
  # Key positions are a simplification: the space bar sits 260 px below the first tap point.
  $keyY = if ($ch -eq ' ') { $TapY + 260 } else { $TapY }
  $sw.Restart()
  Invoke-Adb -Arguments @('shell', 'input', 'tap', "$TapX", "$keyY") | Out-Null
  $sw.Stop()
  $taps.Add($sw.Elapsed.TotalMilliseconds)
  Start-Sleep -Milliseconds $KeyDelayMs
}
$sorted = @($taps | Sort-Object)
$median = $sorted[[math]::Floor($sorted.Count * 0.5)]
$p95 = $sorted[[math]::Min($sorted.Count - 1, [math]::Floor($sorted.Count * 0.95))]
$jank = Get-JankyFrames
$pss = Get-TotalPssMb

Write-Output "## Device bench, phase $Phase ($serial), $(Get-Date -Format 'yyyy-MM-dd')"
Write-Output ''
Write-Output '| Measure | Value |'
Write-Output '|---|---|'
Write-Output "| First show, cold engine (app log) | $((@($coldLines | Select-Object -First 3)) -join ' / ') |"
Write-Output "| Later show (app log) | $((@($warmLines | Select-Object -First 3)) -join ' / ') |"
Write-Output "| Key -> commit, host-side ``input tap`` median / p95 | $([math]::Round($median, 1)) ms / $([math]::Round($p95, 1)) ms ($($taps.Count) keys) |"
Write-Output "| Janky frames while typing | $jank |"
Write-Output "| TOTAL PSS | $pss MB |"
Write-Output ''
Write-Output 'Host-side tap times include adb round trips, so they overstate the in-app latency. Use the [Keyboard] log lines for the in-app figure.'
