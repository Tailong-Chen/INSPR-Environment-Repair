# INSPR Windows CUDA Environment Repair

Repair missing runtime dependencies for an **existing INSPR astigmatism toolbox project** on 64-bit Windows. Run the repair once; afterwards, open MATLAB normally and run the project's `main.m`.

**[Download the complete repair ZIP](https://github.com/Tailong-Chen/INSPR-Environment-Repair/releases/latest/download/INSPR_Environment_Repair.zip)** · **[English illustrated guide](INSPR_Environment_Guide_EN.md)** · **[中文说明](INSPR_Environment_Guide.md)**

You need the complete INSPR application, a working 64-bit Windows MATLAB installation, and an NVIDIA GPU driver. This repository provides the repair package, not the full INSPR application.

## 1. Download and copy to the right folder

Download **`INSPR_Environment_Repair.zip`** using the link above. In Windows File Explorer:

1. Extract the ZIP, then open the extracted folder.
2. Select **everything inside** (`Ctrl+A`) and copy it (`Ctrl+C`).
3. Open your **existing INSPR project root**: the folder that already contains `INSPR for astigmatism-based setup`.
4. Paste the repair contents there (`Ctrl+V`). Merge folders and update the repair files if you are replacing an older package.

![Copy every repair file into the existing project root. Start-INSPR.cmd and the INSPR setup folder must be at the same level; avoid an extra wrapper folder.](docs/images/extract-to-project.png)

**Check before continuing:** `Start-INSPR.cmd` must be **beside** `INSPR for astigmatism-based setup`, with the same parent folder. It should not be inside an extra `INSPR_Environment_Repair` folder or inside the toolbox folder.

The illustrated path `C:\SMLM\INSPR-master` is only an example. Use your own project location.

## 2. Run the repair once

Double-click **`Start-INSPR.cmd` in the existing project root**. Allow the official Microsoft installer permission prompt if a required runtime is missing. Wait for the environment checks and the real GPU localization test to pass; the launcher then opens INSPR.

The ZIP includes the matching CUDA DLL and Microsoft runtime installers. You do not need to install the complete CUDA Toolkit, Visual Studio, or Python. SHA-256 values are listed in [SHA256SUMS.txt](SHA256SUMS.txt).

## 3. Afterwards, run main.m in MATLAB

Open the file shown below in the MATLAB Editor and click **Run**. Alternatively, set MATLAB's **Current Folder** to `INSPR astigmatism toolbox` and enter `main`.

![Inside your existing project, open INSPR for astigmatism-based setup, then INSPR astigmatism toolbox, then run the entire main.m script in MATLAB.](docs/images/run-main-in-matlab.png)

Run the **whole `main.m` script** so its automatic path setup executes. You do not need to click the CMD again for everyday use. Keep the `deployment` and `runtime` folders with your project.

## If you downloaded the whole GitHub repository

GitHub's **Code → Download ZIP** and **Source code** archives contain this repository. Extract that archive, find **`INSPR_Environment_Repair.zip` inside it**, and follow step 1 above using this inner repair ZIP. The folder `INSPR-Environment-Repair-main` is not your existing INSPR application folder.

You can also [download the repair ZIP stored in the repository](https://github.com/Tailong-Chen/INSPR-Environment-Repair/raw/refs/heads/main/INSPR_Environment_Repair.zip).

## Compatibility and troubleshooting

The setup does not hard-code a MATLAB installation path. To select a particular MATLAB version, run this in PowerShell from your INSPR project root, replacing the example path:

```powershell
.\Start-INSPR.cmd -MatlabExe "D:\MATLAB\R2024a\bin\matlab.exe"
```

Verified on **Windows 11 / MATLAB R2024a / RTX 3060 Ti / driver 591.86**, including paths with spaces and Chinese characters and direct `main.m` startup without the launcher's PATH. Other MATLAB versions, RTX 2080 Ti, and clean Windows installations require validation on the target machine. The synthetic test checks execution, not experimental localization accuracy.

If setup fails, keep that run's files from `deployment/logs` and see the [illustrated guide's troubleshooting section](INSPR_Environment_Guide_EN.md#troubleshooting). The tool does not install MATLAB, paid MATLAB toolboxes, or a graphics driver; MEX/GPU compatibility problems can still require recompilation.

## How it works and where the files come from

The project's old MEX files require `cudart64_75.dll` and legacy Microsoft VC++ runtimes. The repair verifies the official packages, installs missing runtimes, backs up `main.m`, and adds an automatic setup block. Each run of `main.m` adds the project's private DLL directory to that MATLAB process's PATH. The system PATH and scientific MEX binaries remain unchanged.

- [English user guide](INSPR_Environment_Guide_EN.md) · [中文使用说明](INSPR_Environment_Guide.md) · [Detailed dependency notes (Chinese)](CUDA_SETUP.md)
- [Official sources and runtime checksums](deployment/runtime-manifest.json) · [NVIDIA CUDA 7.5 license](deployment/licenses/NVIDIA-CUDA-7.5-EULA.txt). Microsoft installers retain their included licenses.
- Repair/diagnostic source is in `deployment/`, `setup_inspr_cuda.m`, and `tests/`. Run development tests in a complete INSPR project. The ready-to-use DLLs and installers are bundled in the repair ZIP.
- The folder illustrations can be regenerated with `docs/render_quickstart.py` and Pillow; Python is not required by recipients.
