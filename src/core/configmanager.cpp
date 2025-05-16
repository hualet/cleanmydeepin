#include "configmanager.h"
#include "log/logger.h"

ConfigManager::ConfigManager(QObject *parent) : QObject(parent) {}

bool ConfigManager::autoStart() const {
    // TODO: 读取配置
    return false;
}

void ConfigManager::setAutoStart(bool value) {
    // TODO: 保存配置
    Logger::info(QString("Set autoStart: %1").arg(value));
    emit autoStartChanged();
}