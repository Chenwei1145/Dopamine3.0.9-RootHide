import SwiftUI
import UIKit
import Foundation
import Darwin

struct Detection: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let detected: Bool
    let weight: Int
}

@MainActor
final class Detector: ObservableObject {
    @Published var checks: [Detection] = []
    @Published var lastScan = Date()

    var score: Int {
        let total = checks.reduce(0) { $0 + $1.weight }
        guard total > 0 else { return 0 }
        return Int((Double(checks.filter(\.detected).reduce(0) { $0 + $1.weight }) / Double(total) * 100).rounded())
    }

    var verdict: String {
        switch score {
        case 70...: return "高度疑似 RootHide / 越狱环境"
        case 30...: return "发现部分越狱迹象"
        default: return "未发现可见的越狱迹象"
        }
    }

    func scan() {
        var result: [Detection] = []
        result.append(checkPath("RootHide jbroot 目录", paths: ["/var/jb", "/var/jb/basebin", "/var/jb/usr/bin/jbctl"], weight: 30))
        result.append(checkPath("RootHide 配置/版本文件", paths: ["/var/jb/basebin/.version", "/var/jb/.jbroot"], weight: 15))
        result.append(checkPath("RootHide 注入组件", paths: ["/var/jb/usr/lib/TweakInject/ElleKit.dylib", "/var/jb/usr/lib/libjailbreak.dylib"], weight: 20))
        result.append(checkLoadedImage(weight: 15))
        result.append(checkEnvironment(weight: 10))
        result.append(checkWritableJailbreakPath(weight: 10))
        checks = result
        lastScan = Date()
    }

    private func checkPath(_ title: String, paths: [String], weight: Int) -> Detection {
        let hit = paths.first { FileManager.default.fileExists(atPath: $0) }
        return Detection(title: title, detail: hit ?? "未找到相关路径", detected: hit != nil, weight: weight)
    }

    private func checkLoadedImage(weight: Int) -> Detection {
        let names = ["/usr/lib/libjailbreak.dylib", "/var/jb/usr/lib/libjailbreak.dylib", "/var/jb/usr/lib/TweakInject/ElleKit.dylib"]
        let hit = names.first { dlopen($0, RTLD_NOLOAD | RTLD_LAZY) != nil }
        return Detection(title: "当前进程已加载 RootHide 库", detail: hit ?? "未检测到已加载库", detected: hit != nil, weight: weight)
    }

    private func checkEnvironment(weight: Int) -> Detection {
        let keys = ["DYLD_INSERT_LIBRARIES", "_MSSafeMode", "ROOT_HIDE", "JBROOT"]
        let hit = keys.first { getenv($0) != nil }
        return Detection(title: "越狱相关环境变量", detail: hit ?? "未发现相关变量", detected: hit != nil, weight: weight)
    }

    private func checkWritableJailbreakPath(weight: Int) -> Detection {
        // 仅检查属性，不创建、修改或删除任何文件。
        let path = "/var/jb"
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        let readable = exists && FileManager.default.isReadableFile(atPath: path)
        return Detection(title: "RootHide 路径可访问性", detail: readable ? "可读取 \(path)" : "路径不可读取或不存在", detected: readable, weight: weight)
    }
}

struct ContentView: View {
    @StateObject private var detector = Detector()

    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(spacing: 8) {
                        Text("RootHide Detector").font(.title2.bold())
                        Text(detector.verdict).font(.headline)
                        Text("检测评分 (detector.score)/100").foregroundStyle(detector.score >= 30 ? .orange : .secondary)
                        ProgressView(value: Double(detector.score), total: 100)
                    }.frame(maxWidth: .infinity).padding(.vertical, 8)
                }
                Section("检测项目") {
                    ForEach(detector.checks) { item in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: item.detected ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                                .foregroundStyle(item.detected ? .orange : .green)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.title).font(.body.bold())
                                Text(item.detail).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
                Section {
                    Button { detector.scan() } label: { Label("重新扫描", systemImage: "arrow.clockwise") }
                    Text("上次扫描：\(detector.lastScan.formatted(date: .omitted, time: .shortened))")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("说明") {
                    Text("RootHide 的设计目标就是隐藏越狱痕迹。普通 App 受沙盒限制时，检测结果可能为阴性；本工具只能评估当前进程可见的迹象，不能证明设备绝对未越狱。")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("越狱检测")
        }
        .task { detector.scan() }
    }
}

@main
struct JailbreakDetectorApp: App {
    var body: some Scene { WindowGroup { ContentView() } }
}
