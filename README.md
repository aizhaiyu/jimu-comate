# MockupStudio - 3D 设备 Mockup 制作应用

<div align="center">

![MockupStudio](https://img.shields.io/badge/MockupStudio-v1.0.0-00ff88)
![Flutter](https://img.shields.io/badge/Flutter-3.4+-02569B?logo=flutter)
![Three.js](https://img.shields.io/badge/Three.js-r128-000000?logo=three.js)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20HarmonyOS%20%7C%20Web%20%7C%20Windows%20%7C%20Linux-lightgrey)

**专为儿童设计的 3D 积木创意设计工具，让创意自由流动**

[快速开始](#-快速开始) • [功能特性](#-功能特性) • [文档](#-文档) • [进度](#-开发进度)

</div>

## 📋 项目简介

MockupStudio（积木工坊）是一个交互式的3D LEGO积木设计工具，让孩子们可以在数字环境中发挥创意，搭建自己的积木作品。应用采用现代化的Flutter框架开发，结合Three.js强大的3D渲染能力，提供流畅的创作体验。

## 🚀 快速开始

### 环境要求

- Flutter SDK: >=3.4.0
- Dart SDK: >=3.4.0
- 开发平台: Android Studio / VS Code

### 安装步骤

1. 克隆项目
```bash
git clone <repository-url>
cd app
```

2. 安装依赖
```bash
flutter pub get
```

3. 运行项目
```bash
# Android
flutter run

# iOS
flutter run -d ios

# Web
flutter run -d web

# Windows
flutter run -d windows

# Linux
flutter run -d linux
```

## ✨ 功能特性

### 🎨 核心创作功能
- **3D积木搭建**: 直观的拖拽式积木放置系统
- **多种积木形状**: 支持标准LEGO积木形状，包括带轮子的特殊积木
- **自定义颜色**: 丰富的颜色选择器，打造个性化作品
- **360度旋转**: 自由旋转积木，实现精确摆放
- **多层级搭建**: 支持复杂的3D结构设计

### 🛠️ 编辑工具
- **构建模式**: 添加和放置积木
- **绘制模式**: 为积木上色
- **擦除模式**: 删除不需要的积木
- **查看模式**: 自由视角预览
- **检查模式**: 查看积木属性信息

### 📁 项目管理
- **项目保存**: 本地SQLite数据库存储
- **项目加载**: 快速恢复之前的创作
- **缩略图生成**: 自动生成项目预览图
- **标签分类**: 为项目添加自定义标签
- **搜索排序**: 按名称、时间、积木数量排序

### 📚 教学系统
- **新手引导**: 交互式教程，帮助用户快速上手
- **分步教学**: 循序渐进的功能介绍
- **操作提示**: 实时显示操作建议

### 🎯 用户体验
- **横屏优化**: 强制横屏模式，提供最佳创作体验
- **全屏沉浸**: 隐藏状态栏，专注创作
- **流畅动画**: 60fps的3D渲染体验
- **响应式设计**: 适配不同屏幕尺寸

## 🏗️ 技术架构

### 前端框架
- **Flutter**: 跨平台UI框架
- **Riverpod**: 状态管理解决方案
- **Go Router**: 路由管理

### 3D渲染
- **Three.js**: 3D图形渲染引擎
- **WebView**: Flutter与Three.js的桥梁
- **Vector Math**: 3D数学计算库

### 数据存储
- **SQLite**: 本地数据库，存储项目数据
- **SharedPreferences**: 用户偏好设置
- **File System**: 项目文件和资源管理

### 平台支持
- **移动端**: Android, iOS, HarmonyOS
- **桌面端**: Windows, Linux
- **Web端**: 现代浏览器支持

## 📊 数据模型

### BrickData (积木数据)
```dart
class BrickData {
  final String id;              // 唯一标识
  final List<double> position;   // 3D坐标 [x, y, z]
  final String color;           // 颜色值
  final List<num> size;         // 尺寸 [width, height, depth]
  final int rotation;           // 旋转角度 (0-3)
  final bool hasWheels;         // 是否带轮子
}
```

### ProjectData (项目数据)
```dart
class ProjectData {
  final String id;              // 项目ID
  final String name;            // 项目名称
  final String description;     // 项目描述
  final DateTime createdAt;     // 创建时间
  final DateTime updatedAt;     // 更新时间
  final List<dynamic> bricks;   // 积木列表
  final String thumbnail;       // 缩略图
  final List<String> tags;      // 项目标签
}
```

## 🔧 开发配置

### 依赖管理
项目使用以下核心依赖：

- `flutter_riverpod: ^2.5.1` - 状态管理
- `flutter_inappwebview: ^6.0.0` - WebView集成
- `sqflite: ^2.3.2` - 数据库
- `go_router: ^13.2.0` - 路由管理
- `file_picker: ^6.1.1` - 文件选择

### 鸿蒙适配
项目已适配HarmonyOS平台，使用专门的OHOS版本依赖：
- `file_picker_ohos` - 鸿蒙文件选择器
- 其他平台的OHOS适配包

## 📱 界面设计

### 主页面 (HomePage)
- 动画标题展示
- 快速入口按钮
- 3D积木Logo展示

### 积木工作室 (LegoStudioPage)
- 3D工作区域
- 工具栏面板
- 项目操作菜单
- 教学覆盖层

### 我的作品 (MyWorksPage)
- 项目网格/列表视图
- 搜索和筛选功能
- 项目管理操作

### 设置页面 (SettingsPage)
- 应用偏好设置
- 关于信息
- 开发者选项

## 🔄 业务流程

### 创作流程
1. **新建项目** → 选择空白画布或模板
2. **选择积木** → 从工具栏选择积木形状和颜色
3. **放置积木** → 在3D空间中定位和旋转
4. **继续搭建** → 重复添加积木，构建完整作品
5. **保存项目** → 命名并保存到本地数据库

### 管理流程
1. **项目列表** → 查看所有保存的作品
2. **搜索筛选** → 按条件查找特定项目
3. **项目操作** → 打开编辑、重命名、删除
4. **导出分享** → 生成缩略图，分享作品

## 📈 开发进度

### 已完成功能 ✅
- [x] 基础3D渲染引擎集成
- [x] 积木添加和基本操作
- [x] 项目保存和加载系统
- [x] 用户界面框架
- [x] 横屏模式优化
- [x] 新手教学系统
- [x] 多平台适配 (Android/iOS/HarmonyOS)

### 开发中功能 🚧
- [ ] 高级积木形状支持
- [ ] 动画和时间轴编辑
- [ ] 云端同步功能
- [ ] 社区分享平台

### 计划功能 📋
- [ ] AR预览模式
- [ ] 积木物理模拟
- [ ] 多人协作编辑
- [ ] AI辅助设计

## ?? 贡献指南

1. Fork 本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 📞 联系方式

- 项目地址: [GitHub Repository]
- 问题反馈: [Issues Page]
- 开发团队: Comate Team

---

**让每个孩子都能成为小小建筑师！** 🏗️🎨