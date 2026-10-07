# INSPR environment repair for Windows

This package supplies the CUDA and Visual C++ runtimes needed by the INSPR astigmatism and biplane toolboxes. It fixes common missing-DLL errors, including the misleading “Please install CUDA environment!” message.

You need an existing INSPR project, 64-bit Windows MATLAB, and an NVIDIA GPU with its driver installed.

**[Download the repository](https://github.com/Tailong-Chen/INSPR-Environment-Repair/archive/refs/heads/main.zip)** · [English guide](INSPR_Environment_Guide_EN.md) · [中文说明](INSPR_Environment_Guide.md)

## Install

1. Download this repository using the link above or **Code → Download ZIP**. Extract it once, open `INSPR-Environment-Repair-main`, and copy **all its contents** into your existing INSPR project folder.
2. Check that `Start-INSPR.cmd` sits beside the setup folder, as shown below. Either toolbox, or both, can be present.
3. Double-click `Start-INSPR.cmd`. Allow the Microsoft runtime installer if prompted, then wait for the GPU tests to finish.

![Repair files belong in the project root, beside the existing INSPR setup folders.](docs/images/extract-to-project.svg)

The launcher checks each installed toolbox in a separate MATLAB process. After the tests pass, it opens INSPR; if both toolboxes are installed, you choose which one to open.

The repository includes the required runtime files in `runtime/win64` and `deployment/installers`. No CUDA Toolkit, Visual Studio, or Python installation is needed. When updating an older repair package, replace its files and run the CMD once again.

There is no inner repair ZIP. After copying, this file should exist: `runtime/win64/cudart64_75.dll`. Keep the three `.exe` files under `deployment/installers` as well.

## Run INSPR

After setup, open the matching `main.m` in MATLAB and click **Run**. You can also set MATLAB’s Current Folder to that file’s directory and enter `main`.

![The main.m entry points for the astigmatism and biplane toolboxes.](docs/images/run-main-in-matlab.svg)

Run the whole script so its path setup executes. Keep `deployment` and `runtime` with the project; you do not need to run the CMD each time.

Use separate MATLAB processes for the two toolboxes. They share function names and GUI variables, so switching between them in one session can load the wrong code.

## Choose a toolbox or MATLAB version

Run these commands from PowerShell in the project folder:

```powershell
# Repair and test only biplane; use astigmatism for the other toolbox.
.\Start-INSPR.cmd -Toolbox biplane

# Use a specific MATLAB installation. Replace this example path.
.\Start-INSPR.cmd -MatlabExe "D:\MATLAB\R2024a\bin\matlab.exe"
```

Without options, the launcher detects MATLAB and tests all installed INSPR toolboxes. Add `-NoLaunch` to test without opening the GUI.

## Tested configuration

Both toolboxes passed on **Windows 11, MATLAB R2024a, RTX 3060 Ti, driver 591.86**. Tests covered separate and combined installations, paths with spaces and Chinese characters, and actual GPU fits. See the [validation record](docs/VALIDATION.md) for details and limits.

Other MATLAB releases and GPUs, including RTX 2080 Ti, need to pass the checks on the target computer. The synthetic fits check that the code runs; they do not measure accuracy on experimental data.

## Troubleshooting

If a check fails, keep the files from that run in `deployment/logs` and consult the [troubleshooting guide](INSPR_Environment_Guide_EN.md#troubleshooting). An incompatible MEX file may need recompilation even when all runtime libraries are present.

The repair backs up `main.m` under `deployment/backups` and adds a startup block that sets the toolbox and DLL paths for that MATLAB process. It leaves the system PATH and localization MEX files unchanged.

## Sources

Runtime downloads, checksums, and publishers are listed in [runtime-manifest.json](deployment/runtime-manifest.json). The package includes the [NVIDIA CUDA 7.5 license](deployment/licenses/NVIDIA-CUDA-7.5-EULA.txt); Microsoft installers retain their own licenses. File checksums are in [SHA256SUMS.txt](SHA256SUMS.txt).

The directory diagrams are rendered from [Python source](docs/render_quickstart.py). SVG and PNG exports are in `docs/images`.
