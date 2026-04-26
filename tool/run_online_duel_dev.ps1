# Starts the Firestore emulator, then runs the app with DUEL_USE_EMULATOR.
# Requires: Node.js (npx), Java 17+ (Firestore emulator), Flutter SDK.
#
# Android emulator: no extra args.
# Physical phone on same Wi‑Fi: .\tool\run_online_duel_dev.ps1 -DeviceHost 192.168.x.x
#   (use your PC's LAN IP; firewall must allow TCP 8080.)

param(
  [string] $DeviceHost = "",
  [string] $DeviceId = ""
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
  Write-Error "Java (JDK 17+) is required. Install Temurin or Oracle JDK and retry."
}

if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
  Write-Error "Node.js / npx is required. Install from https://nodejs.org and retry."
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Error "flutter not in PATH."
}

Write-Host "Starting Firestore emulator on 0.0.0.0:8080 ..."
$EmuJob = Start-Job -ScriptBlock {
  Set-Location $using:Root
  npx --yes firebase-tools@14 emulators:start --only firestore --project demo-sudoku-duel 2>&1
}

try {
  $ready = $false
  for ($i = 0; $i -lt 90; $i++) {
    try {
      $c = Test-NetConnection -ComputerName 127.0.0.1 -Port 8080 -WarningAction SilentlyContinue
      if ($c.TcpTestSucceeded) {
        $ready = $true
        break
      }
    } catch {}
    if ($EmuJob.State -eq "Failed") {
      Receive-Job $EmuJob
      throw "Emulator job failed."
    }
    Start-Sleep -Seconds 1
  }
  if (-not $ready) {
    Receive-Job $EmuJob -ErrorAction SilentlyContinue
    throw "Firestore emulator did not open port 8080 in time."
  }

  Write-Host "Emulator ready. Launching Flutter with DUEL_USE_EMULATOR ..."

  $defines = @("DUEL_USE_EMULATOR=true")
  if ($DeviceHost -ne "") {
    $defines += "DUEL_EMULATOR_HOST=$DeviceHost"
  }

  $flutterArgs = @("run")
  foreach ($d in $defines) {
    $flutterArgs += "--dart-define=$d"
  }
  if ($DeviceId -ne "") {
    $flutterArgs += "-d"
    $flutterArgs += $DeviceId
  }

  & flutter @flutterArgs
} finally {
  Write-Host "Stopping emulator job..."
  Stop-Job $EmuJob -ErrorAction SilentlyContinue
  Remove-Job $EmuJob -Force -ErrorAction SilentlyContinue
}
