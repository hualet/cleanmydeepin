#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include "core/scanmanager.h"
#include "core/cleanmanager.h"
#include "core/configmanager.h"
#include "core/translator.h"
#include "log/logger.h"

// 主程序入口
int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // 设置应用信息
    app.setOrganizationName("deepin");
    app.setApplicationName("CleanMyDeepin");

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

    // 加载 QML - 使用正确的URI格式
    engine.load(QUrl(QStringLiteral("qrc:/CleanMyDeepin/qml/MainWindow.qml")));

    if (engine.rootObjects().isEmpty()) {
        Logger::error("Failed to load QML file. Check QML import paths and file existence.");
        return -1;
    }

    return app.exec();
}