# Shared discovery for the launcher and byte-preserving startup installer.
function Get-INSPRToolboxes {
    param([string]$ProjectRoot, [ValidateSet('auto','astigmatism','biplane')][string]$Toolbox = 'auto')
    $definitions = @(
        @{ Id='astigmatism'; Directory='INSPR for astigmatism-based setup\INSPR astigmatism toolbox' },
        @{ Id='biplane'; Directory='INSPR for biplane setup\INSPR toolbox' }
    )
    $found = @()
    foreach ($definition in $definitions) {
        if ($Toolbox -ne 'auto' -and $Toolbox -ne $definition.Id) { continue }
        $directory = Join-Path $ProjectRoot $definition.Directory
        if (Test-Path -LiteralPath (Join-Path $directory 'main.m') -PathType Leaf) {
            $found += [pscustomobject]@{ Id=$definition.Id; Directory=$directory; Main=(Join-Path $directory 'main.m') }
        }
    }
    if ($found.Count -eq 0) {
        throw "No $Toolbox INSPR entry point found in $ProjectRoot. Put the repair files BESIDE 'INSPR for astigmatism-based setup' or 'INSPR for biplane setup', not inside either folder."
    }
    return $found
}
