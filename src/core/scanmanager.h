#ifndef SCANMANAGER_H
#define SCANMANAGER_H

#include <QObject>
#include <QString>
#include <QVariant>
#include <QList>

// 扫描管理器，负责垃圾文件扫描
class ScanManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(qreal progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(int scannedFiles READ scannedFiles NOTIFY scannedFilesChanged)
    Q_PROPERTY(int scannedDirs READ scannedDirs NOTIFY scannedDirsChanged)
    Q_PROPERTY(QVariant treeResult READ treeResult NOTIFY treeResultChanged)

public:
    // 扫描项结构体
    struct ScanItem {
        QString name;         // 文件/目录名
        QString path;         // 绝对路径
        bool isDir;          // 是否为目录
        qint64 size;         // 文件大小（目录为0或统计值）
        QList<ScanItem> children; // 子节点（仅目录有，文件为空）
    };

    explicit ScanManager(QObject *parent = nullptr);

    qreal progress() const;
    int scannedFiles() const;
    int scannedDirs() const;
    QVariant treeResult() const;
    QVariant scanResult() const;

    // 扫描目录常量
    static const QStringList kScanPaths;

public slots:
    void startScan();
    void stopScan();
    QVariant getChildren(const QString &path);

signals:
    void progressChanged();
    void scannedFilesChanged();
    void scannedDirsChanged();
    void treeResultChanged();
    void scanResultChanged();
    void scanProgress(int progress, int filesCount);
    void scanFinished(const QVariant &result);

private:
    void scanDirectory(const QString &path, ScanItem &parentItem);
    QVariantMap itemToVariantMap(const ScanItem &item);

    qreal m_progress;
    int m_scannedFiles;
    int m_scannedDirs;
    bool m_scanning;
    QList<ScanItem> m_scanResult;
    QVariantList m_treeResult;
};

#endif // SCANMANAGER_H