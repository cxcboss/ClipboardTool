# ClipboardTool

一个 macOS 剪贴板管理工具，帮助你管理和快速粘贴剪贴板历史记录。

## 功能特性

- 📋 **剪贴板历史记录** - 自动记录所有复制的文本内容
- ⌨️ **全局热键** - 使用 `Ctrl+V` 快速唤出剪贴板窗口
- 🔒 **隐私保护** - 本地存储，不上传任何数据
- 🚀 **开机自启动** - 支持开机自动运行
- ⚙️ **自定义设置** - 可自定义热键

## 安装方法

### 方法一：从源码编译

```bash
# 克隆项目
git clone https://github.com/cxcboss/ClipboardTool.git
cd ClipboardTool

# 编译项目
xcodebuild -project ClipboardTool.xcodeproj -scheme ClipboardTool -configuration Debug build
```

### 方法二：使用 Homebrew

```bash
# 后续将支持 Homebrew 安装
brew install clipboardtool
```

## 使用说明

### 唤出剪贴板窗口

1. 按下 **Ctrl+V** 全局热键唤出剪贴板窗口
2. 或点击菜单栏图标选择"显示剪贴板窗口"

### 粘贴剪贴板内容

1. 在剪贴板窗口中点击任意条目
2. 内容将自动输入到当前光标位置

### 设置

1. 点击菜单栏图标
2. 选择"快捷键设置..."
3. 自定义热键组合

## 权限说明

首次使用需要授予**输入监控**与**辅助功能权限**，用于：

- 全局键盘监听（热键检测）
- 模拟键盘输入（自动粘贴）

请在 `系统设置 > 隐私与安全性 > 输入监控` 和 `系统设置 > 隐私与安全性 > 辅助功能` 中勾选 ClipboardTool。

## 项目结构

```
ClipboardTool/
├── Sources/
│   ├── App/
│   │   ├── AppDelegate.swift      # 应用入口
│   │   ├── ClipboardApp.swift     # SwiftUI 应用配置
│   │   └── FloatingWindowController.swift  # 浮动窗口控制器
│   ├── Models/
│   │   ├── ClipboardItem.swift    # 剪贴板数据模型
│   │   └── HotkeySettings.swift   # 热键配置模型
│   ├── Services/
│   │   ├── ClipboardManager.swift  # 剪贴板管理服务
│   │   └── HotkeyManager.swift    # 热键管理服务
│   └── Views/
│       ├── AboutView.swift        # 关于窗口
│       ├── ClipboardCardView.swift # 剪贴板卡片视图
│       ├── ClipboardWindowView.swift # 剪贴板窗口视图
│       ├── SettingsView.swift      # 设置窗口
│       └── StatusBarMenu.swift    # 状态栏菜单
├── Resources/
│   ├── Assets.xcassets/          # 应用图标资源
│   ├── ClipboardTool.entitlements # 权限配置
│   └── Info.plist                 # 应用配置
└── README.md                      # 项目说明
```

## 技术栈

- **Swift** - 主要开发语言
- **SwiftUI** - 用户界面框架
- **AppKit** - 系统集成
- **Carbon** - 键盘事件处理
- **CoreGraphics** - 图形和事件处理

## 系统要求

- macOS 13.0 (Ventura) 或更高版本
- Apple Silicon (M1/M2/M3) 或 Intel 芯片

## 开发环境

- Xcode 15.0+
- Swift 5.9+

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

## 作者

cxcboss
