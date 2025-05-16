#include "logger.h"
#include <QDebug>

// 日志初始化
void Logger::init() {
    // 可扩展为文件日志
    qInfo() << "Logger initialized";
}

// 信息日志
void Logger::info(const QString &msg) {
    qInfo().noquote() << "[INFO]" << msg;
}

// 警告日志
void Logger::warn(const QString &msg) {
    qWarning().noquote() << "[WARN]" << msg;
}

// 错误日志
void Logger::error(const QString &msg) {
    qCritical().noquote() << "[ERROR]" << msg;
}