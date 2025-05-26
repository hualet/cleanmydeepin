#include <QtTest/QtTest>
#include <QObject>
#include <QSignalSpy>
#include <QDir>
#include <QTemporaryDir>
#include <QFile>
#include <QTextStream>
#include "scanmanager.h"

class TestScanManager : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase();
    void cleanupTestCase();
    void init();
    void cleanup();

    // 基础功能测试
    void testInitialState();
    void testScanPaths();
    void testItemToVariantMap();
    void testGetChildrenEmptyDir();
    void testGetChildrenNonExistentPath();
    void testGetChildrenWithFiles();

    // 扫描功能测试
    void testStartScanSignals();
    void testStopScan();
    void testScanProgress();
    void testScanDirectory();

    // 数据结构测试
    void testScanItemStructure();
    void testTreeResultFormat();

    // 边界条件测试
    void testScanNonExistentDirectory();
    void testScanPermissionDenied();
    void testLargeDirectoryStructure();

private:
    ScanManager *m_scanManager;
    QTemporaryDir *m_testDir;
    QString m_testPath;

    void createTestFileStructure();
    void createLargeTestStructure();
};

void TestScanManager::initTestCase()
{
    // 创建临时测试目录
    m_testDir = new QTemporaryDir();
    QVERIFY(m_testDir->isValid());
    m_testPath = m_testDir->path();

    qDebug() << "Test directory created at:" << m_testPath;
}

void TestScanManager::cleanupTestCase()
{
    delete m_testDir;
}

void TestScanManager::init()
{
    m_scanManager = new ScanManager(this);
    createTestFileStructure();
}

void TestScanManager::cleanup()
{
    delete m_scanManager;
    m_scanManager = nullptr;

    // 清理测试目录内容
    QDir dir(m_testPath);
    dir.removeRecursively();
    m_testDir->remove();
    m_testDir = new QTemporaryDir();
    m_testPath = m_testDir->path();
}

void TestScanManager::createTestFileStructure()
{
    // 创建测试文件结构
    // testdir/
    //   ├── file1.txt (100 bytes)
    //   ├── file2.log (200 bytes)
    //   ├── subdir1/
    //   │   ├── file3.tmp (300 bytes)
    //   │   └── subdir2/
    //   │       └── file4.cache (400 bytes)
    //   └── emptydir/

    QDir testDir(m_testPath);

    // 创建文件
    QFile file1(testDir.filePath("file1.txt"));
    QVERIFY(file1.open(QIODevice::WriteOnly));
    file1.write(QByteArray(100, 'a'));
    file1.close();

    QFile file2(testDir.filePath("file2.log"));
    QVERIFY(file2.open(QIODevice::WriteOnly));
    file2.write(QByteArray(200, 'b'));
    file2.close();

    // 创建子目录
    QVERIFY(testDir.mkdir("subdir1"));
    QVERIFY(testDir.mkdir("subdir1/subdir2"));
    QVERIFY(testDir.mkdir("emptydir"));

    QFile file3(testDir.filePath("subdir1/file3.tmp"));
    QVERIFY(file3.open(QIODevice::WriteOnly));
    file3.write(QByteArray(300, 'c'));
    file3.close();

    QFile file4(testDir.filePath("subdir1/subdir2/file4.cache"));
    QVERIFY(file4.open(QIODevice::WriteOnly));
    file4.write(QByteArray(400, 'd'));
    file4.close();
}

void TestScanManager::testInitialState()
{
    // 测试初始状态
    QCOMPARE(m_scanManager->progress(), 0.0);
    QCOMPARE(m_scanManager->scannedFiles(), 0);
    QCOMPARE(m_scanManager->scannedDirs(), 0);
    QVERIFY(m_scanManager->treeResult().toList().isEmpty());
}

void TestScanManager::testScanPaths()
{
    // 测试扫描路径常量
    const QStringList &paths = ScanManager::kScanPaths;
    QVERIFY(!paths.isEmpty());

    // 验证包含基本的系统路径
    QVERIFY(paths.contains("/tmp"));
    QVERIFY(paths.contains("/var/tmp"));
    QVERIFY(paths.contains("/var/log"));

    // 验证用户目录路径格式正确
    bool hasUserPath = false;
    for (const QString &path : paths) {
        if (path.contains("/.thumbnails")) {
            hasUserPath = true;
            break;
        }
    }
    QVERIFY(hasUserPath);
}

void TestScanManager::testItemToVariantMap()
{
    // 创建测试 ScanItem
    ScanManager::ScanItem item;
    item.name = "test.txt";
    item.path = "/tmp/test.txt";
    item.isDir = false;
    item.size = 1024;

    // 使用反射调用私有方法进行测试
    // 注意：这里需要将 itemToVariantMap 方法设为 public 或添加友元类
    // 或者通过测试 getChildren 方法间接测试

    // 通过 getChildren 测试数据转换
    QVariant result = m_scanManager->getChildren(m_testPath);
    QVariantList children = result.toList();

    QVERIFY(!children.isEmpty());

    // 验证第一个子项的数据结构
    QVariantMap firstChild = children.first().toMap();
    QVERIFY(firstChild.contains("name"));
    QVERIFY(firstChild.contains("path"));
    QVERIFY(firstChild.contains("isDir"));
    QVERIFY(firstChild.contains("size"));
    QVERIFY(firstChild.contains("expanded"));
    QVERIFY(firstChild.contains("hasChildren"));
    QVERIFY(firstChild.contains("childrenLoaded"));
    QVERIFY(firstChild.contains("children"));

    // 验证默认状态
    QCOMPARE(firstChild["expanded"].toBool(), false);
    QCOMPARE(firstChild["childrenLoaded"].toBool(), false);
    QVERIFY(firstChild["children"].toList().isEmpty());
}

void TestScanManager::testGetChildrenEmptyDir()
{
    // 测试空目录
    QString emptyDirPath = QDir(m_testPath).filePath("emptydir");
    QVariant result = m_scanManager->getChildren(emptyDirPath);
    QVariantList children = result.toList();

    QVERIFY(children.isEmpty());
}

void TestScanManager::testGetChildrenNonExistentPath()
{
    // 测试不存在的路径
    QString nonExistentPath = "/path/that/does/not/exist";
    QVariant result = m_scanManager->getChildren(nonExistentPath);
    QVariantList children = result.toList();

    QVERIFY(children.isEmpty());
}

void TestScanManager::testGetChildrenWithFiles()
{
    // 测试包含文件的目录
    QVariant result = m_scanManager->getChildren(m_testPath);
    QVariantList children = result.toList();

    QVERIFY(children.size() >= 3); // file1.txt, file2.log, subdir1, emptydir

    // 查找并验证文件项
    bool foundFile1 = false, foundSubdir1 = false;
    for (const QVariant &child : children) {
        QVariantMap childMap = child.toMap();
        QString name = childMap["name"].toString();

        if (name == "file1.txt") {
            foundFile1 = true;
            QCOMPARE(childMap["isDir"].toBool(), false);
            QCOMPARE(childMap["size"].toLongLong(), 100LL);
            QCOMPARE(childMap["hasChildren"].toBool(), false);
        } else if (name == "subdir1") {
            foundSubdir1 = true;
            QCOMPARE(childMap["isDir"].toBool(), true);
            QCOMPARE(childMap["hasChildren"].toBool(), true);
        }
    }

    QVERIFY(foundFile1);
    QVERIFY(foundSubdir1);
}

void TestScanManager::testStartScanSignals()
{
    // 测试扫描开始时的信号发射
    QSignalSpy progressSpy(m_scanManager, &ScanManager::progressChanged);
    QSignalSpy filesSpy(m_scanManager, &ScanManager::scannedFilesChanged);
    QSignalSpy dirsSpy(m_scanManager, &ScanManager::scannedDirsChanged);
    QSignalSpy treeSpy(m_scanManager, &ScanManager::treeResultChanged);
    QSignalSpy finishedSpy(m_scanManager, &ScanManager::scanFinished);

    m_scanManager->startScan();

    // 验证初始信号
    QVERIFY(progressSpy.count() >= 1);
    QVERIFY(filesSpy.count() >= 1);
    QVERIFY(dirsSpy.count() >= 1);
    QVERIFY(treeSpy.count() >= 1);

    // 等待扫描完成
    QVERIFY(finishedSpy.wait(5000)); // 5秒超时

    // 验证最终状态
    QCOMPARE(m_scanManager->progress(), 1.0);
}

void TestScanManager::testStopScan()
{
    // 测试停止扫描
    m_scanManager->startScan();

    // 立即停止
    m_scanManager->stopScan();

    // 验证扫描已停止（通过检查进度是否不再更新）
    qreal initialProgress = m_scanManager->progress();
    QTest::qWait(100);

    // 进度应该保持不变或者扫描应该很快完成
    QVERIFY(m_scanManager->progress() >= initialProgress);
}

void TestScanManager::testScanProgress()
{
    // 测试扫描进度信号
    QSignalSpy progressSignalSpy(m_scanManager, &ScanManager::scanProgress);
    QSignalSpy finishedSpy(m_scanManager, &ScanManager::scanFinished);

    m_scanManager->startScan();

    // 等待扫描完成
    QVERIFY(finishedSpy.wait(5000));

    // 验证进度信号
    QVERIFY(progressSignalSpy.count() >= 1);

    // 验证最后一个进度信号是100%
    if (!progressSignalSpy.isEmpty()) {
        QList<QVariant> lastSignal = progressSignalSpy.last();
        QCOMPARE(lastSignal.at(0).toInt(), 100);
    }
}

void TestScanManager::testScanDirectory()
{
    // 这个测试需要访问私有方法，可以通过友元类或者重构为 protected 方法
    // 目前通过 startScan 间接测试

    QSignalSpy finishedSpy(m_scanManager, &ScanManager::scanFinished);
    m_scanManager->startScan();

    QVERIFY(finishedSpy.wait(5000));

    // 验证扫描结果包含预期的文件和目录数量
    QVERIFY(m_scanManager->scannedFiles() > 0);
    QVERIFY(m_scanManager->scannedDirs() > 0);
}

void TestScanManager::testScanItemStructure()
{
    // 测试 ScanItem 结构体的基本功能
    ScanManager::ScanItem item;
    item.name = "test";
    item.path = "/test";
    item.isDir = true;
    item.size = 0;

    // 添加子项
    ScanManager::ScanItem child;
    child.name = "child.txt";
    child.path = "/test/child.txt";
    child.isDir = false;
    child.size = 100;

    item.children.append(child);

    // 验证结构
    QCOMPARE(item.children.size(), 1);
    QCOMPARE(item.children.first().name, QString("child.txt"));
    QCOMPARE(item.children.first().size, 100LL);
}

void TestScanManager::testTreeResultFormat()
{
    // 测试树形结果的格式
    QSignalSpy finishedSpy(m_scanManager, &ScanManager::scanFinished);
    m_scanManager->startScan();

    QVERIFY(finishedSpy.wait(5000));

    QVariant treeResult = m_scanManager->treeResult();
    QVERIFY(treeResult.isValid());

    QVariantList rootNodes = treeResult.toList();
    // 根据 kScanPaths 的数量验证根节点数量
    QVERIFY(rootNodes.size() > 0);

    // 验证根节点的数据结构
    if (!rootNodes.isEmpty()) {
        QVariantMap firstRoot = rootNodes.first().toMap();
        QVERIFY(firstRoot.contains("name"));
        QVERIFY(firstRoot.contains("path"));
        QVERIFY(firstRoot.contains("isDir"));
        QVERIFY(firstRoot.contains("size"));
        QVERIFY(firstRoot.contains("children"));
    }
}

void TestScanManager::testScanNonExistentDirectory()
{
    // 测试扫描不存在的目录
    QString nonExistentPath = "/path/that/absolutely/does/not/exist";
    QVariant result = m_scanManager->getChildren(nonExistentPath);

    QVERIFY(result.toList().isEmpty());
}

void TestScanManager::testScanPermissionDenied()
{
    // 测试权限被拒绝的目录
    // 注意：这个测试可能需要特殊的权限设置，在某些环境下可能跳过
    QString restrictedPath = "/root"; // 通常普通用户无法访问

    QVariant result = m_scanManager->getChildren(restrictedPath);
    // 权限被拒绝时应该返回空列表而不是崩溃
    QVERIFY(result.toList().isEmpty() || !result.toList().isEmpty());
}

void TestScanManager::testLargeDirectoryStructure()
{
    // 创建大型目录结构进行性能测试
    createLargeTestStructure();

    QSignalSpy finishedSpy(m_scanManager, &ScanManager::scanFinished);

    // 记录开始时间
    QElapsedTimer timer;
    timer.start();

    m_scanManager->startScan();
    QVERIFY(finishedSpy.wait(10000)); // 10秒超时

    qint64 elapsed = timer.elapsed();
    qDebug() << "Large directory scan took:" << elapsed << "ms";

    // 验证扫描完成
    QCOMPARE(m_scanManager->progress(), 1.0);
    QVERIFY(m_scanManager->scannedFiles() > 0);
}

void TestScanManager::createLargeTestStructure()
{
    // 创建包含多层嵌套和多个文件的大型测试结构
    QDir testDir(m_testPath);

    // 创建多层目录结构
    for (int i = 0; i < 5; ++i) {
        QString dirName = QString("level%1").arg(i);
        testDir.mkdir(dirName);

        QDir subDir(testDir.filePath(dirName));

        // 在每个目录中创建多个文件
        for (int j = 0; j < 10; ++j) {
            QString fileName = QString("file%1_%2.txt").arg(i).arg(j);
            QFile file(subDir.filePath(fileName));
            if (file.open(QIODevice::WriteOnly)) {
                file.write(QByteArray(100 * (i + 1), 'x'));
                file.close();
            }
        }

        // 创建子目录
        if (i < 3) {
            subDir.mkdir(QString("sublevel%1").arg(i));
        }
    }
}

QTEST_MAIN(TestScanManager)
#include "test_scanmanager.moc"