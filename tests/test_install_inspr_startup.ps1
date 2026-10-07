$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$installer = Join-Path $root 'deployment\Install-INSPRStartup.ps1'
$fixture = Join-Path $root ('deployment\cache\startup space ' + [guid]::NewGuid().ToString('N'))
$toolbox = Join-Path $fixture 'INSPR for astigmatism-based setup\INSPR astigmatism toolbox'
New-Item -ItemType Directory -Path $toolbox,(Join-Path $fixture 'deployment') -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'deployment\inspr_prepare_runtime.m') -Destination (Join-Path $fixture 'deployment')
$main = Join-Path $toolbox 'main.m'
# A UTF-8 BOM, CRLF, user code, and non-UTF8 comment bytes must survive intact.
$original = [byte[]](@(239,187,191) + [Text.Encoding]::ASCII.GetBytes("% custom main`r`n% ") + @(214,208,206,196) + [Text.Encoding]::ASCII.GetBytes("`r`nuser_setting = 42;`r`n"))
[IO.File]::WriteAllBytes($main, $original)
& $installer -ProjectRoot $fixture
$updated = [IO.File]::ReadAllBytes($main)
if ($updated.Length -le $original.Length) { throw 'The startup installer did not add a bootstrap.' }
if ([Convert]::ToBase64String($updated[0..2]) -ne '77u/') { throw 'The UTF-8 BOM was moved or changed.' }
$suffix = $updated[($updated.Length - $original.Length + 3)..($updated.Length - 1)]
if ([Convert]::ToBase64String($suffix) -ne [Convert]::ToBase64String($original[3..($original.Length-1)])) {
    throw 'The startup installer changed original script bytes.'
}
$backups = @(Get-ChildItem -LiteralPath (Join-Path $fixture 'deployment\backups') -File)
if ($backups.Count -ne 1 -or [Convert]::ToBase64String([IO.File]::ReadAllBytes($backups[0].FullName)) -ne [Convert]::ToBase64String($original)) {
    throw 'The exact original was not backed up before patching.'
}
& $installer -ProjectRoot $fixture
if ([Convert]::ToBase64String([IO.File]::ReadAllBytes($main)) -ne [Convert]::ToBase64String($updated)) {
    throw 'A repeated installation changed the script.'
}
if (@(Get-ChildItem -LiteralPath (Join-Path $fixture 'deployment\backups') -File).Count -ne 1) { throw 'Repeated setup created another backup.' }
# Do not silently extend an incomplete or user-edited managed block.
$partial = [Text.Encoding]::ASCII.GetBytes("% BEGIN INSPR PRIVATE RUNTIME v1`ncustom_code;`n")
[IO.File]::WriteAllBytes($main, $partial)
$rejected = $false
try { & $installer -ProjectRoot $fixture } catch { $rejected = $true }
if (-not $rejected -or [Convert]::ToBase64String([IO.File]::ReadAllBytes($main)) -ne [Convert]::ToBase64String($partial)) {
    throw 'An unrecognized managed block was not preserved and rejected.'
}
Write-Host 'PASS: startup installation preserves script bytes and BOM, backs up originals, and is idempotent.'
