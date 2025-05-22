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

// 扫描项结构体
struct ScanItem {
    QString name;         // 文件/目录名
    QString path;         // 绝对路径
    bool isDir;          // 是否为目录
    qint64 size;         // 文件大小（目录为0或统计值）
    QList<ScanItem> children; // 子节点（仅目录有，文件为空）
};

// 扫描目录常量定义
const QStringList ScanManager::kScanPaths = {
    "/tmp",
    "/var/tmp",
    "/var/log",
    // QString::fromUtf8(qgetenv("HOME")) + "/.cache",
    // QString::fromUtf8(qgetenv("HOME")) + "/.local/share/Trash",
    QString::fromUtf8(qgetenv("HOME")) + "/.thumbnails"
};

// 构造函数
ScanManager::ScanManager(QObject *parent)
    : QObject(parent), m_progress(0), m_scannedFiles(0), m_scannedDirs(0), m_scanning(false) {
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
    for (const QFileInfo &info : entries) {
        if (!m_scanning) return;

        ScanItem item;
        item.name = info.fileName();
        item.path = info.absoluteFilePath();
        item.isDir = info.isDir();
        item.size = info.isDir() ? 0 : info.size();

        if (info.isDir()) {
            scanDirectory(info.absoluteFilePath(), item);
        } else {
            m_scannedFiles++;
            emit scannedFilesChanged();
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
            child["size"] = info.isDir() ? 0 : info.size();
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
        for (const QString &path : kScanPaths) {
            if (!m_scanning) break;

            ScanItem rootItem;
            rootItem.name = QFileInfo(path).fileName();
            rootItem.path = path;
            rootItem.isDir = true;
            rootItem.size = 0;

            scanDirectory(path, rootItem);

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
        QMetaObject::invokeMethod(this, [this, rootNodes]() {
            m_progress = 1.0;
            emit progressChanged();
            emit scanProgress(100, m_scannedFiles);
            m_scanning = false;

            m_treeResult = rootNodes;
            emit treeResultChanged();
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