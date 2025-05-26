#include <QtTest/QtTest>
#include <QObject>
#include <QSignalSpy>
#include <QSettings>
#include <QStandardPaths>
#include <QDir>
#include "configmanager.h"

class TestConfigManager : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase();
    void cleanupTestCase();
    void init();
    void cleanup();

    // 基础功能测试
    void testInitialState();
    void testAutoStartProperty();
    void testAutoStartSignal();

    // 配置持久化测试
    void testConfigPersistence();
    void testMultipleInstances();

    // 边界条件测试
    void testInvalidConfigValues();
    void testConfigFileCorruption();

private:
    ConfigManager *m_configManager;
    QString m_testConfigPath;

    void clearTestConfig();
    void createCorruptedConfig();
};

void TestConfigManager::initTestCase()
{
    // 设置测试配置路径
    m_testConfigPath = QStandardPaths::writableLocation(QStandardPaths::TempLocation) + "/cleanmydeepin_test";
    QDir().mkpath(m_testConfigPath);

    // 设置测试环境的配置路径
    QSettings::setPath(QSettings::IniFormat, QSettings::UserScope, m_testConfigPath);

    qDebug() << "Test config directory:" << m_testConfigPath;
}

void TestConfigManager::cleanupTestCase()
{
    // 清理测试配置目录
    QDir testDir(m_testConfigPath);
    testDir.removeRecursively();
}

void TestConfigManager::init()
{
    clearTestConfig();
    m_configManager = new ConfigManager(this);
}

void TestConfigManager::cleanup()
{
    delete m_configManager;
    m_configManager = nullptr;
    clearTestConfig();
}

void TestConfigManager::clearTestConfig()
{
    // 清理测试配置文件
    QSettings settings("CleanMyDeepin", "CleanMyDeepin");
    settings.clear();
    settings.sync();
}

void TestConfigManager::createCorruptedConfig()
{
    // 创建损坏的配置文件
    QSettings settings("CleanMyDeepin", "CleanMyDeepin");
    QString configFile = settings.fileName();

    QFile file(configFile);
    if (file.open(QIODevice::WriteOnly)) {
        file.write("corrupted config data\n[invalid section\nkey=");
        file.close();
    }
}

void TestConfigManager::testInitialState()
{
    // 测试初始状态
    // 默认情况下，autoStart 应该为 false
    QCOMPARE(m_configManager->autoStart(), false);
}

void TestConfigManager::testAutoStartProperty()
{
    // 测试 autoStart 属性的设置和获取

    // 初始值应该为 false
    QCOMPARE(m_configManager->autoStart(), false);

    // 设置为 true
    m_configManager->setAutoStart(true);
    QCOMPARE(m_configManager->autoStart(), true);

    // 设置为 false
    m_configManager->setAutoStart(false);
    QCOMPARE(m_configManager->autoStart(), false);

    // 重复设置相同值
    m_configManager->setAutoStart(false);
    QCOMPARE(m_configManager->autoStart(), false);

    m_configManager->setAutoStart(true);
    QCOMPARE(m_configManager->autoStart(), true);

    m_configManager->setAutoStart(true);
    QCOMPARE(m_configManager->autoStart(), true);
}

void TestConfigManager::testAutoStartSignal()
{
    // 测试 autoStartChanged 信号
    QSignalSpy autoStartSpy(m_configManager, &ConfigManager::autoStartChanged);

    // 初始状态，没有信号
    QCOMPARE(autoStartSpy.count(), 0);

    // 设置为 true，应该发射信号
    m_configManager->setAutoStart(true);
    QCOMPARE(autoStartSpy.count(), 1);

    // 设置为相同值，不应该发射信号
    m_configManager->setAutoStart(true);
    QCOMPARE(autoStartSpy.count(), 1);

    // 设置为 false，应该发射信号
    m_configManager->setAutoStart(false);
    QCOMPARE(autoStartSpy.count(), 2);

    // 再次设置为 false，不应该发射信号
    m_configManager->setAutoStart(false);
    QCOMPARE(autoStartSpy.count(), 2);

    // 设置为 true，应该发射信号
    m_configManager->setAutoStart(true);
    QCOMPARE(autoStartSpy.count(), 3);
}

void TestConfigManager::testConfigPersistence()
{
    // 测试配置的持久化

    // 设置配置值
    m_configManager->setAutoStart(true);
    QCOMPARE(m_configManager->autoStart(), true);

    // 删除当前实例
    delete m_configManager;
    m_configManager = nullptr;

    // 创建新实例，应该加载之前保存的配置
    m_configManager = new ConfigManager(this);
    QCOMPARE(m_configManager->autoStart(), true);

    // 修改配置
    m_configManager->setAutoStart(false);
    QCOMPARE(m_configManager->autoStart(), false);

    // 再次重新创建实例
    delete m_configManager;
    m_configManager = new ConfigManager(this);
    QCOMPARE(m_configManager->autoStart(), false);
}

void TestConfigManager::testMultipleInstances()
{
    // 测试多个实例之间的配置同步

    // 创建第二个实例
    ConfigManager *secondManager = new ConfigManager(this);

    // 初始状态应该相同
    QCOMPARE(m_configManager->autoStart(), secondManager->autoStart());

    // 在第一个实例中修改配置
    m_configManager->setAutoStart(true);

    // 第二个实例应该仍然是旧值（因为没有自动同步机制）
    QCOMPARE(secondManager->autoStart(), false);

    // 删除并重新创建第二个实例，应该获取新值
    delete secondManager;
    secondManager = new ConfigManager(this);
    QCOMPARE(secondManager->autoStart(), true);

    // 在第二个实例中修改配置
    QSignalSpy firstSpy(m_configManager, &ConfigManager::autoStartChanged);
    QSignalSpy secondSpy(secondManager, &ConfigManager::autoStartChanged);

    secondManager->setAutoStart(false);

    // 验证信号只在修改的实例中发射
    QCOMPARE(firstSpy.count(), 0);
    QCOMPARE(secondSpy.count(), 1);

    // 验证值
    QCOMPARE(m_configManager->autoStart(), true);  // 第一个实例保持旧值
    QCOMPARE(secondManager->autoStart(), false);   // 第二个实例是新值

    delete secondManager;
}

void TestConfigManager::testInvalidConfigValues()
{
    // 测试无效配置值的处理

    // 直接修改配置文件，设置无效值
    QSettings settings("CleanMyDeepin", "CleanMyDeepin");
    settings.setValue("autoStart", "invalid_boolean_value");
    settings.sync();

    // 创建新实例，应该使用默认值
    delete m_configManager;
    m_configManager = new ConfigManager(this);

    // 应该使用默认值 false
    QCOMPARE(m_configManager->autoStart(), false);

    // 设置有效值应该正常工作
    m_configManager->setAutoStart(true);
    QCOMPARE(m_configManager->autoStart(), true);
}

void TestConfigManager::testConfigFileCorruption()
{
    // 测试配置文件损坏的处理

    // 创建损坏的配置文件
    createCorruptedConfig();

    // 创建新实例，应该能够处理损坏的配置文件
    delete m_configManager;
    m_configManager = new ConfigManager(this);

    // 应该使用默认值
    QCOMPARE(m_configManager->autoStart(), false);

    // 设置新值应该正常工作
    QSignalSpy autoStartSpy(m_configManager, &ConfigManager::autoStartChanged);
    m_configManager->setAutoStart(true);

    QCOMPARE(autoStartSpy.count(), 1);
    QCOMPARE(m_configManager->autoStart(), true);

    // 重新创建实例，应该能够正常加载
    delete m_configManager;
    m_configManager = new ConfigManager(this);
    QCOMPARE(m_configManager->autoStart(), true);
}

QTEST_MAIN(TestConfigManager)
#include "test_configmanager.moc"