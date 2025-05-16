#pragma once
#include <QObject>

// 扫描管理器，负责垃圾文件扫描
class ScanManager : public QObject {
    Q_OBJECT
public:
    explicit ScanManager(QObject *parent = nullptr);

    Q_INVOKABLE void startScan();
    Q_INVOKABLE void stopScan();

signals:
    void scanProgress(int percent, int fileCount); // 扫描进度信号
    void scanFinished(const QVariant &result);     // 扫描完成信号
    void scanInterrupted();                        // 扫描中断信号
};