# INSPR Windows CUDA 环境修复包

为已有的 **INSPR 散光定位工具箱**补齐旧版运行库，并配置自动加载路径。首次运行修复程序后，日常直接在 MATLAB 中运行项目的 `main.m`。

**[下载完整修复包 ZIP](https://github.com/Tailong-Chen/INSPR-Environment-Repair/releases/latest/download/INSPR_Environment_Repair.zip)** · **[中文使用说明与原理](INSPR_Environment_Guide.md)** · **[发布版本](https://github.com/Tailong-Chen/INSPR-Environment-Repair/releases)**

## 下载后怎样使用

1. 下载上面的 `INSPR_Environment_Repair.zip`，将**全部内容**解压到已有的 `INSPR-master` 根目录，使 `Start-INSPR.cmd` 与 `INSPR for astigmatism-based setup` 文件夹并列。
2. **首次**双击 `Start-INSPR.cmd`。如缺少微软运行库，允许官方安装器的管理员权限提示。等待环境检查和真实 GPU 定位测试通过。
3. 以后正常打开 MATLAB，运行 `INSPR for astigmatism-based setup/INSPR astigmatism toolbox/main.m`，无需再次点击 CMD。

若通过 GitHub 的 **Code → Download ZIP** 下载整个仓库，请先解压仓库，再把其中的 `INSPR_Environment_Repair.zip` 解压到已有的 INSPR 项目中。也可[直接下载仓库内的修复 ZIP](https://github.com/Tailong-Chen/INSPR-Environment-Repair/raw/refs/heads/main/INSPR_Environment_Repair.zip)。

修复包约 22.6 MB，已包含匹配的 CUDA DLL 和微软运行库安装器。接收方无需另行下载 CUDA 7.5 Toolkit、Visual Studio 或 Python。文件校验值见 [SHA256SUMS.txt](SHA256SUMS.txt)。

## 使用前提

- 已有完整的 INSPR 散光项目；本仓库是环境修复工具，不包含完整 INSPR 程序或实验数据。
- 已安装可正常启动、授权可用的 Windows 64 位 MATLAB，以及适合本机 NVIDIA 显卡的驱动。
- 缺少 VC++ 运行库时，需要允许安装这些系统组件。修复工具不安装 MATLAB、付费 MATLAB 工具箱或显卡驱动。

## 它修复什么

项目的旧 MEX 程序明确依赖 `cudart64_75.dll`。安装新版 CUDA 不代表同时具备这个旧版 DLL，因此仍可能报“Please install CUDA environment”或“无效 MEX 文件：找不到指定的模块”。

修复工具校验官方 DLL/安装器的散列值和发布者签名，按需安装 VC++ 2008/2010/2013 x64 运行库，并给原 `main.m` 加入自动配置入口。原文件备份在 `deployment/backups`。以后运行 `main.m`，会自动把项目的 `runtime/win64` 加入当前 MATLAB 进程的 DLL 搜索路径；不修改系统 PATH，也不替换定位算法或 MEX。

## MATLAB 版本和验证范围

配置不绑定某个 MATLAB 安装目录。多个 MATLAB 默认选择较新的版本，也可以在 INSPR 项目根目录的 PowerShell 中指定：

```powershell
.\Start-INSPR.cmd -MatlabExe "D:\MATLAB\R2024a\bin\matlab.exe"
```

首次修复会在所选 MATLAB 中实际测试 GUI、分割、重建和三维 GPU 定位，日志保存在 `deployment/logs`。

截至 2026-10-08，已在 **Windows 11 / MATLAB R2024a / RTX 3060 Ti / 驱动 591.86** 验证通过，也测试了中文和空格路径，以及不继承启动器 PATH 时直接运行 `main.m`。其他 MATLAB 版本、RTX 2080 Ti 和全新系统安装场景仍需现场验证。合成数据自检验证环境可运行，不替代实验数据的定位精度验证。

如果自检失败，保留该次 `*_launcher.txt`、`*_matlab.txt`、`*_environment.txt` 和 `*_status.txt`，按[中文说明的故障处理部分](INSPR_Environment_Guide.md#6-常见问题与处理)排查。旧 MEX 的 ABI 或 GPU 内核兼容问题可能需要重新编译，不能仅靠修改路径解决。

## 文件与来源

- [INSPR_Environment_Guide.md](INSPR_Environment_Guide.md)：首次安装、日常启动、原理、兼容性和恢复方法。
- [CUDA_SETUP.md](CUDA_SETUP.md)：MEX 依赖及详细诊断说明。
- `deployment/`、`setup_inspr_cuda.m`、`tests/`：修复、诊断和验证源代码。
- [runtime-manifest.json](deployment/runtime-manifest.json)：NVIDIA / Microsoft 官方来源和 SHA-256。
- [NVIDIA CUDA 7.5 原版许可](deployment/licenses/NVIDIA-CUDA-7.5-EULA.txt)；Microsoft 安装器保留其内置许可。第三方二进制适用各自许可。

维护者需在完整 INSPR 开发目录中使用这些脚本和测试；源码仓库不单独展开存储 DLL/安装器，它们包含在发布 ZIP 中。修改后用 `deployment/Build-RepairPackage.ps1` 重新打包，并在发布前运行实际 MATLAB/GPU 验证。
