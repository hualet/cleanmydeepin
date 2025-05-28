#include "scanmanager.h"
#include "log/logger.h"
#include <QTimer>
#include <QVariant>
#include <QDir>
#include <QFileInfo>
#include <QString>
#include <QObject>
#include <QThread>
#include <QMap>
#include <QDebug>
#include <functional>

// TreeModel 实现
TreeModel::TreeModel(QObject *parent)
    : QAbstractItemModel(parent)
{
    // 创建根项目
    ScanManager::ScanItem rootData;
    rootData.name = "Root";
    rootData.path = "";
    rootData.isDir = true;
    rootData.size = 0;
    rootData.selected = false;
    m_rootItem = new TreeItem(rootData);
}

QModelIndex TreeModel::index(int row, int column, const QModelIndex &parent) const
{
    if (!hasIndex(row, column, parent))
        return QModelIndex();

    TreeItem *parentItem = getTreeItem(parent);
    if (!parentItem)
        return QModelIndex();

    TreeItem *childItem = parentItem->children.value(row);
    if (childItem)
        return createIndex(row, column, childItem);

    return QModelIndex();
}

QModelIndex TreeModel::parent(const QModelIndex &child) const
{
    if (!child.isValid())
        return QModelIndex();

    TreeItem *childItem = getTreeItem(child);
    TreeItem *parentItem = childItem ? childItem->parent : nullptr;

    if (parentItem == m_rootItem || !parentItem)
        return QModelIndex();

    TreeItem *grandParentItem = parentItem->parent;
    if (!grandParentItem)
        return QModelIndex();

    int row = grandParentItem->children.indexOf(parentItem);
    return createIndex(row, 0, parentItem);
}

int TreeModel::rowCount(const QModelIndex &parent) const
{
    TreeItem *parentItem = getTreeItem(parent);
    return parentItem ? parentItem->children.count() : 0;
}

int TreeModel::columnCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return 1; // 单列树形结构
}

QVariant TreeModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid())
        return QVariant();

    TreeItem *item = getTreeItem(index);
    if (!item)
        return QVariant();

    switch (role) {
    case NameRole:
        return item->data.name;
    case PathRole:
        return item->data.path;
    case IsDirRole:
        return item->data.isDir;
    case SizeRole:
        return item->data.size;
    case SelectedRole:
        return item->data.selected;
    case HasChildrenRole:
        return item->data.isDir && (!item->children.isEmpty() || !item->childrenLoaded);
    case Qt::DisplayRole:
        return item->data.name;
    default:
        return QVariant();
    }
}

bool TreeModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    if (!index.isValid()) {
        qDebug() << "TreeModel::setData: Invalid index";
        return false;
    }

    TreeItem *item = getTreeItem(index);
    if (!item) {
        qDebug() << "TreeModel::setData: No item found for index";
        return false;
    }

    if (role == SelectedRole) {
        bool newValue = value.toBool();
        item->data.selected = newValue;
        emit dataChanged(index, index, {SelectedRole});
        return true;
    }

    return false;
}

Qt::ItemFlags TreeModel::flags(const QModelIndex &index) const
{
    if (!index.isValid())
        return Qt::NoItemFlags;

    return Qt::ItemIsEnabled | Qt::ItemIsSelectable;
}

QHash<int, QByteArray> TreeModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[NameRole] = "name";
    roles[PathRole] = "path";
    roles[IsDirRole] = "isDir";
    roles[SizeRole] = "size";
    roles[SelectedRole] = "selected";
    roles[HasChildrenRole] = "hasChildren";
    return roles;
}

void TreeModel::setRootItems(const QList<ScanManager::ScanItem> &items)
{
    beginResetModel();

    // 清理现有数据
    qDeleteAll(m_rootItem->children);
    m_rootItem->children.clear();

    // 递归创建树形结构的辅助函数
    std::function<TreeItem*(const ScanManager::ScanItem&, TreeItem*)> createTreeItem =
        [&createTreeItem](const ScanManager::ScanItem& item, TreeItem* parent) -> TreeItem* {
        TreeItem *treeItem = new TreeItem(item, parent);

        // 递归创建子节点
        for (const auto &child : item.children) {
            TreeItem *childItem = createTreeItem(child, treeItem);
            treeItem->children.append(childItem);
        }

        // 如果有子节点，标记为已加载
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

void TreeModel::loadChildren(const QModelIndex &parent, const QList<ScanManager::ScanItem> &children)
{
    TreeItem *parentItem = getTreeItem(parent);
    if (!parentItem)
        return;

    if (parentItem->childrenLoaded)
        return;

    beginInsertRows(parent, 0, children.count() - 1);

    for (const auto &childData : children) {
        TreeItem *childItem = new TreeItem(childData, parentItem);
        parentItem->children.append(childItem);
    }

    parentItem->childrenLoaded = true;
    endInsertRows();
}

ScanManager::ScanItem* TreeModel::getScanItem(const QModelIndex &index) const
{
    TreeItem *item = getTreeItem(index);
    return item ? &item->data : nullptr;
}

TreeModel::TreeItem* TreeModel::getTreeItem(const QModelIndex &index) const
{
    if (index.isValid()) {
        TreeItem *item = static_cast<TreeItem*>(index.internalPointer());
        if (item)
            return item;
    }
    return m_rootItem;
}

// 扫描项结构体
struct ScanItem {
    QString name;         // 文件/目录名
    QString path;         // 绝对路径
    bool isDir;          // 是否为目录
    qint64 size;         // 文件大小（目录为0或统计值）
    QList<ScanItem> children; // 子节点（仅目录有，文件为空）
};

// 扫描目录常量定义
const QMap<QString, QString> ScanManager::kScanPaths = {
    {QObject::tr("System Logs"), "/var/log"},
    // {QObject::tr("User Cache"), QString::fromUtf8(qgetenv("HOME")) + "/.cache"},
    {QObject::tr("Trash"), QString::fromUtf8(qgetenv("HOME")) + "/.local/share/Trash"}
};

// 构造函数
ScanManager::ScanManager(QObject *parent)
    : QObject(parent), m_progress(0), m_scannedFiles(0), m_scannedDirs(0), m_scanning(false) {
    m_treeModel = new TreeModel(this);
}

// 获取进度
qreal ScanManager::progress() const {
    return m_progress;
}

// 获取已扫描文件数
int ScanManager::scannedFiles() const {
    return m_scannedFiles;
}

// 获取已扫描目录数
int ScanManager::scannedDirs() const {
    return m_scannedDirs;
}

// 获取树形模型
QAbstractItemModel* ScanManager::treeModel() const {
    return m_treeModel;
}

// 更新树形模型
void ScanManager::updateTreeModel() {
    if (!m_treeModel)
        return;

    QList<ScanItem> rootItems;
    for (const auto &item : m_scanResult) {
        rootItems.append(item);
    }

    m_treeModel->setRootItems(rootItems);
    emit treeModelChanged();
}

// 将 ScanItem 转换为 QVariantMap
QVariantMap ScanManager::itemToVariantMap(const ScanItem &item) {
    QVariantMap map;
    map["name"] = item.name;
    map["path"] = item.path;
    map["isDir"] = item.isDir;
    map["size"] = item.size;
    map["expanded"] = false;
    map["hasChildren"] = item.isDir && (!item.children.isEmpty() || !QDir(item.path).entryList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot).isEmpty());
    map["childrenLoaded"] = !item.children.isEmpty();

    if (!item.children.isEmpty()) {
        QVariantList childrenList;
        for (const ScanItem &child : item.children) {
            childrenList.append(itemToVariantMap(child));
        }
        map["children"] = childrenList;
    } else {
        map["children"] = QVariantList();
    }

    return map;
}

// 扫描目录并构建树形结构
void ScanManager::scanDirectory(const QString &path, ScanItem &parentItem) {
    if (!m_scanning) return;

    QDir dir(path);
    if (!dir.exists()) return;

    m_scannedDirs++;
    emit scannedDirsChanged();
    Logger::info(QString("Scanning directory: %1").arg(path));

    QFileInfoList entries = dir.entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::Hidden, QDir::DirsFirst);

    // 重置父目录大小
    parentItem.size = 0;

    for (const QFileInfo &info : entries) {
        if (!m_scanning) return;

        ScanItem item;
        item.name = info.fileName();
        item.path = info.absoluteFilePath();
        item.isDir = info.isDir();
        item.size = info.isDir() ? 0 : info.size();
        item.selected = false; // 添加默认选中状态

        if (info.isDir()) {
            scanDirectory(info.absoluteFilePath(), item);
            // 将子目录的大小累加到父目录
            parentItem.size += item.size;
        } else {
            m_scannedFiles++;
            emit scannedFilesChanged();
            // 将文件大小累加到父目录
            parentItem.size += item.size;
        }

        parentItem.children.append(item);
    }
}

// 获取指定路径的子节点
QVariant ScanManager::getChildren(const QString &path) {
    Logger::info(QString("Getting children for path: %1").arg(path));

    QDir dir(path);
    if (dir.exists()) {
        QVariantList children;
        QFileInfoList entries = dir.entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::Hidden, QDir::DirsFirst);

        for (const QFileInfo &info : entries) {
            QVariantMap child;
            child["name"] = info.fileName();
            child["path"] = info.absoluteFilePath();
            child["isDir"] = info.isDir();

            // 计算目录大小
            qint64 totalSize = 0;
            if (info.isDir()) {
                // 创建一个临时的ScanItem来计算目录大小
                ScanItem tempItem;
                tempItem.name = info.fileName();
                tempItem.path = info.absoluteFilePath();
                tempItem.isDir = true;
                scanDirectory(info.absoluteFilePath(), tempItem);
                totalSize = tempItem.size;
            } else {
                totalSize = info.size();
            }

            child["size"] = totalSize;
            child["expanded"] = false;
            child["hasChildren"] = info.isDir() && !QDir(info.absoluteFilePath()).entryList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot).isEmpty();
            child["childrenLoaded"] = false;
            child["children"] = QVariantList();

            children.append(child);
        }

        return children;
    }

    return QVariantList();
}

// 启动扫描
void ScanManager::startScan() {
    Logger::info("Scan started");
    if (m_scanning) return;

    m_scanning = true;
    m_progress = 0;
    m_scannedFiles = 0;
    m_scannedDirs = 0;
    m_scanResult.clear();
    m_treeResult.clear();

    emit progressChanged();
    emit scannedFilesChanged();
    emit scannedDirsChanged();
    emit treeResultChanged();

    // 创建工作线程
    QThread *workerThread = new QThread();
    QObject *worker = new QObject();
    worker->moveToThread(workerThread);

    // 连接工作线程完成后的清理
    connect(workerThread, &QThread::finished, worker, &QObject::deleteLater);
    connect(workerThread, &QThread::finished, workerThread, &QObject::deleteLater);

    // 在工作线程中执行扫描
    connect(workerThread, &QThread::started, worker, [this, worker, workerThread]() {
        int totalDirs = kScanPaths.size();
        int currentDir = 0;

        QVariantList rootNodes;
        QList<ScanItem> scanResults; // 临时存储扫描结果

        for (auto it = kScanPaths.begin(); it != kScanPaths.end(); ++it) {
            if (!m_scanning) break;

            const QString &name = it.key();
            const QString &path = it.value();

            ScanItem rootItem;
            rootItem.name = name;
            rootItem.path = path;
            rootItem.isDir = true;
            rootItem.size = 0;
            rootItem.selected = false; // 添加默认选中状态

            scanDirectory(path, rootItem);

            // 保存到扫描结果
            scanResults.append(rootItem);

            // 将根节点转换为 QVariantMap 并添加到结果中
            rootNodes.append(itemToVariantMap(rootItem));

            currentDir++;

            // 使用 QMetaObject::invokeMethod 在主线程中更新进度
            QMetaObject::invokeMethod(this, [this, currentDir, totalDirs]() {
                m_progress = (qreal)currentDir / totalDirs;
                emit progressChanged();
                emit scanProgress(static_cast<int>(m_progress * 100), m_scannedFiles);
            }, Qt::QueuedConnection);
        }

        // 扫描完成,在主线程中更新状态和发送结果
        QMetaObject::invokeMethod(this, [this, rootNodes, scanResults]() {
            m_progress = 1.0;
            emit progressChanged();
            emit scanProgress(100, m_scannedFiles);
            m_scanning = false;

            // 保存扫描结果到成员变量
            m_scanResult = scanResults;

            m_treeResult = rootNodes;
            emit treeResultChanged();

            // 更新树形模型
            updateTreeModel();

            emit scanFinished(m_treeResult);

            Logger::info(QString("Scan finished with %1 files, %2 directories").arg(m_scannedFiles).arg(m_scannedDirs));
        }, Qt::QueuedConnection);

        // 工作完成后退出线程
        workerThread->quit();
    });

    // 启动工作线程
    workerThread->start();
}

// 停止扫描
void ScanManager::stopScan() {
    Logger::info("Scan interrupted by user");
    m_scanning = false;
}

// 获取树形结构结果
QVariant ScanManager::treeResult() const {
    return QVariant::fromValue(m_treeResult);
}

// 获取扫描结果
QVariant ScanManager::scanResult() const {
    QVariantList resultList;
    for (const auto &item : m_scanResult) {
        QVariantMap map;
        map["path"] = item.path;
        map["isDir"] = item.isDir;
        map["size"] = item.size;
        resultList.append(map);
    }
    return QVariant::fromValue(resultList);
}

// 私有成员变量
typedef struct {
    qreal m_progress;
    int m_scannedFiles;
    int m_scannedDirs;
    bool m_scanning;
} ScanManagerPrivate;