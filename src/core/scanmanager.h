#pragma once
#include <QObject>
#include <QString>
#include <QVector>
#include <QVariant>

// 扫描管理器，负责垃圾文件扫描
class ScanManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(qreal progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(int scannedFiles READ scannedFiles NOTIFY scannedFilesChanged)
    Q_PROPERTY(int scannedDirs READ scannedDirs NOTIFY scannedDirsChanged)
    Q_PROPERTY(QVariant scanResult READ scanResult NOTIFY scanResultChanged)
public:
    explicit ScanManager(QObject *parent = nullptr);

    Q_INVOKABLE void startScan();
    Q_INVOKABLE void stopScan();

    qreal progress() const;
    int scannedFiles() const;
    int scannedDirs() const;
    QVariant scanResult() const;

signals:
    void scanProgress(int percent, int fileCount); // 扫描进度信号
    void scanFinished(const QVariant &result);     // 扫描完成信号
    void scanInterrupted();                        // 扫描中断信号
    void progressChanged();                        // 进度属性变更信号
    void scannedFilesChanged();                    // 文件数属性变更信号
    void scannedDirsChanged();                     // 目录数属性变更信号
    void scanResultChanged();                        // 扫描结果属性变更信号
private:
    struct ScanItem {
        QString path;
        bool isDir;
        qint64 size;
    };
    qreal m_progress;
    int m_scannedFiles;
    int m_scannedDirs;
    bool m_scanning;
    QVector<ScanItem> m_scanResult;
    void scanDirectory(const QString &path);
    static const QStringList kScanPaths;
};