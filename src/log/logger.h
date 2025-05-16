#pragma once
#include <QString>

// 日志模块，统一日志接口
class Logger {
public:
    static void init();
    static void info(const QString &msg);
    static void warn(const QString &msg);
    static void error(const QString &msg);
};