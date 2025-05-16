#include "scanmanager.h"
#include "log/logger.h"
#include <QTimer>
#include <QVariant>

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

// 启动扫描
void ScanManager::startScan() {
    Logger::info("Scan started");
    if (m_scanning) return;
    m_scanning = true;
    m_progress = 0;
    m_scannedFiles = 0;
    m_scannedDirs = 0;
    emit progressChanged();
    emit scannedFilesChanged();
    emit scannedDirsChanged();

    // 模拟异步扫描进度
    QTimer *timer = new QTimer(this);
    timer->setInterval(200);
    connect(timer, &QTimer::timeout, this, [this, timer]() {
        if (!m_scanning) {
            timer->stop();
            timer->deleteLater();
            emit scanInterrupted();
            Logger::info("Scan interrupted by user");
            return;
        }
        m_progress += 0.1;
        m_scannedFiles += 5;
        m_scannedDirs += 1;
        if (m_progress > 1.0) m_progress = 1.0;
        emit progressChanged();
        emit scannedFilesChanged();
        emit scannedDirsChanged();
        emit scanProgress(static_cast<int>(m_progress * 100), m_scannedFiles);
        if (m_progress >= 1.0) {
            timer->stop();
            timer->deleteLater();
            m_scanning = false;
            QVariant result; // TODO: 填充实际扫描结果
            emit scanFinished(result);
            Logger::info("Scan finished");
        }
    });
    timer->start();
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