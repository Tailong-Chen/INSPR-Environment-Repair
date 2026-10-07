$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$installer = Join-Path $root 'deployment\Install-INSPRStartup.ps1'
$fixture = Join-Path $root ('deployment\cache\dual startup ' + [guid]::NewGuid().ToString('N'))
$paths = @{
    astigmatism = 'INSPR for astigmatism-based setup\INSPR astigmatism toolbox'
    biplane = 'INSPR for biplane setup\INSPR toolbox'
}
New-Item -ItemType Directory -Path (Join-Path $fixture 'deployment') -Force | Out-Null
Copy-Item -Path (Join-Path $root 'deployment\*.m') -Destination (Join-Path $fixture 'deployment')
$original = [Text.Encoding]::ASCII.GetBytes("% user script`r`ncustom_setting = 42;`r`n")
# A biplane-only distribution must work without an astigmatism directory.
$biplane = Join-Path $fixture ($paths.biplane + '\main.m')
New-Item -ItemType Directory -Path (Split-Path $biplane -Parent) -Force | Out-Null
[IO.File]::WriteAllBytes($biplane, $original)
& $installer -ProjectRoot $fixture
$first = [IO.File]::ReadAllBytes($biplane)
if (-not ([Text.Encoding]::ASCII.GetString($first).Contains("inspr_prepare_runtime(inspr_project_root, 'biplane');"))) {
    throw 'Biplane-only installation did not configure its own toolbox.'
}
if ([Convert]::ToBase64String($first[($first.Length-$original.Length)..($first.Length-1)]) -ne [Convert]::ToBase64String($original)) {
    throw 'Biplane user code was changed.'
}
# Add a previously repaired v1 astigmatism script; upgrade both in one run.
$astig = Join-Path $fixture ($paths.astigmatism + '\main.m')
New-Item -ItemType Directory -Path (Split-Path $astig -Parent) -Force | Out-Null
$v1 = @(
    '% BEGIN INSPR PRIVATE RUNTIME v1',
    'inspr_project_root = fileparts(fileparts(fileparts(mfilename(''fullpath''))));',
    'addpath(fullfile(inspr_project_root, ''deployment''));',
    'inspr_prepare_runtime(inspr_project_root);',
    'clear inspr_project_root',
    '% END INSPR PRIVATE RUNTIME v1', '', ''
) -join "`r`n"
$old = [byte[]]([Text.Encoding]::ASCII.GetBytes($v1) + $original)
[IO.File]::WriteAllBytes($astig, $old)
& $installer -ProjectRoot $fixture
$text = [IO.File]::ReadAllText($astig)
if (-not $text.Contains("inspr_prepare_runtime(inspr_project_root, 'astigmatism');") -or $text.Contains('RUNTIME v1')) { throw 'v1 upgrade failed.' }
if (-not $text.EndsWith([Text.Encoding]::ASCII.GetString($original))) { throw 'Upgrade changed user code.' }
$backups = @(Get-ChildItem -LiteralPath (Join-Path $fixture 'deployment\backups') -File)
if ($backups.Count -ne 2) { throw 'Expected exactly one backup per changed entry point.' }
if (-not ($backups | Where-Object { [Convert]::ToBase64String([IO.File]::ReadAllBytes($_.FullName)) -eq [Convert]::ToBase64String($old) })) { throw 'v1 backup missing.' }
& $installer -ProjectRoot $fixture
if (@(Get-ChildItem -LiteralPath (Join-Path $fixture 'deployment\backups') -File).Count -ne 2) { throw 'Repeat installation is not idempotent.' }
if ([Convert]::ToBase64String([IO.File]::ReadAllBytes($biplane)) -ne [Convert]::ToBase64String($first)) { throw 'Other toolbox was modified unnecessarily.' }
$rejected = $false
try { & $installer -ProjectRoot (Join-Path $fixture 'deployment') -Toolbox biplane } catch { $rejected = $true }
if (-not $rejected) { throw 'Missing requested toolbox was accepted.' }
Write-Host 'PASS: biplane-only discovery, dual installation, v1 upgrade, backup and idempotency.'
