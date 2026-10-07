#requires -Version 5.1
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$powershell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
& $powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'Start-INSPR.ps1') -ValidateOnly
if ($LASTEXITCODE -ne 0) { throw 'Runtime package validation failed.' }
$files = @(
    'Start-INSPR.cmd', 'setup_inspr_cuda.m', 'CUDA_SETUP.md', 'INSPR_Environment_Guide.md',
    'INSPR_Environment_Guide_EN.md', 'docs\images\extract-to-project.png',
    'docs\images\run-main-in-matlab.png', 'docs\images\extract-to-project.svg',
    'docs\images\run-main-in-matlab.svg',
    'deployment\Start-INSPR.ps1', 'deployment\Get-INSPRToolboxes.ps1',
    'deployment\inspr_toolbox_profile.m', 'deployment\inspr_configure_paths.m',
    'deployment\inspr_biplane_smoketest.m', 'deployment\runtime-manifest.json',
    'deployment\inspr_gpu_smoketest.m', 'deployment\inspr_runtime_probe.m',
    'deployment\inspr_start_gui.m', 'deployment\licenses\NVIDIA-CUDA-7.5-EULA.txt',
    'deployment\Install-INSPRStartup.ps1', 'deployment\inspr_prepare_runtime.m',
    'runtime\win64\cudart64_75.dll',
    'deployment\installers\vcredist2008_x64.exe',
    'deployment\installers\vcredist2010_x64.exe',
    'deployment\installers\vcredist2013_x64.exe'
)
$stage = Join-Path $PSScriptRoot ('staging\' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage -Force | Out-Null
foreach ($file in $files) {
    $source = Join-Path $root $file
    $destination = Join-Path $stage $file
    New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null
    Copy-Item -LiteralPath $source -Destination $destination
}
$zip = Join-Path $root 'INSPR_Environment_Repair.zip'
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip -Force
Get-Item -LiteralPath $zip | Select-Object FullName,Length
Get-FileHash -LiteralPath $zip -Algorithm SHA256 | Format-List
