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
    bool selected;       // 选中状态
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

### 2. TreeModel 数据模型

项目使用基于 `QAbstractItemModel` 的标准 TreeView 实现，提供高性能的树形数据展示：

```cpp
class TreeModel : public QAbstractItemModel {
    Q_OBJECT

public:
    // 数据角色定义
    enum Roles {
        NameRole = Qt::UserRole + 1,    // 257 - 文件/目录名
        PathRole,                       // 258 - 绝对路径
        IsDirRole,                      // 259 - 是否为目录
        SizeRole,                       // 260 - 文件大小
        SelectedRole,                   // 261 - 选中状态
        HasChildrenRole                 // 262 - 是否有子节点
    };

private:
    struct TreeItem {
        ScanManager::ScanItem data;     // 业务数据
        TreeItem *parent;               // 父节点指针
        QList<TreeItem*> children;      // 子节点列表
        bool childrenLoaded;            // 子节点是否已加载
    };
};
```

**关键设计点：**
- 使用 Qt 标准的 Model/View 架构
- 数据角色明确分离，便于 QML 绑定
- 树形结构支持无限层级嵌套
- 内置选中状态管理，支持父子节点同步

### 3. 扫描路径配置

```cpp
// 扫描目标路径映射
const QMap<QString, QString> ScanManager::kScanPaths = {
    {QObject::tr("System Logs"), "/var/log"},
    {QObject::tr("Trash"), QString::fromUtf8(qgetenv("HOME")) + "/.local/share/Trash"}
    // 注：可根据需要添加更多扫描路径
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
扫描完成 → updateTreeModel() → TreeModel::setRootItems()
     ↓
递归创建 TreeItem → 构建完整树形结构
     ↓
TreeView 绑定模型 → 用户点击展开 → TreeView::toggleExpanded()
     ↓
QML 委托渲染 → 展示节点内容 → 支持交互操作
```

**关键机制：**
- **一次性加载**：扫描完成后构建完整树形结构，无需延迟加载
- **标准 TreeView**：使用 Qt 原生 TreeView 组件，性能优异
- **角色绑定**：通过 `model.name`、`model.selected` 等直接绑定数据
- **自动展开**：TreeView 内置展开/收起逻辑，无需手动管理状态

### 3. 选择状态管理

```
CheckBox 状态变更 → TreeModel::setData(SelectedRole) → 更新节点选中状态
     ↓
递归设置子节点 → setNodeSelection() → 批量更新子树状态
     ↓
dataChanged 信号 → QML 自动更新 → UI 同步显示
     ↓
updateSelectionStats() → 计算统计信息 → 更新选择计数
```

**核心实现：**
```javascript
// QML 端选择状态管理
onCheckedChanged: {
    if (checked !== itemSelected && modelIndex && ScanManager && ScanManager.treeModel) {
        // 设置当前节点选中状态
        var success = ScanManager.treeModel.setData(modelIndex, checked, 261); // SelectedRole

        // 递归设置子节点选中状态
        var rowCount = ScanManager.treeModel.rowCount(modelIndex);
        for (var i = 0; i < rowCount; i++) {
            var childIndex = ScanManager.treeModel.index(i, 0, modelIndex);
            cleanPage.setNodeSelection(childIndex, checked);
        }

        // 更新统计信息
        cleanPage.updateSelectionStats();
    }
}
```

```cpp
// C++ 端数据更新
bool TreeModel::setData(const QModelIndex &index, const QVariant &value, int role) {
    if (role == SelectedRole) {
        TreeItem *item = getTreeItem(index);
        item->data.selected = value.toBool();
        emit dataChanged(index, index, {SelectedRole});
        return true;
    }
    return false;
}
```

**关键特性：**
- **父子同步**：选中父节点时自动选中所有子节点
- **角色驱动**：通过 SelectedRole (261) 统一管理选中状态
- **实时统计**：选择变更时自动更新文件数量和大小统计
- **状态持久**：选中状态保存在 TreeItem 数据结构中

## 五、架构约束与原则

### 1. 模块职责边界

- **ScanManager**: 负责文件扫描、数据构建和 TreeModel 管理，提供统一的数据接口
- **TreeModel**: 负责树形数据的存储、索引和角色管理，实现标准的 Model/View 接口
- **CleanPage**: 负责数据展示、用户交互和选择状态管理，不直接操作文件系统
- **TreeView 委托**: 负责单个节点的渲染和交互，通过角色绑定获取数据

### 2. 数据流向

```
ScanManager → TreeModel → QML TreeView → 委托渲染
    ↑              ↓              ↓           ↓
角色更新 ← dataChanged ← setData ← 用户交互 ← CheckBox
```

**数据流说明：**
- **正向流**：C++ 扫描数据 → TreeModel 角色 → QML 属性绑定 → UI 展示
- **反向流**：用户操作 → QML 事件 → TreeModel::setData → 数据更新
- **信号机制**：dataChanged 信号自动触发 QML 视图更新

### 3. 状态管理原则

- 选中状态通过 TreeModel 角色统一管理
- 使用标准的 Model/View 数据变更通知机制
- 状态变更必须通过 TreeModel::setData 接口
- 父子节点选中状态自动同步

### 4. 性能考虑

- **一次性构建**：扫描完成后构建完整树形结构，避免频繁的数据操作
- **角色优化**：使用明确的数据角色，减少不必要的数据转换
- **异步扫描**：长时间扫描操作使用工作线程，避免阻塞 UI
- **原生组件**：使用 Qt TreeView 原生组件，获得最佳渲染性能

## 六、TreeModel 实现细节

### 1. 核心方法实现

```cpp
// 索引创建 - 根据行列和父索引创建子索引
QModelIndex TreeModel::index(int row, int column, const QModelIndex &parent) const {
    TreeItem *parentItem = getTreeItem(parent);
    TreeItem *childItem = parentItem->children.value(row);
    return childItem ? createIndex(row, column, childItem) : QModelIndex();
}

// 父索引获取 - 根据子索引获取父索引
QModelIndex TreeModel::parent(const QModelIndex &child) const {
    TreeItem *childItem = getTreeItem(child);
    TreeItem *parentItem = childItem ? childItem->parent : nullptr;

    if (parentItem == m_rootItem || !parentItem)
        return QModelIndex();

    TreeItem *grandParentItem = parentItem->parent;
    int row = grandParentItem->children.indexOf(parentItem);
    return createIndex(row, 0, parentItem);
}

// 数据设置 - 支持选中状态更新
bool TreeModel::setData(const QModelIndex &index, const QVariant &value, int role) {
    if (role == SelectedRole) {
        TreeItem *item = getTreeItem(index);
        item->data.selected = value.toBool();
        emit dataChanged(index, index, {SelectedRole});
        return true;
    }
    return false;
}
```

### 2. 递归树形结构构建

```cpp
void TreeModel::setRootItems(const QList<ScanManager::ScanItem> &items) {
    beginResetModel();

    // 递归创建树形结构的辅助函数
    std::function<TreeItem*(const ScanManager::ScanItem&, TreeItem*)> createTreeItem =
        [&createTreeItem](const ScanManager::ScanItem& item, TreeItem* parent) -> TreeItem* {
        TreeItem *treeItem = new TreeItem(item, parent);

        // 递归创建子节点
        for (const auto &child : item.children) {
            TreeItem *childItem = createTreeItem(child, treeItem);
            treeItem->children.append(childItem);
        }

        treeItem->childrenLoaded = !item.children.isEmpty();
        return treeItem;
    };

    // 添加新的根项目
    for (const auto &item : items) {
        TreeItem *treeItem = createTreeItem(item, m_rootItem);
        m_rootItem->children.append(treeItem);
    }

    endResetModel();
}
```

### 3. 角色系统设计

| 角色名称 | 角色值 | 数据类型 | 用途描述 |
|---------|--------|----------|----------|
| NameRole | 257 | QString | 文件/目录名称，用于显示 |
| PathRole | 258 | QString | 绝对路径，用于唯一标识 |
| IsDirRole | 259 | bool | 是否为目录，用于图标显示 |
| SizeRole | 260 | qint64 | 文件大小，用于统计计算 |
| SelectedRole | 261 | bool | 选中状态，用于复选框绑定 |
| HasChildrenRole | 262 | bool | 是否有子节点，用于展开图标 |

**角色使用示例：**
```qml
// QML 中通过角色直接绑定数据
readonly property string itemName: model.name        // NameRole
readonly property bool itemSelected: model.selected  // SelectedRole
readonly property bool itemIsDir: model.isDir       // IsDirRole
```

## 七、扩展点设计

### 1. 新增扫描类型
- 在 `kScanPaths` 中添加新路径
- 扩展 `ScanItem` 结构体添加类型标识

### 2. 新增 UI 组件
- 在 `qml/components/` 下添加可复用组件
- 遵循现有的属性和信号命名约定

### 3. 新增管理器模块
- 继承 QObject，使用 Q_PROPERTY 和信号槽
- 在 main.cpp 中注册为 QML 上下文属性

## 八、注意事项

1. **TreeModel 角色一致性**: QML 中使用的角色值必须与 C++ 中定义的角色值完全一致，特别是 SelectedRole (261)
2. **模型重置时机**: 调用 `beginResetModel()` 和 `endResetModel()` 时必须确保数据结构的完整性
3. **内存管理**: TreeItem 对象的生命周期由 TreeModel 管理，避免手动删除
4. **跨线程操作**: 使用 QMetaObject::invokeMethod 进行线程间通信，确保 UI 更新在主线程执行
5. **递归深度控制**: 大型目录结构可能导致深度递归，需要考虑栈溢出风险
6. **选中状态同步**: 父子节点选中状态变更时，必须通过 TreeModel::setData 统一处理
7. **角色绑定**: QML 委托中的数据绑定应使用 `model.roleName` 格式，避免直接访问索引

---

**重要提醒**: 修改此项目时，必须遵循上述架构设计，避免破坏模块边界和数据流向。任何重大变更应先更新此设计文档。