# INSPR 在 Windows 上的一次性环境修复

本说明针对散光和 biplane 两套 INSPR 工具箱；单独安装任一套或同时安装均可识别。
接收方可先阅读 [环境修复使用说明与原理](INSPR_Environment_Guide.md)，其中包含首次安装、日常启动、一次配置的原理、版本兼容性和常见问题。
直接使用 GitHub 仓库中的完整文件夹，不再分发内层修复 ZIP。仓库包含官方 CUDA 7.5 运行库、微软 x64 运行库安装器和自动启动程序，接收方不需要安装 Python、Visual Studio 或完整 CUDA Toolkit。

## 直接给接收方的操作

1. 将修复文件夹的**全部内容**复制到已有的 `INSPR-master` 根目录，保证 `Start-INSPR.cmd` 与已安装的 `INSPR for astigmatism-based setup` / `INSPR for biplane setup` 文件夹并列。
2. **首次**双击 **`Start-INSPR.cmd`**。如果缺少微软运行库，接受 Windows 的管理员权限提示。
3. 等待自动检测、GUI 启动和小规模 GPU 定位测试完成，程序会打开 MATLAB 和 INSPR 界面。
4. **以后正常打开 MATLAB，运行对应工具箱的 `main.m`（biplane 为 `INSPR for biplane setup/INSPR toolbox/main.m`）即可，无需再点击 CMD，也无需每次手动配置路径。**

启动器会校验所有 DLL/安装器的 SHA-256 和 NVIDIA/Microsoft 数字签名，使用项目私有 CUDA DLL，按需安装缺少的 VC++ 2008/2010/2013 x64 运行库。随后给已有的 `main.m` 添加自动配置入口，原文件按字节备份到 `deployment/backups`，重复运行不会重复插入。修改后的入口根据项目位置找到 DLL，不写死 MATLAB 安装目录，移动整个项目文件夹后也仍能定位运行库。

首次修复在独立 MATLAB 进程中先移除从启动器继承的私有 DLL 路径，再通过 `main.m` 打开隐藏的 GUI，确认入口自己配置成功，然后实际调用分割、2D/3D 直方图和该工具箱的定位 MEX：散光 `cuda_ast_model`，biplane `cuda_channel_specific_model`。两套均存在时分进程测试，全部通过后选择要打开的 GUI。测试通过才打开交互 GUI。测试数据由脚本生成，不读取或改动实验数据。

已有新版 CUDA 可以保留。自动配置通过 `main.m` 在需要时设置当前 MATLAB 的进程 PATH；不修改系统 PATH、用户 `startup.m` 或其他 MATLAB 版本的安装目录，不安装旧显卡驱动，不替换项目的计算 MEX。微软运行库安装属于系统变更，只有缺失时才执行；如安装器要求重启，会明确提示，不自动重启。

日常入口是 **`main.m`**；直接绕过它调用 `INSPR_ast_GUI` / `INSPR_GUI` 不会触发这段配置。保留项目中的 `deployment` 和 `runtime` 文件夹。恢复原入口时，可将 `deployment/backups` 中对应的原始 `*_main_*.m.bak`（旧版为 `main_*.m.bak`） 复制回 `main.m`；如果安装后又改过 `main.m`，只移除 `BEGIN/END INSPR PRIVATE RUNTIME` 之间的块以保留后续修改。

## 不同 MATLAB 版本

配置入口在当前 MATLAB 内执行，不绑定 R2024a，也不依赖 `mexcuda` 或 MATLAB 自带的 `gpuDevice` 检查。它面向 Windows 64 位 MATLAB；首次验证只验证所选的一个版本，不能将结果外推到其他版本。多个 MATLAB 默认使用注册表中较新的版本；非标准安装路径或需要指定版本时，可以运行：

```powershell
.\Start-INSPR.cmd -MatlabExe "D:\MATLAB\R2024a\bin\matlab.exe"
```

换用另一个 MATLAB 版本时，建议用上面的 `-MatlabExe` 指定该版本，做一次验证；通过后该版本也直接运行 `main.m`。每次报告记录实际 `version`、release、MATLAB 路径，以及原始失败信息。没有在本机安装的版本无法实测，所以不提供未经验证的全版本兼容承诺。

[MathWorks 的 MEX 兼容说明](https://www.mathworks.com/help/matlab/matlab_external/version-compatibility.html)说明，旧版本生成的 MEX 通常可以在新版本运行，但出错时可能需要从源代码重新编译。环境修复只能处理依赖和路径，不能自动消除所有 MEX ABI 或 MATLAB 函数差异。另外，R2025a 移除的是 GUIDE 编辑器，[已有 GUIDE 应用仍可运行](https://www.mathworks.com/help/matlab/creating_guis/gui-options.html)；这本身不等于本项目已在 R2025a 通过验证。

失败记录保存在 `deployment\logs`。本工具要求已有可用的 MATLAB 和 NVIDIA 驱动；它不能代替 MATLAB 授权，也不自动安装付费 MATLAB 工具箱。

**当前实测：**Windows 11、MATLAB R2024a、RTX 3060 Ti、驱动 591.86，原先缺少 CUDA 7.5 DLL；加入私有运行库后，完整启动器验证返回 `INSPR_RUNTIME_OK`，真实 GPU 定位 MEX 的合成数据测试通过。2080 Ti 尚未现场测试，启动器会在接收方机器上自行验证。显卡枚举成功与实验结果准确性是不同的验证层次；合成测试不替代真实数据的科学验证。

启动包中的核心文件为 `Start-INSPR.cmd`、`deployment/Start-INSPR.ps1`、`deployment/Install-INSPRStartup.ps1`、`deployment/inspr_prepare_runtime.m`、`deployment/inspr_gpu_smoketest.m`、`deployment/runtime-manifest.json` 及 `runtime/win64/cudart64_75.dll`。官方来源和原始 SHA-256 已记录在 manifest；NVIDIA 原版许可位于 `deployment/licenses`，Microsoft 原版安装器保留自身许可信息。分发目录不包含实验数据、原始 MEX、旧 CUDA 全量安装器或 7-Zip，也不分发整份 `main.m` 覆盖接收方的修改。

## 可选：在已经打开的 MATLAB 中检查

把完整项目发给对方，在 MATLAB 中进入项目根目录，然后运行：

```matlab
report = setup_inspr_cuda('Toolbox', 'biplane'); % 或 astigmatism
```

命令窗口会打印报告，并显示 UTF-8 文本报告的保存位置。把这个 `.txt` 文件发回来即可看到 MATLAB 版本、显卡和驱动、各 MEX 的 DLL 依赖，以及 `listGPUs` 的原始报错。报告含软件安装路径和本机路径。

如果 CUDA 7.5 的 `bin` 目录已存在，脚本会尝试找到并加入当前 MATLAB 进程的 `PATH`。非默认安装位置可手动指定：

```matlab
report = setup_inspr_cuda('Toolbox', 'biplane', 'RuntimeDirectory', 'D:\CUDA\v7.5\bin');
```

仓库中的 `runtime/win64` 已直接提供**从官方软件包提取并校验签名**的 `runtime\win64\cudart64_75.dll`。诊断函数本身不下载安装运行库。不要把新版 DLL 重命名成旧版文件名。

配置后在同一个 MATLAB 会话中启动：

```matlab
cd(report.toolboxDirectory);
main
```

`setup_inspr_cuda` 诊断函数本身只修改当前会话的 MATLAB 搜索路径和进程 `PATH`，不修改系统环境变量、不调用 `savepath`、不安装或替换驱动，也不覆盖 MEX。完成新版修复包的一次性安装后，重新打开 MATLAB 时直接运行 `main.m`，它会自动完成运行库路径配置，无需重跑诊断函数。

只检查文件和环境、不调用 GPU 枚举 MEX：

```matlab
report = setup_inspr_cuda('Toolbox', 'biplane', 'TestGPU', false);
```

## 为什么安装最新 CUDA 仍会弹窗

原 GUI 的 3D 定位回调调用 `listGPUs`，并把所有异常统一显示为“Please install CUDA environment”。这既可能是路径问题，也可能是旧运行库、VC++ 运行库、MEX 兼容性等问题。原始 GUI 可能仍显示泛化提示；修复启动器会在日志中保留实际 MEX 错误。

本次直接读取仓库中 Windows PE 导入表得到：

| 文件/用途 | 直接运行库依赖 |
|---|---|
| `listGPUs.mexw64`：GPU 检查 | `cudart64_75.dll`、`MSVCR120.dll` |
| `cuda_ast_model.mexw64`：3D GPU 定位 | `cudart64_75.dll`、`MSVCR120.dll` |
| `cuda_channel_specific_model.mexw64`：biplane 3D GPU 定位 | `cudart64_75.dll`、`MSVCR120.dll` |
| `SRsCMOS_MLE.mexw64`：2D GPU 定位 | `cudart64_75.dll`、`MSVCR120.dll` |
| `GPUgaussMLE.mexw64`：可选初值估计 | `cudart64_70.dll`、`MSVCR120.dll` |
| `cMakeSubregions.mexw64`：分割 | `MSVCR90.dll` |
| `cHistRecon3D.mexw64`：三维直方图 | `MSVCR100.dll` |
| `cHistRecon.mexw64`：二维直方图 | `MSVCR120.dll` |

`MSVCR90/100/120` 分别对应 VC++ 2008/2010/2013；这里需要 x64 运行库。较新的 VC++ 运行库不能代替这些旧版本。表中省略 Windows 和 MATLAB 自身的 DLL，完整列表见脚本报告。

标准 3D 分支调用 `genIniguess(data,'median')`，不会进入需要 `GPUgaussMLE` 的额外参数分支，因此不要看到 CUDA 7.0 的可选依赖就把它当成当前 3D 弹窗的原因。

新版 CUDA Toolkit 不包含所有旧版命名的运行库；驱动向后兼容也不等于自动提供这些 DLL。[NVIDIA 兼容性说明](https://docs.nvidia.com/deploy/cuda-compatibility/why-cuda-compatibility.html)明确区分驱动与动态库要求。`nvidia-smi` 的 CUDA Version 表示驱动支持的 CUDA 版本，不能证明对应 Toolkit 已安装。`nvcc` 缺失也不等于预编译 MEX 不能运行。

## 如何处理报告

1. **找得到 CUDA 7.5 DLL，但原来不在路径中：**脚本加入当前会话路径后重试 `listGPUs`，再在 GUI 中用小数据集验证 3D 定位。
2. **找不到 `cudart64_75.dll`：**路径修改无法制造缺失的运行库。短期可评估来自 [NVIDIA CUDA 7.5 官方归档](https://developer.nvidia.com/cuda-75-downloads-archive)的匹配运行库。Win11 上运行这套旧二进制仍需实际验证，不保证旧版完整安装器可用，也不应随旧工具包安装旧显卡驱动。
3. **缺少旧 VC++ 库：**根据报告中的确切版本安装 [Microsoft 官方运行库](https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist)。VC++ 2008 使用的 SxS 机制不在脚本的目录扫描范围内；“未在扫描目录找到”不等于它一定未安装。
4. **`listGPUs` 成功，但定位提示 `no kernel image` 或 `invalid device function`：**需要检查/重编译 GPU 内核，继续修改 PATH 无效。
5. **DLL 看起来都存在，MEX 仍加载失败：**把完整错误报告发回来。目录扫描不验证 DLL 的所有间接依赖、已加载模块冲突、Windows SxS、MATLAB ABI 或运行库身份。[MathWorks 的 MEX 错误说明](https://www.mathworks.com/help/matlab/matlab_external/invalid-mex-file-error.html)列出了这些依赖与版本问题。

接收方显卡已知为 RTX 2080 Ti；MATLAB 版本尚未确认。仓库的旧 Visual Studio 工程指定 CUDA 7.5、v120 工具链以及 `compute_52,sm_52`。进一步用 NVIDIA cuobjdump 12.4.127 检查实际 `cuda_ast_model.mexw64`，确认含 5 组 sm_52 cubin 和 PTX。根据 [NVIDIA Turing 兼容性指南](https://docs.nvidia.com/cuda/turing-compatibility-guide/index.html)，CUDA 8.0 及以前的程序可通过适用 PTX 在 Turing 上执行；启动器还会实际跑内核验证。

## 推荐的长期部署方式

本次已经实现现有 MEX + 匹配运行库 + 自动启动的部署包。后续若需要支持发生变化的 MATLAB ABI 或 GPU 架构，可以在开发机上统一重编译 MEX，再按同样方式交付。接收方主要运行预编译程序，通常无需安装完整 CUDA 开发工具链。

仓库保留了 `cuda_ast_model` 的 C++/CUDA 源码，具备重建基础；但 `listGPUs` 和多个辅助 MEX 的对应源码未在本次检索中找到，不能宣称已经具备“一键重编译全部组件”的条件。现代化构建仍需工具链适配，以及 CPU/GPU 小数据集数值验证。本次没有重编译或替换任何 MEX。

## 项目与故障所在的调用链

- `INSPR for astigmatism-based setup`：本次使用的散光 INSPR GUI；`main.m` 设置支持路径并打开 `INSPR_ast_GUI.m`。
- `INSPR for biplane setup`：独立双平面工作流及其支持代码。
- `Mex function for 3D localization`：散光/双平面定位的旧 Visual Studio、C++、CUDA 工程和编译产物。
- `PR-code-for-beads`：珠子 z-stack 相位恢复工具、GUI、示例数据与独立依赖。

散光工作流为：数据导入 → 分割 → `INSPR_model_generation_ast` 反复分类/配准/相位恢复 → 全局 `data_empupil.probj` 保存拟合 pupil → `analysis3D_fromPupil_ast` → GPU `loc_ast_model` / CPU `loc_ast_model_CPU` → 筛选、漂移校正、重建与导出。

本次弹窗发生在进入实际 GPU 定位之前的 `listGPUs` 检查。3D 定位已有 CPU 分支，可取消勾选 **Run GPU** 临时尝试；CPU 流程仍有 MATLAB 工具箱与分割/重建 MEX 依赖，不能视为完全无二进制依赖。2D 定位目前只有 GPU 分支。

## 验证范围

诊断脚本检测的 `ENUMERATION_RETURNED` 只表示枚举函数正常返回，仍需检查输出中的设备情况。它不会宣称定位已经通过，也不会以 MATLAB 的 `gpuDevice` 代替 INSPR 自己的 MEX 测试。

不要用无参数 `cuda_ast_model()` 或 `cuda_channel_specific_model()` 测试加载：该旧源码在检查参数数量前就访问输入指针，可能导致 MATLAB 崩溃。

开发者可在项目根目录运行：

```matlab
addpath('tests');
test_setup_inspr_cuda
```

测试覆盖依赖解析、目录无关运行、重复运行、错误保留和验证边界；真实 2080 Ti 的完整定位仍需在接收方电脑上测试。

## 双工具箱隔离与验证

`-Toolbox auto`（默认）识别两条 `main.m` 路径，对每套分别备份配置并启动独立 MATLAB 自检。`-Toolbox biplane` / `-Toolbox astigmatism` 可限定目标，`-MatlabExe` 选择实际 MATLAB 安装。每套日志文件名均含其名称；某套失败时会继续检查另一套，最终返回失败且不自动打开 GUI。

`inspr_toolbox_profile` 解析所选目录；`inspr_configure_paths` 配置对应代码路径并移除另一套的路径。如果另一套已在会话中加载，则要求新开 MATLAB，不清空用户数据来强行切换。直接运行各自 `main.m` 时配置自动生效；默认诊断在项目根目录且两套都存在时要求明确给出 Toolbox，避免默认猜错。

biplane 自检使用原生产调用的 22 输入、5 输出、双 16×16 通道和 7 参数布局，包括非零配准平移和分割偏移；实际调用两个通道拟合并检查数值输出。自检不会处理实验数据，也不认证实验精度。

开发验证还包括 `tests/test_dual_toolbox_install.ps1`（单 biplane、双入口、v1 升级、备份和重复运行）、`tests/test_biplane_runtime.m`（在独立 MATLAB 中执行），以及 `tests/test_distribution_layouts.ps1`（从完整分发文件夹复制测试三种安装布局，需要 GPU）。
