#include "scanmanager.h"
#include "log/logger.h"

// 构造函数
ScanManager::ScanManager(QObject *parent) : QObject(parent) {}

// 启动扫描
void ScanManager::startScan() {
    Logger::info("Scan started");
    // TODO: 实现异步扫描逻辑
}

// 停止扫描
void ScanManager::stopScan() {
    Logger::info("Scan interrupted by user");
    // TODO: 实现中断逻辑
}