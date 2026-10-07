#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ProjectRoot,
    [string]$MatlabExe,
    [ValidateSet('auto','astigmatism','biplane')][string]$Toolbox = 'auto',
    [switch]$NoLaunch,
    [switch]$NoInstall,
    [switch]$ValidateOnly
)
$ErrorActionPreference = 'Stop'
# A CMD launched by PowerShell 7 can inherit its incompatible PSModulePath.
# Load the Windows PowerShell modules explicitly for the Win11 double-click path.
foreach ($module in 'Utility','Management','Security') {
    Import-Module (Join-Path $PSHOME ("Modules\Microsoft.PowerShell.$module\Microsoft.PowerShell.$module.psd1")) -Force
}
Set-StrictMode -Version Latest
if (-not $ProjectRoot) { $ProjectRoot = Split-Path $PSScriptRoot -Parent }
. (Join-Path $PSScriptRoot 'Get-INSPRToolboxes.ps1')

function Resolve-PackageFile($Entry) {
    $file = [IO.Path]::GetFullPath((Join-Path $ProjectRoot $Entry.path))
    $prefix = $ProjectRoot.TrimEnd('\') + '\'
    if (-not $file.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Package path escapes the project directory.'
    }
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        throw "Package file is missing: $file. Copy ALL files from the repair repository, including runtime and deployment/installers, into the INSPR project folder."
    }
    if ((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -ne $Entry.sha256) {
        throw "SHA256 mismatch: $file. Copy a fresh, complete repair folder from the official repository."
    }
    $signature = Get-AuthenticodeSignature -LiteralPath $file
    if ($signature.Status -ne 'Valid' -or
        $signature.SignerCertificate.Subject -notlike ('*' + $Entry.publisher + '*')) {
        throw "Publisher signature validation failed: $file ($($signature.Status))."
    }
    return $file
}

function Test-VCRuntime([string]$Version) {
    switch ($Version) {
        '2013' { return (Test-Path -LiteralPath (Join-Path $env:SystemRoot 'System32\msvcr120.dll')) }
        '2010' { return (Test-Path -LiteralPath (Join-Path $env:SystemRoot 'System32\msvcr100.dll')) }
        '2008' {
            $assemblies = @(Get-ChildItem -Path (Join-Path $env:SystemRoot 'WinSxS\amd64_microsoft.vc90.crt_*') -Directory -ErrorAction SilentlyContinue)
            foreach ($assembly in $assemblies) {
                if (Test-Path -LiteralPath (Join-Path $assembly.FullName 'msvcr90.dll')) { return $true }
            }
            return $false
        }
        default { throw "Unsupported VC runtime: $Version" }
    }
}

function Find-Matlab {
    if ($MatlabExe) {
        if (-not (Test-Path -LiteralPath $MatlabExe -PathType Leaf)) { throw "MATLAB executable not found: $MatlabExe" }
        return [IO.Path]::GetFullPath($MatlabExe)
    }
    $candidates = @()
    $registry = @(Get-ChildItem -LiteralPath 'HKLM:\SOFTWARE\MathWorks\MATLAB' -ErrorAction SilentlyContinue | Sort-Object {
        $release = $null
        if ([version]::TryParse($_.PSChildName, [ref]$release)) { $release } else { [version]'0.0' }
    } -Descending)
    foreach ($key in $registry) {
        $properties = Get-ItemProperty -LiteralPath $key.PSPath
        if ($properties.PSObject.Properties.Name -contains 'MATLABROOT') {
            $candidates += Join-Path $properties.MATLABROOT 'bin\matlab.exe'
        }
    }
    $folders = @(Get-ChildItem -Path (Join-Path $env:ProgramFiles 'MATLAB\R*') -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending)
    foreach ($folder in $folders) { $candidates += Join-Path $folder.FullName 'bin\matlab.exe' }
    $command = Get-Command matlab.exe -ErrorAction SilentlyContinue
    if ($command) { $candidates += $command.Source }
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    }
    throw 'MATLAB was not found. Use Start-INSPR.cmd -MatlabExe "D:\MATLAB\R2024a\bin\matlab.exe".'
}

$transcriptStarted = $false
try {
    $ProjectRoot = [IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\')
    if (-not [Environment]::Is64BitProcess) { throw 'Run this tool using 64-bit Windows PowerShell.' }
    $manifestPath = Join-Path $ProjectRoot 'deployment\runtime-manifest.json'
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    if ($manifest.schema -ne 1) { throw 'Unsupported runtime manifest.' }
    Write-Host '[1/5] Verifying the offline NVIDIA and Microsoft packages...'
    $runtimeFile = Resolve-PackageFile $manifest.runtime
    $installerFiles = @{}
    foreach ($entry in $manifest.installers) { $installerFiles[$entry.version] = Resolve-PackageFile $entry }
    if ($ValidateOnly) { Write-Host 'PASS: all package hashes and publisher signatures are valid.'; exit 0 }

    $profiles = @(Get-INSPRToolboxes -ProjectRoot $ProjectRoot -Toolbox $Toolbox)
    Write-Host ('Detected toolboxes: ' + (($profiles | ForEach-Object { $_.Id }) -join ', '))
    $logs = Join-Path $ProjectRoot 'deployment\logs'
    New-Item -ItemType Directory -Path $logs -Force | Out-Null
    $runId = (Get-Date -Format 'yyyyMMdd_HHmmss') + '_' + [guid]::NewGuid().ToString('N').Substring(0,8)
    Start-Transcript -LiteralPath (Join-Path $logs ($runId + '_launcher.txt')) | Out-Null
    $transcriptStarted = $true
    $matlab = Find-Matlab
    Write-Host "MATLAB: $matlab"

    Write-Host '[2/5] Preparing the private CUDA runtime...'
    # Only this launcher and its MATLAB children inherit the private DLL path.
    $env:PATH = (Split-Path $runtimeFile -Parent) + ';' + $env:PATH
    $env:INSPR_PROJECT_ROOT = $ProjectRoot
    $smi = Join-Path $env:SystemRoot 'System32\nvidia-smi.exe'
    if (-not (Test-Path -LiteralPath $smi)) {
        throw 'The NVIDIA display driver was not found. Install the current driver for your NVIDIA GPU, then rerun this launcher.'
    }
    & $smi --query-gpu=name,driver_version --format=csv,noheader
    if ($LASTEXITCODE -ne 0) { throw 'The NVIDIA driver could not access a GPU. See nvidia-smi output above.' }

    Write-Host '[3/5] Checking Microsoft x64 runtimes...'
    foreach ($entry in $manifest.installers) {
        if (Test-VCRuntime $entry.version) { Write-Host "VC++ $($entry.version) x64: already available"; continue }
        if ($NoInstall) { throw "VC++ $($entry.version) x64 is missing; -NoInstall prevents automatic installation." }
        Write-Host "Installing official VC++ $($entry.version) x64. Accept the Windows permission prompt if shown."
        $process = Start-Process -FilePath $installerFiles[$entry.version] -ArgumentList $entry.arguments -Verb RunAs -WindowStyle Hidden -Wait -PassThru
        if ($process.ExitCode -eq 3010) { throw 'A Microsoft runtime requires a Windows restart. Restart Windows, then run Start-INSPR.cmd again.' }
        if ($process.ExitCode -notin @(0,1638)) { throw "VC++ $($entry.version) installer failed with exit code $($process.ExitCode)." }
        if (-not (Test-VCRuntime $entry.version)) { throw "VC++ $($entry.version) is still unavailable after installation." }
    }

    & (Join-Path $PSScriptRoot 'Install-INSPRStartup.ps1') -ProjectRoot $ProjectRoot -Toolbox $Toolbox
    Write-Host '[4/5] Testing direct main.m startup, segmentation, reconstruction and GPU localization...'
    Write-Host 'The first GPU kernel compilation can take a few minutes.'
    $failures = @()
    foreach ($profile in $profiles) {
        Write-Host ('Testing toolbox: ' + $profile.Id)
        $env:INSPR_TOOLBOX = $profile.Id
        try {
            $env:INSPR_PROBE_STATUS = Join-Path $logs ($runId + '_' + $profile.Id + '_status.txt')
            $env:INSPR_PROBE_REPORT = Join-Path $logs ($runId + '_' + $profile.Id + '_environment.txt')
            $matlabLog = Join-Path $logs ($runId + '_' + $profile.Id + '_matlab.txt')
            # Environment variables avoid interpolating project paths into MATLAB code.
            $probeCode = "try, addpath(fullfile(getenv('INSPR_PROJECT_ROOT'),'deployment')); inspr_runtime_probe; exit(0); catch ME, disp(getReport(ME,'extended','hyperlinks','off')); exit(1); end"
            $arguments = '-wait -nosplash -nodesktop -logfile "{0}" -r "{1}"' -f $matlabLog,$probeCode
            $probe = Start-Process -FilePath $matlab -ArgumentList $arguments -WorkingDirectory $ProjectRoot -WindowStyle Hidden -PassThru
            $watch = [Diagnostics.Stopwatch]::StartNew()
            while (-not $probe.WaitForExit(15000)) {
                Write-Host ('GPU test running... {0:N0} seconds' -f $watch.Elapsed.TotalSeconds)
                if ($watch.Elapsed.TotalSeconds -gt 300) {
                    # Terminate only the helper process tree that this run created.
                    if (-not $probe.HasExited) { & (Join-Path $env:SystemRoot 'System32\taskkill.exe') /PID $probe.Id /T /F | Out-Null }
                    throw "MATLAB validation timed out. Check $matlabLog (license dialogs or startup scripts may block MATLAB)."
                }
            }
            $probe.WaitForExit()
            $status = ''
            if (Test-Path -LiteralPath $env:INSPR_PROBE_STATUS) { $status = (Get-Content -LiteralPath $env:INSPR_PROBE_STATUS -Raw).Trim() }
            if ($probe.ExitCode -ne 0 -or $status -ne 'INSPR_RUNTIME_OK') {
                throw "$($profile.Id) GPU validation failed. $status`nFull MATLAB log: $matlabLog"
            }
            Write-Host ('PASS: ' + $profile.Id + ' startup and real GPU localization.') -ForegroundColor Green
        } catch {
            $failures += $_.Exception.Message
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    }
    if ($failures.Count -gt 0) { throw ($failures -join "`n") }
    Write-Host 'PASS: all selected INSPR toolboxes ran their own GPU localization MEX successfully.' -ForegroundColor Green
    Write-Host 'One-time setup complete. In future, open MATLAB normally and run the project main.m.' -ForegroundColor Green
    Write-Host "Logs: $logs"
    $env:INSPR_TOOLBOX = $Toolbox
    if (-not $NoLaunch) {
        Write-Host '[5/5] Opening INSPR in a configured MATLAB window...'
        $startCode = "addpath(fullfile(getenv('INSPR_PROJECT_ROOT'),'deployment')); inspr_start_gui;"
        $arguments = '-desktop -nosplash -r "{0}"' -f $startCode
        # This is the interactive application the recipient will use.
        Start-Process -FilePath $matlab -ArgumentList $arguments -WorkingDirectory $ProjectRoot -WindowStyle Normal | Out-Null
    } else {
        Write-Host '[5/5] Verification complete (-NoLaunch).'
    }
    if ($transcriptStarted) { Stop-Transcript | Out-Null }
    exit 0
} catch {
    Write-Host ('ERROR: ' + $_.Exception.Message) -ForegroundColor Red
    if ($transcriptStarted) { Stop-Transcript | Out-Null }
    exit 1
}
