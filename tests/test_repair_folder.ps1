# Catch the recipient's missing-DLL failure in the distributed folder itself.
param([Parameter(Mandatory=$true)][string]$RepairDirectory)
$ErrorActionPreference = 'Stop'
$RepairDirectory = [IO.Path]::GetFullPath($RepairDirectory)
$manifest = Get-Content -LiteralPath (Join-Path $RepairDirectory 'deployment\runtime-manifest.json') -Raw | ConvertFrom-Json
foreach ($entry in (@($manifest.runtime) + @($manifest.installers))) {
    $file = Join-Path $RepairDirectory $entry.path
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        throw "The distributed folder is incomplete: $($entry.path) must be present as a regular file."
    }
    if ((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -ne $entry.sha256) { throw "Wrong payload: $file" }
}
if (Test-Path -LiteralPath (Join-Path $RepairDirectory 'INSPR_Environment_Repair.zip')) {
    throw 'Do not distribute a nested repair ZIP; include the runtime and installer folders directly.'
}
$ps = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
& $ps -NoProfile -ExecutionPolicy Bypass -File (Join-Path $RepairDirectory 'deployment\Start-INSPR.ps1') -ProjectRoot $RepairDirectory -ValidateOnly
if ($LASTEXITCODE -ne 0) { throw 'The complete repair folder failed signature validation.' }
Write-Host 'PASS: the distributed folder contains all signed runtime files; no inner ZIP is required.'
