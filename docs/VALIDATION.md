# v1.1.0 validation

Tested on 2026-10-08 with Windows 11, MATLAB R2024a, NVIDIA RTX 3060 Ti and driver 591.86. The original INSPR MEX binaries were used without recompilation.

| Check | Result |
|---|---|
| Astigmatism-only extracted repair ZIP | Passed: discovery, startup patch, GUI, segmentation, histograms, actual CUDA fit |
| Biplane-only extracted repair ZIP | Passed: discovery, startup patch, GUI, segmentation, histograms, actual two-channel CUDA fit |
| Both toolboxes in one project | Passed: separate MATLAB validation processes and separate logs |
| Paths containing spaces and Chinese characters | Passed for all three layouts |
| Direct main.m without inherited private DLL PATH | Passed for both toolboxes |
| Previously repaired v1 startup block | Upgraded with exact backup and original user code preserved |
| Repeated installation; UTF-8 BOM and legacy script bytes | Passed |
| Another toolbox's paths / already loaded functions or MEX | Unused paths removed; loaded-toolbox conflicts refused |
| Official binary hashes/signatures; corrupt DLL rejection | Passed |
| Explicit biplane GUI launcher entry | Passed |

The biplane test uses two independently generated, pixel-integrated Gaussian channels, different focal planes, affine translation and segmentation offsets. For the synthetic truth `[8, 8, 0.12, 3000, 2100, 5, 8]`, the fitted parameters were approximately `[8, 8, 0.1153, 2991.72, 2104.14, 5.032, 7.984]`. The test checks dimensions, finite values, nonnegative CRLB/PSF outputs and broad recovery bounds. These are environment checks, not a scientific accuracy benchmark.

## Reproduce in a complete INSPR project

Run PowerShell tests from the project root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests\test_install_inspr_startup.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests\test_dual_toolbox_install.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests\test_deployment.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests\test_distribution_layouts.ps1
```

The layout test needs the complete repair ZIP, original application files, a licensed MATLAB and NVIDIA GPU. It copies application/support files into temporary project directories under `deployment/cache`, runs the real launcher with `-NoInstall -NoLaunch`, and preserves logs. Existing Microsoft runtimes are required for `-NoInstall`.

In fresh, isolated MATLAB processes, add the project's `tests` folder and run `test_setup_inspr_cuda` / `test_inspr_startup` for astigmatism, `test_biplane_runtime` for biplane, and `test_inspr_preloaded_mex` for the loaded-MEX conflict check. Do not run both toolbox suites in the same MATLAB process. The legacy localization MEX resets its CUDA context.

## Boundaries

Other MATLAB releases, RTX 2080 Ti, and a clean Windows installation were not available for testing. Missing-runtime installer execution was not exercised because the local VC++ runtimes were already installed. The interactive two-toolbox selection dialog was not visually tested. Experimental datasets, calibration accuracy, optional CUDA 7.0 Gaussian initialization, and astigmatism 2D fitting are outside these 3D smoke tests.
