#include "scanmanager.h"
#include "log/logger.h"
#include <QTimer>
#include <QVariant>
#include <QDir>
#include <QFileInfo>
#include <QString>
#include <QObject>

// 构造函数
ScanManager::ScanManager(QObject *parent)
    : QObject(parent), m_progress(0), m_scannedFiles(0), m_scannedDirs(0), m_scanning(false) {}

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

void ScanManager::scanDirectory(const QString &path) {
    if (!m_scanning) return;
    QDir dir(path);
    if (!dir.exists()) return;
    m_scannedDirs++;
    emit scannedDirsChanged();
    QFileInfoList entries = dir.entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::Hidden, QDir::DirsFirst);
    for (const QFileInfo &info : entries) {
        if (!m_scanning) return;
        ScanItem item;
        item.path = info.absoluteFilePath();
        item.isDir = info.isDir();
        item.size = info.isDir() ? 0 : info.size();
        m_scanResult.append(item);
        if (info.isDir()) {
            scanDirectory(info.absoluteFilePath());
        } else {
            m_scannedFiles++;
            emit scannedFilesChanged();
        }
    }
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

    emit progressChanged();
    emit scannedFilesChanged();
    emit scannedDirsChanged();

    // TODO(hualet): make it multi-thread
    QTimer::singleShot(0, this, [this]() {
        int totalDirs = kScanPaths.size();
        int currentDir = 0;
        for (const QString &path : kScanPaths) {
            if (!m_scanning) break;
            scanDirectory(path);
            currentDir++;
            m_progress = (qreal)currentDir / totalDirs;
            emit progressChanged();
            emit scanProgress(static_cast<int>(m_progress * 100), m_scannedFiles);
        }
        m_progress = 1.0;
        emit progressChanged();
        emit scanProgress(100, m_scannedFiles);
        m_scanning = false;
        QVariantList resultList;
        for (const auto &item : m_scanResult) {
            QVariantMap map;
            map["path"] = item.path;
            map["isDir"] = item.isDir;
            map["size"] = item.size;
            resultList.append(map);
        }
        emit scanFinished(resultList);
        Logger::info("Scan finished");
    });
}

// 停止扫描
void ScanManager::stopScan() {
    Logger::info("Scan interrupted by user");
    m_scanning = false;
}

// 私有成员变量
typedef struct {
    qreal m_progress;
    int m_scannedFiles;
    int m_scannedDirs;
    bool m_scanning;
} ScanManagerPrivate;