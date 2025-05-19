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

// 构造函数
ScanManager::ScanManager(QObject *parent)
    : QObject(parent), m_progress(0), m_scannedFiles(0), m_scannedDirs(0), m_scanning(false) {
    // 测试用，初始化一个简单的树形结构
    QTimer::singleShot(500, this, &ScanManager::initTestData);
}

// 测试用，生成简单的树形数据
void ScanManager::initTestData() {
    Logger::info("Initializing test tree data");

    // 清除现有数据
    m_pathChildrenMap.clear();
    m_treeResult.clear();

    // 添加几个测试目录作为根节点
    QString homeDir = QString::fromUtf8(qgetenv("HOME"));
    QStringList testDirs = {
        "/tmp",
        homeDir,
        "/var"
    };

    // 为每个测试目录添加一些子节点
    for (const QString &dir : testDirs) {
        QDir rootDir(dir);
        if (rootDir.exists()) {
            // 添加根节点
            QVariantMap rootNode;
            rootNode["name"] = rootDir.dirName().isEmpty() ? dir : rootDir.dirName();
            rootNode["path"] = dir;
            rootNode["isDir"] = true;
            rootNode["size"] = 0;
            rootNode["expanded"] = false;
            rootNode["hasChildren"] = true;
            rootNode["childrenLoaded"] = false;

            m_treeResult.append(rootNode);

            // 添加一些子节点
            QFileInfoList entries = rootDir.entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot, QDir::DirsFirst);
            for (int i = 0; i < qMin(entries.size(), 10); i++) {
                const QFileInfo &info = entries.at(i);
                addPathToChildrenMap(info.absoluteFilePath(), info.isDir(), info.size());
            }
        }
    }

    Logger::info(QString("Test data initialized with %1 root nodes").arg(m_treeResult.size()));
    emit treeResultChanged();
}

qreal ScanManager::progress() const {
    return m_progress;
}

int ScanManager::scannedFiles() const {
    return m_scannedFiles;
}

int ScanManager::scannedDirs() const {
    return m_scannedDirs;
}

// 扫描目录常量
const QStringList ScanManager::kScanPaths = {
    "/tmp",
    "/var/tmp",
    "/var/log",
    QString::fromUtf8(qgetenv("HOME")) + "/.cache",
    QString::fromUtf8(qgetenv("HOME")) + "/.local/share/Trash",
    QString::fromUtf8(qgetenv("HOME")) + "/.thumbnails"
};

void ScanManager::addPathToChildrenMap(const QString &path, bool isDir, qint64 size) {
    // 获取父目录
    QFileInfo fileInfo(path);
    QString parentPath = fileInfo.absolutePath();
    QString name = fileInfo.fileName();

    // 创建当前节点
    QVariantMap node;
    node["name"] = name;
    node["path"] = path;
    node["isDir"] = isDir;
    node["size"] = size;
    node["expanded"] = false;
    node["hasChildren"] = isDir; // 目录可能有子节点，先标记为可能有
    node["childrenLoaded"] = false; // 标记子节点尚未加载

    // 将节点添加到父目录的子节点列表中
    if (!m_pathChildrenMap.contains(parentPath)) {
        m_pathChildrenMap[parentPath] = QVariantList();
    }
    m_pathChildrenMap[parentPath].append(node);

    Logger::info(QString("Added path to map: %1, parent: %2").arg(path).arg(parentPath));
}

void ScanManager::scanDirectory(const QString &path) {
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
        item.path = info.absoluteFilePath();
        item.isDir = info.isDir();
        item.size = info.isDir() ? 0 : info.size();
        m_scanResult.append(item);

        // 添加到路径-子节点映射中
        addPathToChildrenMap(info.absoluteFilePath(), info.isDir(), item.size);

        if (info.isDir()) {
            scanDirectory(info.absoluteFilePath());
        } else {
            m_scannedFiles++;
            emit scannedFilesChanged();
        }
    }
}

// 构建第一层树状结构
void ScanManager::buildFirstLevelTree() {
    m_treeResult.clear();
    Logger::info("Building first level tree structure");

    // 为每个根路径创建节点
    for (const QString &path : kScanPaths) {
        QFileInfo info(path);
        if (info.exists()) {
            QVariantMap rootNode;
            rootNode["name"] = info.fileName().isEmpty() ? path : info.fileName();
            rootNode["path"] = path;
            rootNode["isDir"] = true;
            rootNode["size"] = 0;
            rootNode["expanded"] = false;
            rootNode["hasChildren"] = m_pathChildrenMap.contains(path) && !m_pathChildrenMap[path].isEmpty();
            rootNode["childrenLoaded"] = false; // 标记子节点尚未加载

            Logger::info(QString("Adding root node: %1, hasChildren: %2").arg(path).arg(rootNode["hasChildren"].toBool()));

            m_treeResult.append(rootNode);
        } else {
            Logger::info(QString("Skipping non-existent path: %1").arg(path));
        }
    }

    Logger::info(QString("First level tree built with %1 nodes").arg(m_treeResult.size()));
    emit treeResultChanged();
}

// 获取指定路径的子节点
QVariant ScanManager::getChildren(const QString &path) {
    Logger::info(QString("Getting children for path: %1").arg(path));

    if (m_pathChildrenMap.contains(path)) {
        QVariantList children = m_pathChildrenMap[path];
        Logger::info(QString("Found %1 children for path: %2").arg(children.size()).arg(path));
        return children;
    }

    // 如果没有找到，尝试直接扫描这个目录获取子节点
    QDir dir(path);
    if (dir.exists()) {
        QVariantList children;
        QFileInfoList entries = dir.entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot, QDir::DirsFirst);
        Logger::info(QString("Directly scanning directory: %1, found %2 entries").arg(path).arg(entries.size()));

        for (const QFileInfo &info : entries) {
            QVariantMap node;
            node["name"] = info.fileName();
            node["path"] = info.absoluteFilePath();
            node["isDir"] = info.isDir();
            node["size"] = info.isDir() ? 0 : info.size();
            node["expanded"] = false;
            node["hasChildren"] = info.isDir(); // 目录可能有子节点
            node["childrenLoaded"] = false; // 标记子节点尚未加载

            children.append(node);

            // 同时添加到映射中，方便后续使用
            if (!m_pathChildrenMap.contains(path)) {
                m_pathChildrenMap[path] = QVariantList();
            }
            m_pathChildrenMap[path] = children;
        }

        Logger::info(QString("Direct scan found %1 children for path: %2").arg(children.size()).arg(path));
        return children;
    }

    Logger::info(QString("No children found for path: %1").arg(path));
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
    m_pathChildrenMap.clear();
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

        for (const QString &path : kScanPaths) {
            if (!m_scanning) break;
            scanDirectory(path);
            currentDir++;

            // 使用 QMetaObject::invokeMethod 在主线程中更新进度
            QMetaObject::invokeMethod(this, [this, currentDir, totalDirs]() {
                m_progress = (qreal)currentDir / totalDirs;
                emit progressChanged();
                emit scanProgress(static_cast<int>(m_progress * 100), m_scannedFiles);
            }, Qt::QueuedConnection);
        }

        // 扫描完成,在主线程中更新状态和发送结果
        QMetaObject::invokeMethod(this, [this]() {
            m_progress = 1.0;
            emit progressChanged();
            emit scanProgress(100, m_scannedFiles);
            m_scanning = false;

            // 构建第一层树结构
            buildFirstLevelTree();

            QVariantList resultList;
            for (const auto &item : m_scanResult) {
                QVariantMap map;
                map["path"] = item.path;
                map["isDir"] = item.isDir;
                map["size"] = item.size;
                resultList.append(map);
            }
            emit scanFinished(resultList);
            emit scanResultChanged();
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

QVariant ScanManager::scanResult() const {
    // 返回 QVariantList，便于 QML 访问
    QVariantList resultList;
    for (const auto &item : m_scanResult) {
        QVariantMap map;
        map["path"] = item.path;
        map["isDir"] = item.isDir;
        map["size"] = item.size;
        resultList.append(map);
    }
    return resultList;
}

// 返回树状结构的第一层数据
QVariant ScanManager::treeResult() const {
    Logger::info(QString("Returning tree result with %1 nodes").arg(m_treeResult.size()));
    return m_treeResult;
}

// 私有成员变量
typedef struct {
    qreal m_progress;
    int m_scannedFiles;
    int m_scannedDirs;
    bool m_scanning;
} ScanManagerPrivate;