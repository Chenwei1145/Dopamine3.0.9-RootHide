# RootHide Detector

独立的 SwiftUI 越狱可见性检测器，用于评估 RootHide 对普通 App 的隐藏效果。它只读取文件、环境变量和当前进程加载镜像，不会修改系统文件，也不会执行越狱操作。

## WSL / Theos 编译

本项目按 iPhone Theos 目标构建，并在 WSL 的 Linux 文件系统中临时编译，避免 `/mnt/c` 的权限、时间戳和 `ldid` 问题：

```bash
cd /mnt/c/Users/39437/Documents/Codex/TheosProjects/Dopamine/gitdioamine
export THEOS=$HOME/theos
./build_jailbreak_detector.sh
```

如果出现 `libxml2.so.2: cannot open shared object file`，安装 Swift 工具链依赖后重试：

```bash
sudo apt update
sudo apt install -y libxml2
```

产物位于 `JailbreakDetector/output/`，包括 `.ipa` 和 `.deb`。Theos 会使用 `ldid` 进行 ad-hoc 签名；如需安装到设备，可通过 Sileo、TrollStore 或你现有的签名流程安装。

## 结果解释

评分越高表示当前进程能直接看到的 RootHide 痕迹越多。RootHide 可能隐藏 `/var/jb`、动态库和环境变量，因此 **0 分不等于设备未越狱**。该工具只用于测试和研究，不能替代系统安全检测。
