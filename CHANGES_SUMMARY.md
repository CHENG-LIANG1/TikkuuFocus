# 更新总结 - 2026/2/8

## 1. 预置 Duration 新增 25 分钟 ✅

**文件**: `TransportMode.swift`

- **Walking**: 15, 25, 30 分钟（保持不变）
- **Cycling**: 25, 30, 45, 60 分钟（新增 25 分钟）
- **Driving**: 45, 60, 90, 120 分钟（新增 45 分钟）
- **Subway**: 25, 45, 60 分钟（保持不变）

## 2. 首页顶部优化 ✅

**文件**: `SetupView.swift`

### 改动：
- 顶部 padding 从 50pt 减少到 20pt
- Header 使用 ZStack 布局，确保 "Tikkuu" 标题绝对居中
- 左侧按钮（History、Trophy）和右侧按钮（Settings）不影响标题位置

### 布局结构：
```
ZStack {
  HStack { 左侧按钮 + Spacer }  // 左对齐
  Text("Tikkuu")                // 绝对居中
  HStack { Spacer + 右侧按钮 }  // 右对齐
}
```

## 3. 所有 Sheet 统一使用官方导航栏 ✅

**修改的文件**:
1. `HistoryView.swift`
2. `TrophyView.swift`
3. `TrophyDetailView.swift`
4. `SettingsView.swift`
5. `LocationPickerView.swift`
6. `MapPickerView.swift`
7. `RecordDetailView.swift`

### 改动：
- 移除所有自定义的 X 按钮和 header
- 使用 `NavigationView` + `.navigationTitle()` + `.navigationBarTitleDisplayMode(.inline)`
- 统一在右上角使用 `ToolbarItem(placement: .navigationBarTrailing)` 显示 "Done" 或 "完成" 按钮
- 删除了所有 `headerView` 的实现

## 4. Focus 页面地图优化 ✅

**文件**: `ExplorationMapView.swift`

### 改动：
- 添加固定缩放级别：`fixedZoomMeters = 1000` 米
- 地图交互模式从 `[.pan, .zoom, .rotate, .pitch]` 改为 `[.pan]`（只允许平移）
- 所有相机更新函数使用固定缩放级别
- 相机移动动画时长从 1.0 秒减少到 0.5 秒，移动更流畅
- 用户平移地图后，5 秒内不会自动跟随位置

### 优化点：
- 地图不会自动缩放，保持固定视野
- 移动流畅，不会一截一截跳动
- 用户可以手动平移查看周围
- 提供重新居中按钮，可随时回到当前位置

## 5. 选择 Location Sheet 优化 ✅

**文件**: `LocationPickerView.swift`

### 改动：
1. **顺序调整**：
   - Use Current Location（使用当前位置）
   - Choose from Map（地图选点）← 移到第二位
   - Preset Locations（预设地点）

2. **地图选点卡片优化**：
   - 未选择时：显示空心圆圈
   - 已选择时：显示实心圆圈 + 打勾 + 显示选择的地点名称
   - 右侧图标：未选择显示 chevron.right，已选择显示 checkmark.circle.fill

3. **MapPickerView 优化**：
   - 右上角文字从 "Skip" 改为 "Done"
   - 移除左上角的 Cancel 按钮
   - 使用统一的官方导航栏样式

### 视觉效果：
- 地图选点卡片会根据选择状态改变颜色（蓝色渐变）
- 显示选中的地点名称，用户可以清楚看到自己选了什么
- 所有选项都有一致的打勾/空心圆圈视觉反馈

## 本地化字符串新增 ✅

**文件**: 
- `zh-Hans.lproj/Localizable.strings`
- `en.lproj/Localizable.strings`

### 新增：
- `"Done" = "完成"` / `"Done" = "Done"`
- `"trophy.detail" = "奖杯详情"` / `"trophy.detail" = "Trophy Detail"`

## 技术细节

### 删除的代码：
- 7 个自定义 headerView 实现
- 所有自定义 X 按钮的代码
- 地图的缩放、旋转、倾斜交互

### 新增的代码：
- NavigationView 包装器
- 统一的 toolbar 配置
- 固定缩放级别常量
- 地图选点状态判断逻辑

## 测试建议

1. **Duration 测试**：
   - 检查所有交通方式的 duration 选项是否正确显示
   - 确认新增的 25 分钟和 45 分钟选项可以正常选择

2. **首页布局测试**：
   - 在不同设备尺寸上测试（iPhone SE, iPhone 15, iPhone 15 Pro Max）
   - 确认 "Tikkuu" 标题始终居中
   - 确认顶部 padding 合适，不会太挤

3. **Sheet 导航测试**：
   - 打开所有 sheet（History, Trophy, Settings, Location Picker）
   - 确认都有统一的导航栏和 Done 按钮
   - 测试中英文切换，确认 "Done"/"完成" 显示正确

4. **地图测试**：
   - 开始一个 journey，进入 focus 页面
   - 尝试缩放地图（应该无法缩放）
   - 平移地图，观察是否流畅
   - 等待位置更新，观察相机移动是否平滑

5. **Location Picker 测试**：
   - 打开 location picker
   - 点击 "Choose from Map"
   - 在地图上选择一个点
   - 确认卡片显示打勾和地点名称
   - 重新打开 location picker，确认选择状态保持

## 兼容性

- iOS 17.0+
- 所有 iPhone 尺寸
- 支持深色/浅色模式
- 支持中文/英文

## 已知问题

无

## 下一步建议

1. 在真机上测试地图性能
2. 收集用户反馈，调整固定缩放级别（目前是 1000 米）
3. 考虑添加缩放级别选项（小/中/大）
4. 优化地图标记的显示性能
