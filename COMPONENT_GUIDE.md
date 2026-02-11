# 组件使用快速指南

## 📦 公共样式 (CommonStyles.swift)

### 玻璃卡片效果
```swift
// 基础用法
VStack {
    Text("内容")
}
.glassCard()

// 自定义圆角和内边距
VStack {
    Text("内容")
}
.glassCard(cornerRadius: 20, padding: 20)
```

### 渐变样式
```swift
// 主要渐变（蓝紫色）
.fill(GradientStyles.primaryGradient)

// 强调渐变（橙红色）
.fill(GradientStyles.accentGradient)

// 成功渐变（绿青色）
.fill(GradientStyles.successGradient)

// 警告渐变（黄橙色）
.fill(GradientStyles.warningGradient)
```

### 间距和圆角
```swift
// 间距
.padding(Spacing.xs)   // 4pt
.padding(Spacing.sm)   // 8pt
.padding(Spacing.md)   // 12pt
.padding(Spacing.lg)   // 16pt
.padding(Spacing.xl)   // 20pt
.padding(Spacing.xxl)  // 24pt

// 圆角
RoundedRectangle(cornerRadius: CornerRadius.sm)   // 8pt
RoundedRectangle(cornerRadius: CornerRadius.md)   // 12pt
RoundedRectangle(cornerRadius: CornerRadius.lg)   // 16pt
RoundedRectangle(cornerRadius: CornerRadius.xl)   // 20pt
RoundedRectangle(cornerRadius: CornerRadius.xxl)  // 24pt
```

### 动画配置
```swift
// 快速弹簧动画
.animation(AnimationConfig.quickSpring, value: someValue)

// 平滑弹簧动画
.animation(AnimationConfig.smoothSpring, value: someValue)

// 慢速弹簧动画
.animation(AnimationConfig.slowSpring, value: someValue)

// 弹跳动画
.animation(AnimationConfig.bouncy, value: someValue)
```

## 🔘 按钮组件 (CommonButtons.swift)

### 主要按钮
```swift
PrimaryButton(
    title: "开始旅程",
    icon: "play.fill",
    isLoading: false
) {
    // 点击操作
}
```

### 次要按钮
```swift
SecondaryButton(
    title: "取消",
    icon: "xmark"
) {
    // 点击操作
}
```

### 图标按钮
```swift
IconButton(
    icon: "gear",
    size: 44
) {
    // 点击操作
}
```

### 渐变按钮
```swift
GradientButton(
    title: "保存",
    icon: "checkmark",
    gradient: GradientStyles.successGradient
) {
    // 点击操作
}
```

### 按钮样式
```swift
// 缩放效果
Button("点击") { }
    .buttonStyle(ScaleButtonStyle())

// 卡片按钮效果
Button("点击") { }
    .buttonStyle(CardButtonStyle())
```

## 🎴 卡片组件 (CommonCards.swift)

### 统计卡片
```swift
StatCard(
    icon: "clock.fill",
    title: "总时长",
    value: "12 hr 30 min",
    color: .blue,
    gradient: GradientStyles.primaryGradient
)
```

### 信息卡片
```swift
InfoCard(
    title: "位置服务",
    subtitle: "已启用",
    icon: "location.fill",
    color: .green
)
```

### 指标卡片
```swift
MetricCard(
    icon: "star.fill",
    value: "128",
    label: "发现的景点",
    gradient: GradientStyles.warningGradient
)
```

### 空状态卡片
```swift
EmptyStateCard(
    icon: "tray",
    title: "暂无数据",
    message: "开始你的第一次旅程来查看统计数据",
    actionTitle: "开始旅程"
) {
    // 操作
}
```

### 功能卡片
```swift
FeatureCard(
    icon: "map.fill",
    title: "虚拟旅程",
    description: "根据你的专注时长和交通方式前往随机目的地",
    color: .blue
)
```

## 📊 History 组件

### 记录行组件
```swift
// 地点记录
LocationRecordRow(
    location: "旧金山",
    count: 15,
    totalTime: 3600
)

// 交通方式记录
TransportModeRow(
    mode: "cycling",
    count: 20,
    distance: 50000
)

// 时间记录
TimeRecordRow(record: journeyRecord)

// 距离记录
DistanceRecordRow(record: journeyRecord)

// 完成记录
CompletedRecordRow(record: journeyRecord)

// POI 记录
POIRecordRow(record: journeyRecord)
```

### 统计卡片
```swift
// 概览统计网格
OverviewStatsGrid(
    totalTime: 36000,
    totalDistance: 100000,
    completedCount: 50,
    totalPOIs: 200
)

// 成就卡片网格
AchievementCardsGrid(
    longestJourney: record1,
    farthestDistance: record2,
    mostPOIs: record3,
    fastestSpeed: record4,
    onTapLongest: { },
    onTapFarthest: { },
    onTapMostPOIs: { },
    onTapFastest: { }
)

// 里程碑卡片
MilestoneCard(
    icon: "calendar",
    title: "活跃天数",
    value: "45",
    color: .blue
)
```

## 🎯 Journey Summary 组件

### 旅程卡片
```swift
// 时间卡片
JourneyTimeCard(
    duration: 3600,
    cardsAppeared: true
)

// 天气卡片
JourneyWeatherCard(
    weatherIcon: "sun.max.fill",
    weatherCondition: "晴朗",
    isDaytime: true,
    cardsAppeared: true
)

// 距离卡片
JourneyDistanceCard(
    distance: 5000,
    cardsAppeared: true
)

// 交通方式卡片
JourneyTransportCard(
    transportMode: .subway,
    subwayLine: "1号线",
    subwayColor: .red,
    cardsAppeared: true
)

// POI 卡片
JourneyPOICard(
    poiCount: 8,
    cardsAppeared: true
)
```

## ⚙️ Setup 组件

### 选择器组件
```swift
// 交通方式选择器
TransportModeSelector(
    selectedMode: $selectedMode,
    cardsAppeared: true
)

// 时长选择器
DurationSelector(
    selectedDuration: $selectedDuration,
    cardsAppeared: true
)

// 位置源选择器
LocationSourceSelector(
    selectedLocation: $selectedLocation,
    currentLocationName: "旧金山",
    onShowPicker: { }
)

// 自定义时长选择器
CustomDurationPicker(
    duration: $duration,
    isPresented: $showPicker
)
```

## 🎨 样式最佳实践

### 1. 使用统一的间距
```swift
// ✅ 好的做法
VStack(spacing: Spacing.md) {
    Text("标题")
    Text("内容")
}

// ❌ 避免硬编码
VStack(spacing: 12) {
    Text("标题")
    Text("内容")
}
```

### 2. 使用预定义的渐变
```swift
// ✅ 好的做法
.fill(GradientStyles.primaryGradient)

// ❌ 避免重复定义
.fill(LinearGradient(
    colors: [Color.blue, Color.purple],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
))
```

### 3. 使用玻璃卡片效果
```swift
// ✅ 好的做法
VStack {
    // 内容
}
.glassCard()

// ❌ 避免重复样式代码
VStack {
    // 内容
}
.padding(16)
.background(
    RoundedRectangle(cornerRadius: 16)
        .fill(.ultraThinMaterial)
        // ... 更多代码
)
```

### 4. 使用公共组件
```swift
// ✅ 好的做法
PrimaryButton(title: "开始", icon: "play.fill") {
    startJourney()
}

// ❌ 避免自定义按钮
Button(action: { startJourney() }) {
    HStack {
        Image(systemName: "play.fill")
        Text("开始")
    }
    .foregroundColor(.white)
    .padding()
    .background(Color.blue)
    .cornerRadius(12)
}
```

## 🔧 性能优化提示

### 1. 使用 LazyVStack/LazyHStack
```swift
// 对于长列表
ScrollView {
    LazyVStack(spacing: Spacing.md) {
        ForEach(items) { item in
            ItemRow(item: item)
        }
    }
}
```

### 2. 避免过度嵌套
```swift
// ✅ 好的做法 - 提取为组件
var body: some View {
    VStack {
        HeaderView()
        ContentView()
        FooterView()
    }
}

// ❌ 避免 - 所有代码在一个 body 中
var body: some View {
    VStack {
        // 100+ 行代码
    }
}
```

### 3. 使用 @ViewBuilder
```swift
@ViewBuilder
func makeContent() -> some View {
    if condition {
        ContentA()
    } else {
        ContentB()
    }
}
```

## 📱 响应式设计

### 使用 GeometryReader
```swift
GeometryReader { geometry in
    VStack {
        // 根据 geometry.size 调整布局
    }
}
```

### 使用环境值
```swift
@Environment(\.horizontalSizeClass) var sizeClass

var body: some View {
    if sizeClass == .compact {
        CompactLayout()
    } else {
        RegularLayout()
    }
}
```

## 🌐 国际化

### 使用 L() 函数
```swift
// ✅ 好的做法
Text(L("journey.summary.focusTime"))

// ❌ 避免硬编码
Text("Focus Time")
```

## 🎯 总结

使用这些公共组件和样式可以：
- ✅ 保持 UI 一致性
- ✅ 减少重复代码
- ✅ 提高开发效率
- ✅ 便于维护和更新
- ✅ 提升代码质量

**记住**: 优先使用公共组件，只在必要时创建自定义组件！
