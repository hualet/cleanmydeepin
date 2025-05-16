#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "core/scanmanager.h"
#include "core/cleanmanager.h"
#include "core/configmanager.h"
#include "core/translator.h"
#include "log/logger.h"

// 主程序入口
int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // 日志初始化
    Logger::init();

    // 国际化
    Translator translator;
    translator.init(&app);

    // QML 引擎
    QQmlApplicationEngine engine;

    // 后端管理器注册
    ScanManager scanManager;
    CleanManager cleanManager;
    ConfigManager configManager;

    engine.rootContext()->setContextProperty("ScanManager", &scanManager);
    engine.rootContext()->setContextProperty("CleanManager", &cleanManager);
    engine.rootContext()->setContextProperty("ConfigManager", &configManager);
    engine.rootContext()->setContextProperty("Translator", &translator);

    // 加载 QML
    engine.load(QUrl(QStringLiteral("qrc:/qml/MainWindow.qml")));

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}