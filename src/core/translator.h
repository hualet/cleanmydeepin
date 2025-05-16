#pragma once
#include <QObject>
#include <QTranslator>

// 翻译管理器，负责多语言切换
class Translator : public QObject {
    Q_OBJECT
public:
    explicit Translator(QObject *parent = nullptr);
    void init(QCoreApplication *app);

    Q_INVOKABLE void switchLanguage(const QString &lang);
};