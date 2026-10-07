$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$launcher = Join-Path $root 'deployment\Start-INSPR.ps1'
if (-not (Test-Path -LiteralPath $launcher)) { throw 'The automatic repair launcher is missing.' }
$powershell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
& $powershell -NoProfile -ExecutionPolicy Bypass -File $launcher -ValidateOnly
if ($LASTEXITCODE -ne 0) { throw 'The genuine offline package failed validation.' }

# Reject corrupt runtime bytes before any installer or MATLAB can run.
$fixture = Join-Path $root ('deployment\cache\tamper-test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $fixture 'runtime\win64'),(Join-Path $fixture 'deployment') -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'deployment\runtime-manifest.json') -Destination (Join-Path $fixture 'deployment\runtime-manifest.json')
[IO.File]::WriteAllText((Join-Path $fixture 'runtime\win64\cudart64_75.dll'), 'Corrupt test fixture: never executable')
$output = & $powershell -NoProfile -ExecutionPolicy Bypass -File $launcher -ProjectRoot $fixture -ValidateOnly 2>&1
if ($LASTEXITCODE -eq 0 -or ($output -join "`n") -notmatch 'SHA256 mismatch') {
    throw 'A corrupt runtime was not rejected at the integrity boundary.'
}
Write-Host 'PASS: signed offline package accepted; corrupt runtime rejected before execution.'
