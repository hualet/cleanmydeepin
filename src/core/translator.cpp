#include "translator.h"
#include <QCoreApplication>
#include "log/logger.h"

Translator::Translator(QObject *parent) : QObject(parent) {}

void Translator::init(QCoreApplication *app) {
    // TODO: 加载默认语言
    Logger::info("Translator initialized");
}

void Translator::switchLanguage(const QString &lang) {
    // TODO: 切换语言
    Logger::info(QString("Switch language to: %1").arg(lang));
}