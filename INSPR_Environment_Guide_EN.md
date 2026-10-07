# INSPR environment repair: illustrated user guide

Updated: 2026-10-08. Applies to the **INSPR astigmatism toolbox on 64-bit Windows**.

[Download the complete repair ZIP](https://github.com/Tailong-Chen/INSPR-Environment-Repair/releases/latest/download/INSPR_Environment_Repair.zip) · [GitHub repository](https://github.com/Tailong-Chen/INSPR-Environment-Repair) · [中文说明](INSPR_Environment_Guide.md)

**Run the repair once. Afterwards, open MATLAB normally and run the project's entire `main.m` script.**

## Before you start

You need an existing, complete INSPR astigmatism project, a working installation of 64-bit Windows MATLAB, and the NVIDIA driver for your GPU. This download supplies runtime dependencies and setup scripts; it does not include the full INSPR application, MATLAB, paid MATLAB toolboxes, or a graphics driver.

The images below are folder-layout illustrations. `C:\SMLM\INSPR-master` is an **example location**, not a required path. Use the folder where your own INSPR project is stored.

## 1. Download the right file

Download **`INSPR_Environment_Repair.zip`** using the link above or the named asset on the GitHub Releases page.

If you use GitHub's **Code → Download ZIP**, first extract that repository archive, then find `INSPR_Environment_Repair.zip` inside it. Continue with the inner repair ZIP. GitHub's automatically generated **Source code** archives are also repository snapshots, not the ready-to-use repair payload.

## 2. Copy the files to your existing INSPR project

1. In Windows File Explorer, extract `INSPR_Environment_Repair.zip` to a temporary folder, such as Downloads.
2. Open that extracted folder. You should see `Start-INSPR.cmd`, `deployment`, `runtime`, and other files directly inside it.
3. Select **all its contents** (`Ctrl+A`), then copy them (`Ctrl+C`).
4. Open your **existing INSPR project root**: the folder that already contains `INSPR for astigmatism-based setup`.
5. Paste the copied contents there (`Ctrl+V`). When updating an earlier repair package, merge the folders and replace the repair files with the new copies.

![Copy all repair contents into the existing project root; Start-INSPR.cmd must be beside the INSPR setup folder.](docs/images/extract-to-project.png)

The key check is that these two items have the **same parent folder**:

```text
Your existing INSPR project root
├─ INSPR for astigmatism-based setup    ← already present
├─ Start-INSPR.cmd                     ← copied from the repair ZIP
├─ deployment/
├─ runtime/
├─ docs/
└─ other repair scripts and guides
```

If the launcher is instead inside `INSPR-master\INSPR_Environment_Repair\`, an extra folder layer has been introduced. Move the repair folder's **contents** up into the existing project root. Do not put the repair files inside `INSPR for astigmatism-based setup` or inside the toolbox subfolder either.

The publicly downloaded repository folder, often named `INSPR-Environment-Repair-main`, is not your existing INSPR application folder.

## 3. Run the repair once

Double-click **`Start-INSPR.cmd` in the existing project root**. If Windows hides known filename extensions, it may be displayed as `Start-INSPR`.

The launcher verifies the bundled NVIDIA DLL and Microsoft installers, checks the GPU driver, installs missing VC++ x64 runtimes when needed, and adds an automatic setup block to your existing `main.m`. Allow the official Microsoft installer permission prompt if a required runtime is missing. The original `main.m` is backed up under `deployment/backups`.

It then starts a separate MATLAB process and checks GUI startup, segmentation, reconstruction, and a small synthetic 3D GPU fit. Successful validation ends with:

```text
PASS: the actual INSPR GPU localization MEX ran successfully.
One-time setup complete. In future, open MATLAB normally and run the project main.m.
```

The launcher opens INSPR after validation. If a Microsoft installer explicitly requests a Windows restart, restart and run the launcher again. You do not need to install Python, Visual Studio, or the complete CUDA 7.5 Toolkit for this package.

## 4. Everyday use: run main.m in MATLAB

After setup has passed, open MATLAB normally. Navigate inside your existing project as shown below:

![Navigate from the existing project root through the astigmatism setup and toolbox folders, then run the entire main.m file in MATLAB.](docs/images/run-main-in-matlab.png)

The entry file, relative to your project root, is:

```text
INSPR for astigmatism-based setup/
└─ INSPR astigmatism toolbox/
   └─ main.m
```

Open that file in the MATLAB Editor and click **Run**, or set MATLAB's **Current Folder** to `INSPR astigmatism toolbox` and enter:

```matlab
main
```

Run the **whole script**. Calling `INSPR_ast_GUI` directly or running only the final section of `main.m` can skip the automatic setup. Keep `deployment` and `runtime` with the project. When relocating it, move the entire project folder.

## How the repair works

The bundled `listGPUs.mexw64` and `cuda_ast_model.mexw64` depend on the specifically named **`cudart64_75.dll`** and the Microsoft VC++ 2013 x64 runtime. Other native components also need VC++ 2008/2010 x64 runtimes. A newer CUDA Toolkit does not necessarily supply these older files.

The persistent change is a short block added to `main.m`. Each time you run that script, `deployment/inspr_prepare_runtime.m` locates the project's `runtime/win64` folder and adds it to **that MATLAB process's DLL search path**. This happens automatically even when MATLAB was opened without the CMD launcher.

Closing MATLAB ends that process's temporary path setting. The block saved in `main.m` reapplies it on the next run. The repair does not change the system PATH, user `startup.m`, scientific MEX binaries, or localization algorithm. Microsoft runtimes installed during the first repair remain installed on the system.

## MATLAB versions and tested configurations

The setup block uses the currently running MATLAB and does not hard-code an R2024a installation directory. The launcher selects a detected MATLAB, generally the newer installed version. To select a specific installation, open PowerShell in your INSPR project root and run:

```powershell
.\Start-INSPR.cmd -MatlabExe "D:\MATLAB\R2024a\bin\matlab.exe"
```

Replace the example with your actual `matlab.exe` location. Validate once when changing MATLAB versions or GPU hardware.

As of 2026-10-08, GUI startup and the native/GPU synthetic tests passed on **Windows 11, MATLAB R2024a, RTX 3060 Ti, driver 591.86**, including paths containing spaces and Chinese characters. Direct `main.m` startup without inheriting the launcher's private PATH was also verified. Other MATLAB releases, RTX 2080 Ti, and clean Windows installations still require validation on the target machine.

Path configuration is not a guarantee that every old MEX will work with every MATLAB release or GPU architecture. [MathWorks explains](https://www.mathworks.com/help/matlab/matlab_external/version-compatibility.html) that older MEX files usually run on newer releases, but recompilation can be necessary. Synthetic tests check that the environment runs; they do not validate localization accuracy on experimental data.

## Troubleshooting

| What you see | What to check |
|---|---|
| A message asking you to extract into the project root | Compare the first illustration with your folders. `Start-INSPR.cmd` must be beside `INSPR for astigmatism-based setup`. |
| Missing `inspr_prepare_runtime` or private CUDA DLL | Copy the entire package, including `deployment` and `runtime`; run the correct project's whole `main.m`. |
| MATLAB was not found, or the wrong release starts | Use `-MatlabExe` with the desired installation's full path. |
| An already-open MATLAB still reports a missing module | Save your results, reopen MATLAB and run the whole `main.m`, or run the diagnostic below in the existing session. |
| Invalid MEX / specified module not found | Preserve the original error and logs; another DLL, VC++ runtime, or MATLAB compatibility issue may remain. |
| GPU enumeration works but the fit fails | Use the actual fit result. Errors such as `no kernel image` or `invalid device function` may require rebuilding the GPU code. |

Logs are saved under `deployment/logs`. Keep the run's `*_launcher.txt`, `*_matlab.txt`, `*_environment.txt`, and `*_status.txt` when asking for help.

To diagnose an already-open MATLAB session, replace the example root below with your project location:

```matlab
addpath('C:\SMLM\INSPR-master');
report = setup_inspr_cuda;
```

The diagnostic reports dependencies and GPU enumeration; it does not run the full localization test or clear imported GUI data. Save results before closing the GUI.

## Restore the original startup

The original `main.m` is saved as `deployment/backups/main_<unique-id>.m.bak`. If you have not edited it since installation, restore the matching backup. If you have made later edits, remove only the block between `% BEGIN INSPR PRIVATE RUNTIME v1` and `% END INSPR PRIVATE RUNTIME v1`, including those marker lines. Restoring the entry script does not uninstall shared Microsoft runtimes.

Official runtime sources and checksums are recorded in [runtime-manifest.json](deployment/runtime-manifest.json). Detailed dependency notes are available in [CUDA_SETUP.md (Chinese)](CUDA_SETUP.md).
