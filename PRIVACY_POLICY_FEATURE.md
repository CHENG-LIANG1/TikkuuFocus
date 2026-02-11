# 隐私政策功能添加说明

## 📋 功能概述

在设置页面的"支持"部分添加了"隐私政策"按钮，点击后会在 WebView 中打开隐私政策页面。

## ✅ 已完成的工作

### 1. 创建 WebView 组件
**文件**: `Views/WebView.swift`

包含两个主要组件：
- `WebView`: UIViewRepresentable 包装器，用于在 SwiftUI 中显示 WKWebView
- `PrivacyPolicyView`: 完整的隐私政策视图，包含导航栏和加载指示器

**功能特性**：
- ✅ 加载状态指示器
- ✅ 导航栏带关闭按钮
- ✅ 强制深色模式
- ✅ 错误处理
- ✅ 优雅的加载动画

### 2. 创建配置文件
**文件**: `Utilities/AppConfig.swift`

集中管理应用配置：
```swift
struct AppConfig {
    static let privacyPolicyURL = "https://example.com/privacy"
    static let termsOfServiceURL = "https://example.com/terms"
    static let supportEmail = "madfool@icloud.com"
    static let appStoreURL = "https://apps.apple.com/app/roam-focus"
    static let websiteURL = "https://roamfocus.app"
}
```

### 3. 更新 SettingsView
**文件**: `Views/SettingsView.swift`

添加的内容：
- ✅ `showPrivacyPolicy` 状态变量
- ✅ 隐私政策按钮（在支持部分）
- ✅ Sheet 展示隐私政策视图

### 4. 国际化字符串
**英文** (`en.lproj/Localizable.strings`):
- `"settings.privacy" = "Privacy Policy"`
- `"common.loading" = "Loading..."`

**中文** (`zh-Hans.lproj/Localizable.strings`):
- `"settings.privacy" = "隐私政策"`
- `"common.loading" = "加载中..."`

## 📱 用户界面

### 设置页面 - 支持部分
```
┌─────────────────────────────┐
│ 💌 Contact & Support        │
│    madfool@icloud.com       │
├─────────────────────────────┤
│ ✋ Privacy Policy         > │
└─────────────────────────────┘
```

### 隐私政策页面
```
┌─────────────────────────────┐
│ ← Privacy Policy      Done  │
├─────────────────────────────┤
│                             │
│   [WebView 内容]            │
│                             │
│   (加载时显示加载指示器)     │
│                             │
└─────────────────────────────┘
```

## 🔧 如何更新隐私政策 URL

### 方法 1: 修改 AppConfig.swift（推荐）
打开 `Utilities/AppConfig.swift`，修改：
```swift
static let privacyPolicyURL = "https://your-actual-url.com/privacy"
```

### 方法 2: 使用环境变量（高级）
可以扩展 AppConfig 支持环境变量：
```swift
static let privacyPolicyURL: String = {
    if let url = ProcessInfo.processInfo.environment["PRIVACY_POLICY_URL"] {
        return url
    }
    return "https://example.com/privacy"
}()
```

## 📝 代码结构

### WebView.swift
```
WebView (UIViewRepresentable)
├── makeUIView() - 创建 WKWebView
├── updateUIView() - 加载 URL
└── Coordinator - 处理导航事件
    ├── didStartProvisionalNavigation - 开始加载
    ├── didFinish - 加载完成
    └── didFail - 加载失败

PrivacyPolicyView
├── WebView - 显示网页内容
├── Loading Indicator - 加载状态
└── Navigation Bar - 标题和关闭按钮
```

### 数据流
```
用户点击"隐私政策"
    ↓
showPrivacyPolicy = true
    ↓
显示 PrivacyPolicyView
    ↓
从 AppConfig 读取 URL
    ↓
WebView 加载页面
    ↓
显示内容 / 加载指示器
```

## 🎨 设计特点

### 1. 加载指示器
- 半透明黑色背景
- 玻璃拟态卡片
- 白色进度指示器
- "加载中..." 文本

### 2. 导航栏
- 标题：Privacy Policy / 隐私政策
- 右侧：Done / 完成 按钮
- 深色模式

### 3. WebView
- 全屏显示
- 忽略底部安全区域
- 支持网页内导航

## 🚀 扩展建议

### 短期
- ✅ 已完成基础功能
- [ ] 添加实际的隐私政策 URL
- [ ] 测试不同网络状况下的表现

### 中期
- [ ] 添加刷新按钮
- [ ] 添加分享功能
- [ ] 支持离线缓存
- [ ] 添加错误页面

### 长期
- [ ] 添加用户服务条款
- [ ] 添加帮助中心
- [ ] 支持多语言网页
- [ ] 添加网页内搜索

## 📋 待办事项

### 必须完成
- [ ] **提供实际的隐私政策 URL**
- [ ] 在 AppConfig.swift 中更新 URL
- [ ] 测试 WebView 加载

### 可选优化
- [ ] 添加网络错误处理 UI
- [ ] 添加重试按钮
- [ ] 优化加载动画
- [ ] 添加进度条

## 🔗 相关文件

### 新增文件
1. `Views/WebView.swift` - WebView 组件
2. `Utilities/AppConfig.swift` - 配置文件

### 修改文件
1. `Views/SettingsView.swift` - 添加隐私政策按钮
2. `Resources/en.lproj/Localizable.strings` - 英文字符串
3. `Resources/zh-Hans.lproj/Localizable.strings` - 中文字符串

## 💡 使用示例

### 更新 URL
```swift
// 在 AppConfig.swift 中
static let privacyPolicyURL = "https://roamfocus.app/privacy"
```

### 添加其他 Web 页面
```swift
// 1. 在 AppConfig 添加 URL
static let termsURL = "https://roamfocus.app/terms"

// 2. 创建新视图
struct TermsOfServiceView: View {
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            WebView(url: URL(string: AppConfig.termsURL)!, isLoading: $isLoading)
                .navigationTitle("Terms of Service")
        }
    }
}

// 3. 在 SettingsView 添加按钮
ModernActionRow(
    title: "Terms of Service",
    icon: "doc.text.fill",
    showChevron: true
) {
    showTerms = true
}
```

## ✅ 测试清单

- [ ] 点击隐私政策按钮能正常打开
- [ ] 加载指示器正常显示
- [ ] 网页内容正确加载
- [ ] 点击 Done 按钮能关闭
- [ ] 中英文切换正常
- [ ] 深色模式显示正常
- [ ] 网页内链接可以点击
- [ ] 网络错误时有适当提示

## 🎊 总结

隐私政策功能已完全集成到应用中：
- ✅ 完整的 WebView 实现
- ✅ 优雅的加载体验
- ✅ 完善的国际化支持
- ✅ 易于配置和扩展

**下一步**: 提供实际的隐私政策 URL 即可使用！

---

*功能添加日期: 2026年2月10日*
*开发者: AI Assistant*
*状态: ✅ 等待 URL*
