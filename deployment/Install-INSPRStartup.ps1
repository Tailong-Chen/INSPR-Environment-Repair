#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$ProjectRoot,
    [ValidateSet('auto','astigmatism','biplane')][string]$Toolbox = 'auto'
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$ProjectRoot = [IO.Path]::GetFullPath($ProjectRoot)
. (Join-Path $PSScriptRoot 'Get-INSPRToolboxes.ps1')
$profiles = @(Get-INSPRToolboxes -ProjectRoot $ProjectRoot -Toolbox $Toolbox)
if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'deployment\inspr_prepare_runtime.m'))) {
    throw 'The startup helper is missing. Copy the complete repair folder, including deployment and runtime, first.'
}
$pending = @()
foreach ($profile in $profiles) {
    # ASCII inspection only: preserve legacy Chinese encodings and a UTF-8 BOM.
    $bytes = [IO.File]::ReadAllBytes($profile.Main)
    $view = [Text.Encoding]::ASCII.GetString($bytes)
    if ($view.IndexOf([char]0) -ge 0) { throw "UTF-16 main.m is unsupported: $($profile.Main)" }
    $newline = if ($view.Contains("`r`n")) { "`r`n" } else { "`n" }
    $oldLines = @(
        '% BEGIN INSPR PRIVATE RUNTIME v1',
        'inspr_project_root = fileparts(fileparts(fileparts(mfilename(''fullpath''))));',
        'addpath(fullfile(inspr_project_root, ''deployment''));',
        'inspr_prepare_runtime(inspr_project_root);',
        'clear inspr_project_root',
        '% END INSPR PRIVATE RUNTIME v1', ''
    )
    $oldBlock = ($oldLines -join $newline) + $newline
    $newLines = $oldLines.Clone()
    $newLines[0] = '% BEGIN INSPR PRIVATE RUNTIME v2'
    $newLines[3] = "inspr_prepare_runtime(inspr_project_root, '$($profile.Id)');"
    $newLines[5] = '% END INSPR PRIVATE RUNTIME v2'
    $block = ($newLines -join $newline) + $newline
    $offset = 0
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191) { $offset = 3 }
    $body = $view.Substring($offset)
    $remove = 0
    if ($body.StartsWith($block)) { $remove = $block.Length }
    elseif ($body.StartsWith($oldBlock)) { $remove = $oldBlock.Length }
    $remaining = $body.Substring($remove)
    if ($remaining.Contains('% BEGIN INSPR PRIVATE RUNTIME') -or $remaining.Contains('% END INSPR PRIVATE RUNTIME')) {
        throw "An unrecognized or incomplete INSPR startup block exists: $($profile.Main). No entry points were changed."
    }
    if ($body.StartsWith($block)) {
        Write-Host "$($profile.Id) main.m runtime setup: already installed."
        continue
    }
    $header = [Text.Encoding]::ASCII.GetBytes($block)
    $updated = New-Object byte[] ($bytes.Length - $remove + $header.Length)
    [Array]::Copy($bytes,0,$updated,0,$offset)
    [Array]::Copy($header,0,$updated,$offset,$header.Length)
    [Array]::Copy($bytes,$offset+$remove,$updated,$offset+$header.Length,$bytes.Length-$offset-$remove)
    $pending += [pscustomobject]@{ Profile=$profile; Original=$bytes; Updated=$updated }
}
# Preflight every selected entry point before modifying any of them.
foreach ($change in $pending) {
    $backupDirectory = Join-Path $ProjectRoot 'deployment\backups'
    New-Item -ItemType Directory -Path $backupDirectory -Force | Out-Null
    $backup = Join-Path $backupDirectory ($change.Profile.Id + '_main_' + [guid]::NewGuid().ToString('N') + '.m.bak')
    [IO.File]::WriteAllBytes($backup,$change.Original)
    [IO.File]::WriteAllBytes($change.Profile.Main,$change.Updated)
    Write-Host "$($change.Profile.Id) main.m runtime setup installed. Original backup: $backup"
}
