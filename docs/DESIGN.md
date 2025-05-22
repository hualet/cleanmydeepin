# CleanMyDeepin 项目设计文档

## 一、架构设计

本项目采用 QML + C++ 技术栈，前端界面使用 QML 实现，后端逻辑与系统操作由 C++ 实现，通过 Qt 的信号槽机制进行通信。整体采用前后端分离、模块化设计，保证良好的可维护性与扩展性。

### 1. 总体架构图

```
+-------------------+         +-------------------+
|    QML 前端界面    | <-----> |   C++ 后端逻辑     |
+-------------------+         +-------------------+
         |                              |
         |         Qt 信号/槽           |
         +------------------------------+
```

- QML 负责 UI 展示、用户交互、动画效果等。
- C++ 负责文件扫描、清理、系统操作、配置管理等。
- 二者通过 Qt 的 Q_PROPERTY、信号槽、Q_INVOKABLE 等机制通信。

## 二、目录结构

```
cleanmydeepin/
├── src/
│   ├── main.cpp
│   ├── log/
│   │   ├── logger.h
│   │   └── logger.cpp
│   ├── core/
│   │   ├── scanmanager.h/cpp
│   │   ├── cleanmanager.h/cpp
│   │   ├── configmanager.h/cpp
│   │   └── translator.h/cpp
├── qml/
│   ├── MainWindow.qml
│   ├── ScanPage.qml
│   ├── CleanPage.qml
│   ├── SettingsPage.qml
│   ├── HelpPage.qml
│   └── components/
├── docs/
│   ├── PRD.md
│   └── 设计文档.md
├── translations/
├── resources/
```

## 三、主要模块说明

### 1. C++ 后端类
- **Logger**：统一日志接口，所有日志输出为英文，便于调试和维护。
- **ScanManager**：负责垃圾文件扫描，提供 startScan/stopScan 方法，信号包括 scanProgress、scanFinished、scanInterrupted。
- **CleanManager**：负责垃圾文件清理，提供 startClean 方法，信号包括 cleanProgress、cleanFinished。
- **ConfigManager**：负责配置项管理，支持开机自启等配置，Q_PROPERTY 支持 QML 绑定。
- **Translator**：负责多语言切换，支持 QML 调用。

### 2. QML 前端页面
- **MainWindow.qml**：主窗口，包含左侧标签栏和右侧页面内容区，支持高分屏缩放。
- **ScanPage.qml**：扫描页，包含扫描按钮、进度条、状态文本和中断按钮。
- **CleanPage.qml**：清理页，包含树形文件视图、全选/反选、底部清理按钮。
- **SettingsPage.qml**：设置页，包含开机自启、忽略目录/类型列表、保存按钮。
- **HelpPage.qml**：帮助页，包含功能说明和 FAQ。

### 3. 信号与槽
- QML 通过调用 C++ 的 Q_INVOKABLE 方法发起操作，C++ 通过信号反馈进度和结果，QML 绑定信号实现界面实时更新。

### 4. 国际化与高分屏
- 所有界面文案均使用 `qsTr`，源语言为英文，支持 Qt Linguist 翻译。
- 所有控件尺寸、间距均考虑 `scaleFactor`，适配高分屏。

### 5. 日志与注释
- 日志统一使用 Logger 模块，输出英文。
- 代码注释统一为中文，便于团队协作。

## 四、关键流程设计

### 1. 扫描流程
- 用户点击"扫描"按钮
- QML 触发信号，调用 C++ ScanManager::startScan()
- ScanManager 按类型/目录扫描垃圾文件，实时通过信号反馈进度、当前状态、已发现文件数
- QML 进度条、状态文本实时更新，支持"中断"按钮
- 扫描完成后，ScanManager 返回结果，QML 跳转到清理页并展示树状文件列表

扫描的位置包括：
- /tmp
- /var/tmp
- /var/log
- ~/.cache
- ~/.local/share/Trash
- ~/.thumbnails

数据结构设计：

```cpp
// 单个扫描项结构体
struct ScanItem {
    QString name;         // 文件/目录名
    QString path;         // 绝对路径
    bool isDir;           // 是否为目录
    qint64 size;          // 文件大小（目录为0或统计值）
    QList<ScanItem> children; // 子节点（仅目录有，文件为空）
};

// QVariantMap/QVariantList 形式（便于 QML 交互）
// 单个节点用 QVariantMap 表示
QVariantMap scanItem = {
    {"name", "xxx"},           // 文件/目录名
    {"path", "/xxx/xxx"},      // 绝对路径
    {"isDir", true},           // 是否为目录
    {"size", 12345},           // 文件大小
    {"children", QVariantList{ // 子节点列表
        QVariantMap{
            {"name", "child1"},
            {"path", "/xxx/xxx/child1"},
            {"isDir", false},
            {"size", 2345},
            {"children", QVariantList{}}
        },
        QVariantMap{
            {"name", "child2"},
            {"path", "/xxx/xxx/child2"},
            {"isDir", true},
            {"size", 0},
            {"children", QVariantList{
                // ... 递归嵌套
            }}
        }
    }}
};

// 整体扫描结果为 QVariantList
QVariantList scanResult = {
    scanItem1, // 根节点1
    scanItem2, // 根节点2
    // ...
};
```

### 2. 清理流程
- 用户在清理页勾选/全选垃圾项
- 点击"清理"按钮，弹出二次确认弹窗
- 确认后，QML 调用 C++ CleanManager::startClean()
- CleanManager 依次删除选中文件，实时反馈进度、当前处理项
- 清理完成后，返回结果（释放空间、失败项），QML 弹窗提示

### 3. 设置与帮助
- 设置页通过 QML 绑定 ConfigManager，支持开机自启、忽略目录等配置
- 帮助页展示内置文档，支持常见问题解答

## 五、技术实现要点

- **QML 动画与深色/浅色自适应**：使用 Qt Quick Controls 2，支持主题切换，动画流畅
- **C++ 文件操作权限**：需适配 deepin 权限模型，部分操作需 sudo/提权
- **进度与中断机制**：扫描/清理过程采用异步线程，支持实时进度与中断
- **树形数据结构**：扫描结果以树形结构传递给 QML，支持分组与展开
- **本地化**：采用 Qt Linguist，支持多语言切换
- **异常与安全保护**：关键目录保护、二次确认、失败友好提示
- **日志与调试**：所有关键操作均有日志输出，便于问题定位

## 六、后续扩展建议

- 支持定时清理、清理历史、插件扩展等
- 深度清理、智能推荐等高级功能
- UI 进一步美化，适配更多分辨率

---

本设计文档为 CleanMyDeepin 项目开发的技术蓝图，后续可根据实际开发情况进行细化和调整。