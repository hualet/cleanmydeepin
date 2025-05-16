#pragma once
#include <QObject>

// 清理管理器，负责垃圾文件清理
class CleanManager : public QObject {
    Q_OBJECT
public:
    explicit CleanManager(QObject *parent = nullptr);

    Q_INVOKABLE void startClean(const QVariant &selectedFiles);

signals:
    void cleanProgress(int percent, const QString &currentFile); // 清理进度信号
    void cleanFinished(int freedSpace, const QVariant &failedItems); // 清理完成信号
};