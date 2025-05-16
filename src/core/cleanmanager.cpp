#include "cleanmanager.h"
#include "log/logger.h"

// 构造函数
CleanManager::CleanManager(QObject *parent) : QObject(parent) {}

// 启动清理
void CleanManager::startClean(const QVariant &selectedFiles) {
    Logger::info("Clean started");
    // TODO: 实现异步清理逻辑
}