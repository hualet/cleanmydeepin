# CleanMyDeepin 项目核心设计文档

## 一、项目概述

CleanMyDeepin 是一款专为 deepin 操作系统设计的系统垃圾清理工具，采用 QML + C++ 前后端分离架构，旨在为用户提供高效、安全的系统清理体验。

## 二、核心架构设计

### 1. 整体架构

```
┌─────────────────┐    Qt 信号/槽    ┌─────────────────┐
│   QML 前端层     │ ←──────────────→ │   C++ 后端层     │
├─────────────────┤                 ├─────────────────┤
│ MainWindow.qml  │                 │ ScanManager     │
│ ScanPage.qml    │                 │ CleanManager    │
│ CleanPage.qml   │                 │ ConfigManager   │
│ SettingsPage.qml│                 │ Translator      │
│ HelpPage.qml    │                 │ Logger          │
└─────────────────┘                 └─────────────────┘
```

**设计原则：**
- 前端负责 UI 展示和用户交互
- 后端负责业务逻辑和系统操作
- 通过 Qt 属性绑定和信号槽机制实现通信
- 严格的模块化分离，避免耦合

### 2. 目录结构约定

```
cleanmydeepin/
├── src/                    # C++ 源码
│   ├── main.cpp           # 应用程序入口
│   ├── core/              # 核心业务模块
│   │   ├── scanmanager.*  # 扫描管理器
│   │   ├── cleanmanager.* # 清理管理器
│   │   ├── configmanager.*# 配置管理器
│   │   └── translator.*   # 国际化管理器
│   └── log/               # 日志模块
│       └── logger.*       # 统一日志接口
├── qml/                   # QML 界面文件
│   ├── MainWindow.qml     # 主窗口
│   ├── *Page.qml          # 各功能页面
│   └── components/        # 可复用组件
└── docs/                  # 项目文档
```

## 三、核心数据结构

### 1. 扫描项数据结构

```cpp
// C++ 端数据结构
struct ScanItem {
    QString name;         // 文件/目录名
    QString path;         // 绝对路径
    bool isDir;          // 是否为目录
    qint64 size;         // 文件大小
    QList<ScanItem> children; // 子节点
};

// QML 端数据结构 (QVariantMap)
{
    "name": "filename",
    "path": "/absolute/path",
    "isDir": true/false,
    "size": 12345,
    "expanded": false,        // UI 状态：是否展开
    "hasChildren": true,      // UI 状态：是否有子节点
    "childrenLoaded": false,  // UI 状态：子节点是否已加载
    "selected": false,        // UI 状态：是否被选中
    "children": []            // 子节点数组
}
```

**关键设计点：**
- 树形结构支持无限层级嵌套
- 数据与 UI 状态分离，便于状态管理
- 延迟加载子节点，提升性能

### 2. 扫描路径配置

```cpp
// 扫描目标路径
const QStringList ScanManager::kScanPaths = {
    "/tmp",                                    // 临时文件
    "/var/tmp",                               // 系统临时文件
    "/var/log",                               // 系统日志
    "~/.thumbnails"                           // 缩略图缓存
    // 注：部分路径已注释，可根据需要启用
};
```

## 四、关键流程设计

### 1. 扫描流程

```
用户点击扫描 → ScanManager::startScan() → 异步线程扫描
     ↓
进度更新信号 ← QMetaObject::invokeMethod ← 工作线程
     ↓
扫描完成 → scanFinished 信号 → CleanPage 展示结果
```

**核心实现：**
- 使用 QThread 异步扫描，避免阻塞 UI
- 通过 QMetaObject::invokeMethod 跨线程更新进度
- 扫描结果转换为 QVariantList 传递给 QML

### 2. 树形展示流程

```
根节点展示 → 用户点击展开 → loadChildrenFor()
     ↓
ScanManager::getChildren() → 构建子节点数据
     ↓
更新 treeData → 强制刷新视图 → 展示子节点
```

**关键机制：**
- 延迟加载：只在用户展开时加载子节点
- 状态同步：通过 `deepCopyNodeWithSelection` 保持选中状态
- 视图更新：通过 `forceTreeViewUpdate` 强制刷新

### 3. 选择状态管理

```
节点选择 → setNodeSelection() → 递归更新子节点
     ↓
更新 selectedNodes 映射 → 计算统计信息
     ↓
强制视图更新 → UI 同步显示
```

**核心算法：**
```javascript
function setNodeSelection(node, selected) {
    // 更新当前节点
    node.selected = selected;

    // 更新选择映射和统计
    if (selected) {
        selectedNodes[node.path] = node;
        selectedSize += node.size || 0;
        if (!node.isDir) selectedCount++;
    } else {
        delete selectedNodes[node.path];
        selectedSize -= node.size || 0;
        if (!node.isDir) selectedCount--;
    }

    // 递归处理子节点
    if (node.children) {
        for (var i = 0; i < node.children.length; i++) {
            setNodeSelection(node.children[i], selected);
        }
    }
}
```

## 五、架构约束与原则

### 1. 模块职责边界

- **ScanManager**: 只负责文件扫描和数据构建，不涉及 UI 状态
- **CleanPage**: 只负责数据展示和用户交互，不直接操作文件系统
- **FileTreeItem**: 只负责单个节点的展示，不处理业务逻辑

### 2. 数据流向

```
C++ 数据源 → QVariant 转换 → QML 属性绑定 → UI 展示
    ↑                                        ↓
信号反馈 ← Q_INVOKABLE 方法 ← 用户交互 ← 事件处理
```

### 3. 状态管理原则

- UI 状态与业务数据分离
- 使用不可变数据更新模式
- 状态变更必须通过规定的函数接口

### 4. 性能考虑

- 延迟加载：大型目录结构按需加载
- 异步处理：长时间操作使用工作线程
- 视图优化：最小化不必要的数据绑定

## 六、扩展点设计

### 1. 新增扫描类型
- 在 `kScanPaths` 中添加新路径
- 扩展 `ScanItem` 结构体添加类型标识

### 2. 新增 UI 组件
- 在 `qml/components/` 下添加可复用组件
- 遵循现有的属性和信号命名约定

### 3. 新增管理器模块
- 继承 QObject，使用 Q_PROPERTY 和信号槽
- 在 main.cpp 中注册为 QML 上下文属性

## 七、注意事项

1. **避免递归引用**: QML 组件不能引用自己，使用 Repeater 处理递归结构
2. **内存管理**: C++ 对象的生命周期管理，避免悬挂指针
3. **跨线程操作**: 使用 QMetaObject::invokeMethod 进行线程间通信
4. **状态一致性**: 数据更新时必须保持 UI 状态同步

---

**重要提醒**: 修改此项目时，必须遵循上述架构设计，避免破坏模块边界和数据流向。任何重大变更应先更新此设计文档。