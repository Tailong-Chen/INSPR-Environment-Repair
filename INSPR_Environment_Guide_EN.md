# INSPR environment repair: illustrated user guide

Updated: 2026-10-08. Applies to the **INSPR astigmatism and biplane toolboxes on 64-bit Windows**.

[Download the repository](https://github.com/Tailong-Chen/INSPR-Environment-Repair/archive/refs/heads/main.zip) · [GitHub repository](https://github.com/Tailong-Chen/INSPR-Environment-Repair) · [中文说明](INSPR_Environment_Guide.md)

**Run the repair once. Afterwards, open MATLAB normally and run the project's entire `main.m` script.**

## Before you start

You need an existing, complete INSPR astigmatism or biplane project, a working installation of 64-bit Windows MATLAB, and the NVIDIA driver for your GPU. This download supplies runtime dependencies and setup scripts; it does not include the full INSPR application, MATLAB, paid MATLAB toolboxes, or a graphics driver.

The images below are folder-layout illustrations. `C:\SMLM\INSPR-master` is an **example location**, not a required path. Use the folder where your own INSPR project is stored.

## 1. Download the repair folder

Use **Code → Download ZIP** on GitHub or the download link above. Extract the repository archive once and open `INSPR-Environment-Repair-main`.

The repository contains the files directly. There is no inner repair ZIP. Before continuing, check that it includes:

```text
Start-INSPR.cmd
runtime/win64/cudart64_75.dll
deployment/installers/vcredist2008_x64.exe
deployment/installers/vcredist2010_x64.exe
deployment/installers/vcredist2013_x64.exe
```

## 2. Copy the files to your existing INSPR project

1. Select **all contents** of `INSPR-Environment-Repair-main`, then copy them.
2. Open the existing INSPR project root: the folder containing `INSPR for astigmatism-based setup`, `INSPR for biplane setup`, or both.
3. Paste the contents there. Merge folders and replace older repair files if prompted.

![Copy the complete repair folder contents beside the existing setup folders.](docs/images/extract-to-project.png)

The result should look like this:

```text
Your existing INSPR project root
├─ INSPR for astigmatism-based setup    ← if installed
├─ INSPR for biplane setup              ← if installed
├─ Start-INSPR.cmd
├─ deployment/
│  └─ installers/                      ← three Microsoft installers
├─ runtime/
│  └─ win64/
│     └─ cudart64_75.dll
├─ docs/
└─ other repair scripts and guides
```

Copy the contents, rather than placing the whole `INSPR-Environment-Repair-main` folder inside your project. The CMD and the setup folders need the same parent folder.

## 3. Run the repair once

Double-click **`Start-INSPR.cmd` in the existing project root**. If Windows hides known filename extensions, it may be displayed as `Start-INSPR`.

The launcher verifies the bundled NVIDIA DLL and Microsoft installers, checks the GPU driver, installs missing VC++ x64 runtimes when needed, and adds an automatic setup block to your existing `main.m`. Allow the official Microsoft installer permission prompt if a required runtime is missing. The original `main.m` is backed up under `deployment/backups`.

It then starts a separate MATLAB process **for each detected toolbox** and checks its GUI startup, segmentation, reconstruction, and a small synthetic 3D GPU fit. Successful validation ends with:

```text
PASS: all selected INSPR toolboxes ran their own GPU localization MEX successfully.
One-time setup complete. In future, open MATLAB normally and run the project main.m.
```

The launcher opens INSPR after validation. When both toolboxes are present, a MATLAB dialog lets you select which one to open. Both were repaired and tested. A missing toolbox is not required or downloaded. If a Microsoft installer explicitly requests a Windows restart, restart and run the launcher again. You do not need to install Python, Visual Studio, or the complete CUDA 7.5 Toolkit for this package.

## 4. Everyday use: run main.m in MATLAB

After setup has passed, open MATLAB normally. Navigate inside your existing project as shown below:

![Choose the astigmatism or biplane path and run its entire main.m script in a separate MATLAB process.](docs/images/run-main-in-matlab.png)

Choose the matching entry file, relative to your project root:

```text
INSPR for astigmatism-based setup/
└─ INSPR astigmatism toolbox/
   └─ main.m

INSPR for biplane setup/
└─ INSPR toolbox/
   └─ main.m
```

Open that file in the MATLAB Editor and click **Run**, or set MATLAB's **Current Folder** to the chosen toolbox folder and enter:

```matlab
main
```

Run the **whole script**. Calling `INSPR_ast_GUI` or `INSPR_GUI` directly or running only the final section of `main.m` can skip the automatic setup. Keep `deployment` and `runtime` with the project. When relocating it, move the entire project folder.

**Use a separate MATLAB process for each toolbox.** Both contain same-named functions/classes and share GUI globals. The repair configures only the chosen toolbox and refuses to mix them in one MATLAB session. Open another MATLAB window or restart MATLAB to switch. Do not use `addpath(genpath(projectRoot))`.

To repair/test only one installed toolbox:

```powershell
.\Start-INSPR.cmd -Toolbox biplane
.\Start-INSPR.cmd -Toolbox astigmatism
```

To validate all detected toolboxes without opening an interactive GUI, use `-NoLaunch`. Updating from v1.0.x: copy the complete new repair folder contents into the same root and run the CMD once; recognized old setup blocks are upgraded with backups.

## How the repair works

The bundled `listGPUs.mexw64` and the 3D fitters (`cuda_ast_model.mexw64` / `cuda_channel_specific_model.mexw64`) depend on the specifically named **`cudart64_75.dll`** and the Microsoft VC++ 2013 x64 runtime. Other native components also need VC++ 2008/2010 x64 runtimes. A newer CUDA Toolkit does not necessarily supply these older files.

The persistent change is a short block added to `main.m`. Each time you run that script, `deployment/inspr_prepare_runtime.m` locates the project's `runtime/win64` folder and adds it to **that MATLAB process's DLL search path**. It also configures the matching toolbox and support paths. This happens automatically even when MATLAB was opened without the CMD launcher.

Closing MATLAB ends that process's temporary path setting. The block saved in `main.m` reapplies it on the next run. The repair does not change the system PATH, user `startup.m`, scientific MEX binaries, or localization algorithm. Microsoft runtimes installed during the first repair remain installed on the system.

## MATLAB versions and tested configurations

The setup block uses the currently running MATLAB and does not hard-code an R2024a installation directory. The launcher selects a detected MATLAB, generally the newer installed version. To select a specific installation, open PowerShell in your INSPR project root and run:

```powershell
.\Start-INSPR.cmd -MatlabExe "D:\MATLAB\R2024a\bin\matlab.exe"
```

Replace the example with your actual `matlab.exe` location. Validate once when changing MATLAB versions or GPU hardware.

As of 2026-10-08, both toolboxes passed GUI startup and native/GPU synthetic tests on **Windows 11, MATLAB R2024a, RTX 3060 Ti, driver 591.86**, including astigmatism-only, biplane-only and combined project layouts with spaces and Chinese characters. Direct `main.m` startup without inheriting the launcher's private PATH was also verified. Other MATLAB releases, RTX 2080 Ti, and clean Windows installations still require validation on the target machine.

Path configuration is not a guarantee that every old MEX will work with every MATLAB release or GPU architecture. [MathWorks explains](https://www.mathworks.com/help/matlab/matlab_external/version-compatibility.html) that older MEX files usually run on newer releases, but recompilation can be necessary. Synthetic tests check that the environment runs; they do not validate localization accuracy on experimental data.

## Troubleshooting

| What you see | What to check |
|---|---|
| Missing `runtime/win64/cudart64_75.dll` | Copy the complete repository contents, including `runtime` and `deployment/installers`, into the existing project root. Older releases kept these files in an inner ZIP; current releases include them directly. |
| Missing `inspr_prepare_runtime` or private CUDA DLL | Copy the entire package, including `deployment` and `runtime`; run the correct project's whole `main.m`. |
| MATLAB was not found, or the wrong release starts | Use `-MatlabExe` with the desired installation's full path. |
| An already-open MATLAB still reports a missing module | Save your results, reopen MATLAB and run the whole `main.m`, or run the diagnostic below in the existing session. |
| Invalid MEX / specified module not found | Preserve the original error and logs; another DLL, VC++ runtime, or MATLAB compatibility issue may remain. |
| Toolbox conflict / another INSPR toolbox is already loaded | Open a fresh MATLAB process for the other toolbox; save your current results first. |
| GPU enumeration works but the fit fails | Use the actual fit result. Errors such as `no kernel image` or `invalid device function` may require rebuilding the GPU code. |

Logs are saved under `deployment/logs`. Keep the run's `*_launcher.txt`, `*_matlab.txt`, `*_environment.txt`, and `*_status.txt` when asking for help.

To diagnose an already-open MATLAB session, replace the example root below with your project location:

```matlab
addpath('C:\SMLM\INSPR-master');
report = setup_inspr_cuda('Toolbox', 'biplane'); % or 'astigmatism'
```

The diagnostic reports dependencies and GPU enumeration; it does not run the full localization test or clear imported GUI data. Save results before closing the GUI.

## Restore the original startup

The original `main.m` is saved as `deployment/backups/<toolbox>_main_<unique-id>.m.bak` (older releases used `main_<unique-id>.m.bak`). If you have not edited it since installation, restore the matching backup. If you have made later edits, remove only the block between `% BEGIN INSPR PRIVATE RUNTIME v2` and `% END INSPR PRIVATE RUNTIME v2`, including those marker lines (v1 for older repairs). An upgrade backup contains the previous setup block; restoring the pre-repair state requires the earliest matching backup or removal of the block. Restoring the entry script does not uninstall shared Microsoft runtimes.

Official runtime sources and checksums are recorded in [runtime-manifest.json](deployment/runtime-manifest.json). Detailed dependency notes are available in [CUDA_SETUP.md (Chinese)](CUDA_SETUP.md).

## What the biplane GPU check covers

The biplane test calls the bundled `cuda_channel_specific_model` with the production 22-input / 5-output layout: two synthetic 16 × 16 channels, different focal planes, nonzero affine translation and segmentation offset, and seven fitted parameters (shared x/y/z, two photon counts, two backgrounds). It checks output dimensions, finite values, nonnegative CRLB/PSF values, and broad recovery bounds. It does not certify experimental calibration, registration, or localization accuracy. The optional CUDA 7.0 `GPUgaussMLE` branch and the astigmatism 2D fitter are not part of these 3D tests.
