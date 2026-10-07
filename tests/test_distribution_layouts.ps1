# Slow end-to-end test. Needs separate application and repair folders, MATLAB and an NVIDIA GPU.
# Every layout copies the distributed files directly and uses separate MATLAB processes.
param(
    [Parameter(Mandatory=$true)][string]$RepairDirectory,
    [string]$ApplicationRoot,
    [string]$MatlabExe
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
if (-not $ApplicationRoot) { $ApplicationRoot = $root }
$RepairDirectory = [IO.Path]::GetFullPath($RepairDirectory)
& (Join-Path $PSScriptRoot 'test_repair_folder.ps1') -RepairDirectory $RepairDirectory
$ps = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$definitions = @{
    astigmatism = @('INSPR for astigmatism-based setup','INSPR astigmatism toolbox')
    biplane = @('INSPR for biplane setup','INSPR toolbox')
}
$runRoot = Join-Path $ApplicationRoot ('deployment\cache\layout ' + [char]0x6D4B + [char]0x8BD5 + ' ' + [guid]::NewGuid().ToString('N'))
foreach ($layout in 'astigmatism','biplane','both') {
    $fixture = Join-Path $runRoot $layout
    if ([IO.Path]::GetFullPath($fixture).StartsWith($RepairDirectory.TrimEnd('\')+'\',[StringComparison]::OrdinalIgnoreCase)) {
        throw 'Use a separate RepairDirectory; the test destination must not be inside it.'
    }
    New-Item -ItemType Directory -Path $fixture -Force | Out-Null
    $ids = if ($layout -eq 'both') { @('astigmatism','biplane') } else { @($layout) }
    foreach ($id in $ids) {
        $definition = $definitions[$id]
        $base = Join-Path $fixture $definition[0]
        New-Item -ItemType Directory -Path $base -Force | Out-Null
        # Only application code and support files; never copy the experiment Data folder.
        Copy-Item -LiteralPath (Join-Path $ApplicationRoot ($definition[0] + '\Support')) -Destination $base -Recurse
        Copy-Item -LiteralPath (Join-Path $ApplicationRoot ($definition[0] + '\' + $definition[1])) -Destination $base -Recurse
        $main = Join-Path $base ($definition[1] + '\main.m')
        $bytes = [IO.File]::ReadAllBytes($main)
        $view = [Text.Encoding]::ASCII.GetString($bytes)
        # Start from an unpatched entry point, retaining all original script bytes.
        $match = [regex]::Match($view,'(?s)^% BEGIN INSPR PRIVATE RUNTIME v[12].*?% END INSPR PRIVATE RUNTIME v[12]\r?\n\r?\n')
        if ($match.Success) { [IO.File]::WriteAllBytes($main,[byte[]]$bytes[$match.Length..($bytes.Length-1)]) }
    }
    # The repository itself is the repair folder; no nested archive is opened.
    foreach ($item in (Get-ChildItem -LiteralPath $RepairDirectory -Force | Where-Object { $_.Name -ne '.git' })) {
        Copy-Item -LiteralPath $item.FullName -Destination $fixture -Recurse -Force
    }
    $arguments = @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $fixture 'deployment\Start-INSPR.ps1'),'-NoInstall','-NoLaunch')
    if ($MatlabExe) { $arguments += @('-MatlabExe',$MatlabExe) }
    & $ps @arguments
    if ($LASTEXITCODE -ne 0) { throw "Downloaded-folder layout failed: $layout ($fixture)" }
    $statuses = @(Get-ChildItem -LiteralPath (Join-Path $fixture 'deployment\logs') -Filter '*_status.txt')
    if ($statuses.Count -ne $ids.Count) { throw "Wrong number of toolbox probes: $layout" }
    foreach ($status in $statuses) {
        if ((Get-Content -LiteralPath $status.FullName -Raw).Trim() -ne 'INSPR_RUNTIME_OK') { throw "Failed probe: $($status.FullName)" }
    }
    Write-Host "PASS: copied repair folder with $layout layout. Logs: $fixture"
}
Write-Host 'PASS: all three folder layouts, including spaces and Chinese characters.'
