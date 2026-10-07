# Slow end-to-end test. Needs a full project, built repair ZIP, MATLAB and NVIDIA GPU.
# Every layout uses the actual extracted package and separate MATLAB processes.
param([string]$MatlabExe)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$ps = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$definitions = @{
    astigmatism = @('INSPR for astigmatism-based setup','INSPR astigmatism toolbox')
    biplane = @('INSPR for biplane setup','INSPR toolbox')
}
$runRoot = Join-Path $root ('deployment\cache\layout ' + [char]0x6D4B + [char]0x8BD5 + ' ' + [guid]::NewGuid().ToString('N'))
foreach ($layout in 'astigmatism','biplane','both') {
    $fixture = Join-Path $runRoot $layout
    New-Item -ItemType Directory -Path $fixture -Force | Out-Null
    $ids = if ($layout -eq 'both') { @('astigmatism','biplane') } else { @($layout) }
    foreach ($id in $ids) {
        $definition = $definitions[$id]
        $base = Join-Path $fixture $definition[0]
        New-Item -ItemType Directory -Path $base -Force | Out-Null
        # Only application code and support files; never copy the experiment Data folder.
        Copy-Item -LiteralPath (Join-Path $root ($definition[0] + '\Support')) -Destination $base -Recurse
        Copy-Item -LiteralPath (Join-Path $root ($definition[0] + '\' + $definition[1])) -Destination $base -Recurse
        $main = Join-Path $base ($definition[1] + '\main.m')
        $bytes = [IO.File]::ReadAllBytes($main)
        $view = [Text.Encoding]::ASCII.GetString($bytes)
        # Start from an unpatched entry point, retaining all original script bytes.
        $match = [regex]::Match($view,'(?s)^% BEGIN INSPR PRIVATE RUNTIME v[12].*?% END INSPR PRIVATE RUNTIME v[12]\r?\n\r?\n')
        if ($match.Success) { [IO.File]::WriteAllBytes($main,[byte[]]$bytes[$match.Length..($bytes.Length-1)]) }
    }
    Expand-Archive -LiteralPath (Join-Path $root 'INSPR_Environment_Repair.zip') -DestinationPath $fixture
    $arguments = @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $fixture 'deployment\Start-INSPR.ps1'),'-NoInstall','-NoLaunch')
    if ($MatlabExe) { $arguments += @('-MatlabExe',$MatlabExe) }
    & $ps @arguments
    if ($LASTEXITCODE -ne 0) { throw "Downloaded-package layout failed: $layout ($fixture)" }
    $statuses = @(Get-ChildItem -LiteralPath (Join-Path $fixture 'deployment\logs') -Filter '*_status.txt')
    if ($statuses.Count -ne $ids.Count) { throw "Wrong number of toolbox probes: $layout" }
    foreach ($status in $statuses) {
        if ((Get-Content -LiteralPath $status.FullName -Raw).Trim() -ne 'INSPR_RUNTIME_OK') { throw "Failed probe: $($status.FullName)" }
    }
    Write-Host "PASS: extracted repair ZIP with $layout layout. Logs: $fixture"
}
Write-Host 'PASS: all three package layouts, including spaces and Chinese characters.'
