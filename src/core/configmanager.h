#pragma once
#include <QObject>

// 配置管理器，负责配置项管理
class ConfigManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool autoStart READ autoStart WRITE setAutoStart NOTIFY autoStartChanged)
public:
    explicit ConfigManager(QObject *parent = nullptr);

    bool autoStart() const;
    void setAutoStart(bool value);

signals:
    void autoStartChanged(); // 开机自启配置变更信号
};