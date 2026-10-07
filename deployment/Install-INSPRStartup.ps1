#requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$ProjectRoot)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$ProjectRoot = [IO.Path]::GetFullPath($ProjectRoot)
$main = Join-Path $ProjectRoot 'INSPR for astigmatism-based setup\INSPR astigmatism toolbox\main.m'
if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'deployment\inspr_prepare_runtime.m'))) {
    throw 'The startup helper is missing. Extract the ENTIRE repair ZIP first.'
}
# Decode only for ASCII inspection; preserve every original byte on write.
# Some copies of INSPR use a legacy Chinese encoding rather than UTF-8.
$bytes = [IO.File]::ReadAllBytes($main)
$view = [Text.Encoding]::ASCII.GetString($bytes)
if ($view.IndexOf([char]0) -ge 0) { throw 'UTF-16 main.m is not supported by the automatic patcher.' }
$newline = if ($view.Contains("`r`n")) { "`r`n" } else { "`n" }
$lines = @(
    '% BEGIN INSPR PRIVATE RUNTIME v1',
    'inspr_project_root = fileparts(fileparts(fileparts(mfilename(''fullpath''))));',
    'addpath(fullfile(inspr_project_root, ''deployment''));',
    'inspr_prepare_runtime(inspr_project_root);',
    'clear inspr_project_root',
    '% END INSPR PRIVATE RUNTIME v1',
    ''
)
$block = ($lines -join $newline) + $newline
if ($view.Contains('% BEGIN INSPR PRIVATE RUNTIME')) {
    if (-not $view.Contains($block)) { throw 'An unrecognized INSPR startup block exists; main.m was left unchanged.' }
    Write-Host 'Automatic main.m runtime setup: already installed.'
    return
}
if ($view.Contains('% END INSPR PRIVATE RUNTIME')) { throw 'Incomplete INSPR startup block; main.m was left unchanged.' }
$backupDirectory = Join-Path $ProjectRoot 'deployment\backups'
New-Item -ItemType Directory -Path $backupDirectory -Force | Out-Null
$backup = Join-Path $backupDirectory ('main_' + [guid]::NewGuid().ToString('N') + '.m.bak')
[IO.File]::WriteAllBytes($backup, $bytes)
$header = [Text.Encoding]::ASCII.GetBytes($block)
# Keep a UTF-8 BOM at byte zero if the original script has one.
$offset = 0
if ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191) { $offset = 3 }
$updated = New-Object byte[] ($bytes.Length + $header.Length)
[Array]::Copy($bytes, 0, $updated, 0, $offset)
[Array]::Copy($header, 0, $updated, $offset, $header.Length)
[Array]::Copy($bytes, $offset, $updated, $offset + $header.Length, $bytes.Length - $offset)
[IO.File]::WriteAllBytes($main, $updated)
Write-Host "Automatic main.m runtime setup installed. Original backup: $backup"
