# RootHide Detector

独立的 SwiftUI 越狱可见性检测器，用于评估 RootHide 对普通 App 的隐藏效果。它只读取文件、环境变量和当前进程加载镜像，不会修改系统文件，也不会执行越狱操作。

## 编译说明

SwiftUI 应用必须使用 macOS + Xcode 的 iOS SDK 构建。Theos 的 `application.mk` 在 Linux/WSL
上不支持 iOS 应用目标，所以在 WSL 执行脚本会明确提示并退出；这不是项目源码错误。

在 macOS（已安装 Theos 和 Xcode）上可执行：

```bash
cd /mnt/c/Users/39437/Documents/Codex/TheosProjects/Dopamine/gitdioamine
export THEOS=$HOME/theos
./build_jailbreak_detector.sh
```

产物位于 `JailbreakDetector/packages/`。Theos 会使用 `ldid` 进行 ad-hoc 签名；如需安装到设备，可通过 Sileo、TrollStore 或你现有的签名流程安装。

如果只有 WSL，可将界面改为 UIKit/Objective-C 后再使用 Linux Theos 编译；SwiftUI 不能通过当前 WSL Theos 工具链直接编译。

## 结果解释

评分越高表示当前进程能直接看到的 RootHide 痕迹越多。RootHide 可能隐藏 `/var/jb`、动态库和环境变量，因此 **0 分不等于设备未越狱**。该工具只用于测试和研究，不能替代系统安全检测。
