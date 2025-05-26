#include <QtTest/QtTest>
#include <QObject>
#include <QSignalSpy>
#include <QDir>
#include <QTemporaryDir>
#include <QFile>
#include <QVariantList>
#include <QVariantMap>
#include "cleanmanager.h"

class TestCleanManager : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase();
    void cleanupTestCase();
    void init();
    void cleanup();

    // 基础功能测试
    void testInitialState();
    void testStartCleanEmptyList();
    void testStartCleanSingleFile();
    void testStartCleanMultipleFiles();
    void testStartCleanDirectory();

    // 信号测试
    void testCleanProgressSignal();
    void testCleanFinishedSignal();

    // 错误处理测试
    void testCleanNonExistentFile();
    void testCleanPermissionDenied();
    void testCleanInvalidInput();

    // 边界条件测试
    void testCleanLargeFile();
    void testCleanManyFiles();
    void testCleanNestedDirectories();

private:
    CleanManager *m_cleanManager;
    QTemporaryDir *m_testDir;
    QString m_testPath;

    void createTestFiles();
    QVariantList createFileList(const QStringList &paths);
    void createLargeTestFile(const QString &path, qint64 size);
};

void TestCleanManager::initTestCase()
{
    // 创建临时测试目录
    m_testDir = new QTemporaryDir();
    QVERIFY(m_testDir->isValid());
    m_testPath = m_testDir->path();

    qDebug() << "Test directory created at:" << m_testPath;
}

void TestCleanManager::cleanupTestCase()
{
    delete m_testDir;
}

void TestCleanManager::init()
{
    m_cleanManager = new CleanManager(this);
    createTestFiles();
}

void TestCleanManager::cleanup()
{
    delete m_cleanManager;
    m_cleanManager = nullptr;

    // 清理测试目录内容
    QDir dir(m_testPath);
    dir.removeRecursively();
    m_testDir->remove();
    m_testDir = new QTemporaryDir();
    m_testPath = m_testDir->path();
}

void TestCleanManager::createTestFiles()
{
    // 创建测试文件结构
    QDir testDir(m_testPath);

    // 创建普通文件
    QFile file1(testDir.filePath("test1.txt"));
    QVERIFY(file1.open(QIODevice::WriteOnly));
    file1.write("Test content 1");
    file1.close();

    QFile file2(testDir.filePath("test2.log"));
    QVERIFY(file2.open(QIODevice::WriteOnly));
    file2.write("Test content 2");
    file2.close();

    // 创建子目录和文件
    QVERIFY(testDir.mkdir("subdir"));
    QFile file3(testDir.filePath("subdir/test3.tmp"));
    QVERIFY(file3.open(QIODevice::WriteOnly));
    file3.write("Test content 3");
    file3.close();

    // 创建空目录
    QVERIFY(testDir.mkdir("emptydir"));
}

QVariantList TestCleanManager::createFileList(const QStringList &paths)
{
    QVariantList fileList;
    for (const QString &path : paths) {
        QVariantMap fileItem;
        fileItem["path"] = path;
        fileItem["isDir"] = QFileInfo(path).isDir();
        fileItem["size"] = QFileInfo(path).size();
        fileList.append(fileItem);
    }
    return fileList;
}

void TestCleanManager::createLargeTestFile(const QString &path, qint64 size)
{
    QFile file(path);
    if (file.open(QIODevice::WriteOnly)) {
        // 创建指定大小的文件
        QByteArray data(1024, 'X'); // 1KB 块
        qint64 written = 0;
        while (written < size) {
            qint64 toWrite = qMin(static_cast<qint64>(data.size()), size - written);
            file.write(data.left(toWrite));
            written += toWrite;
        }
        file.close();
    }
}

void TestCleanManager::testInitialState()
{
    // 测试初始状态
    // CleanManager 没有公开的状态属性，主要通过信号测试
    QVERIFY(m_cleanManager != nullptr);
}

void TestCleanManager::testStartCleanEmptyList()
{
    // 测试清理空列表
    QSignalSpy progressSpy(m_cleanManager, &CleanManager::cleanProgress);
    QSignalSpy finishedSpy(m_cleanManager, &CleanManager::cleanFinished);

    QVariantList emptyList;
    m_cleanManager->startClean(emptyList);

    // 等待完成信号
    QVERIFY(finishedSpy.wait(1000));

    // 验证结果
    QCOMPARE(finishedSpy.count(), 1);
    QList<QVariant> finishedArgs = finishedSpy.first();
    QCOMPARE(finishedArgs.at(0).toInt(), 0); // 释放空间为0
    QVERIFY(finishedArgs.at(1).toList().isEmpty()); // 没有失败项
}

void TestCleanManager::testStartCleanSingleFile()
{
    // 测试清理单个文件
    QString filePath = QDir(m_testPath).filePath("test1.txt");
    QVERIFY(QFile::exists(filePath));

    qint64 originalSize = QFileInfo(filePath).size();

    QSignalSpy progressSpy(m_cleanManager, &CleanManager::cleanProgress);
    QSignalSpy finishedSpy(m_cleanManager, &CleanManager::cleanFinished);

    QVariantList fileList = createFileList({filePath});
    m_cleanManager->startClean(fileList);

    // 等待完成信号
    QVERIFY(finishedSpy.wait(2000));

    // 验证文件已被删除
    QVERIFY(!QFile::exists(filePath));

    // 验证信号
    QCOMPARE(finishedSpy.count(), 1);
    QList<QVariant> finishedArgs = finishedSpy.first();
    QVERIFY(finishedArgs.at(0).toInt() >= originalSize); // 释放的空间应该至少等于文件大小
    QVERIFY(finishedArgs.at(1).toList().isEmpty()); // 没有失败项
}

void TestCleanManager::testStartCleanMultipleFiles()
{
    // 测试清理多个文件
    QStringList filePaths = {
        QDir(m_testPath).filePath("test1.txt"),
        QDir(m_testPath).filePath("test2.log"),
        QDir(m_testPath).filePath("subdir/test3.tmp")
    };

    // 验证文件存在
    for (const QString &path : filePaths) {
        QVERIFY(QFile::exists(path));
    }

    qint64 totalSize = 0;
    for (const QString &path : filePaths) {
        totalSize += QFileInfo(path).size();
    }

    QSignalSpy progressSpy(m_cleanManager, &CleanManager::cleanProgress);
    QSignalSpy finishedSpy(m_cleanManager, &CleanManager::cleanFinished);

    QVariantList fileList = createFileList(filePaths);
    m_cleanManager->startClean(fileList);

    // 等待完成信号
    QVERIFY(finishedSpy.wait(3000));

    // 验证文件已被删除
    for (const QString &path : filePaths) {
        QVERIFY(!QFile::exists(path));
    }

    // 验证进度信号
    QVERIFY(progressSpy.count() >= 1);

    // 验证完成信号
    QCOMPARE(finishedSpy.count(), 1);
    QList<QVariant> finishedArgs = finishedSpy.first();
    QVERIFY(finishedArgs.at(0).toInt() >= totalSize);
    QVERIFY(finishedArgs.at(1).toList().isEmpty());
}

void TestCleanManager::testStartCleanDirectory()
{
    // 测试清理目录
    QString dirPath = QDir(m_testPath).filePath("subdir");
    QVERIFY(QDir(dirPath).exists());

    QSignalSpy progressSpy(m_cleanManager, &CleanManager::cleanProgress);
    QSignalSpy finishedSpy(m_cleanManager, &CleanManager::cleanFinished);

    QVariantList dirList = createFileList({dirPath});
    m_cleanManager->startClean(dirList);

    // 等待完成信号
    QVERIFY(finishedSpy.wait(3000));

    // 验证目录已被删除
    QVERIFY(!QDir(dirPath).exists());

    // 验证信号
    QCOMPARE(finishedSpy.count(), 1);
    QList<QVariant> finishedArgs = finishedSpy.first();
    QVERIFY(finishedArgs.at(0).toInt() >= 0); // 释放了一些空间
}

void TestCleanManager::testCleanProgressSignal()
{
    // 测试进度信号的正确性
    QStringList filePaths = {
        QDir(m_testPath).filePath("test1.txt"),
        QDir(m_testPath).filePath("test2.log")
    };

    QSignalSpy progressSpy(m_cleanManager, &CleanManager::cleanProgress);
    QSignalSpy finishedSpy(m_cleanManager, &CleanManager::cleanFinished);

    QVariantList fileList = createFileList(filePaths);
    m_cleanManager->startClean(fileList);

    QVERIFY(finishedSpy.wait(3000));

    // 验证进度信号
    QVERIFY(progressSpy.count() >= 1);

    // 检查进度信号的参数
    for (int i = 0; i < progressSpy.count(); ++i) {
        QList<QVariant> progressArgs = progressSpy.at(i);
        QCOMPARE(progressArgs.size(), 2);

        int percent = progressArgs.at(0).toInt();
        QString currentFile = progressArgs.at(1).toString();

        // 进度应该在 0-100 之间
        QVERIFY(percent >= 0 && percent <= 100);
        // 当前文件路径不应该为空
        QVERIFY(!currentFile.isEmpty());
    }
}

void TestCleanManager::testCleanFinishedSignal()
{
    // 测试完成信号的正确性
    QString filePath = QDir(m_testPath).filePath("test1.txt");
    qint64 fileSize = QFileInfo(filePath).size();

    QSignalSpy finishedSpy(m_cleanManager, &CleanManager::cleanFinished);

    QVariantList fileList = createFileList({filePath});
    m_cleanManager->startClean(fileList);

    QVERIFY(finishedSpy.wait(2000));

    // 验证完成信号参数
    QCOMPARE(finishedSpy.count(), 1);
    QList<QVariant> finishedArgs = finishedSpy.first();
    QCOMPARE(finishedArgs.size(), 2);

    int freedSpace = finishedArgs.at(0).toInt();
    QVariantList failedItems = finishedArgs.at(1).toList();

    // 释放空间应该大于等于文件大小
    QVERIFY(freedSpace >= fileSize);
    // 没有失败项
    QVERIFY(failedItems.isEmpty());
}

void TestCleanManager::testCleanNonExistentFile()
{
    // 测试清理不存在的文件
    QString nonExistentPath = QDir(m_testPath).filePath("nonexistent.txt");
    QVERIFY(!QFile::exists(nonExistentPath));

    QSignalSpy finishedSpy(m_cleanManager, &CleanManager::cleanFinished);

    QVariantList fileList = createFileList({nonExistentPath});
    m_cleanManager->startClean(fileList);

    QVERIFY(finishedSpy.wait(2000));

    // 验证结果
    QList<QVariant> finishedArgs = finishedSpy.first();
    int freedSpace = finishedArgs.at(0).toInt();
    QVariantList failedItems = finishedArgs.at(1).toList();

    // 释放空间应该为0
    QCOMPARE(freedSpace, 0);
    // 应该有一个失败项
    QCOMPARE(failedItems.size(), 1);

    // 验证失败项的内容
    QVariantMap failedItem = failedItems.first().toMap();
    QCOMPARE(failedItem["path"].toString(), nonExistentPath);
}

void TestCleanManager::testCleanPermissionDenied()
{
    // 测试权限被拒绝的情况
    // 创建一个只读文件
    QString readOnlyPath = QDir(m_testPath).filePath("readonly.txt");
    QFile readOnlyFile(readOnlyPath);
    QVERIFY(readOnlyFile.open(QIODevice::WriteOnly));
    readOnlyFile.write("readonly content");
    readOnlyFile.close();

    // 设置为只读
    QVERIFY(readOnlyFile.setPermissions(QFile::ReadOwner | QFile::ReadGroup | QFile::ReadOther));

    QSignalSpy finishedSpy(m_cleanManager, &CleanManager::cleanFinished);

    QVariantList fileList = createFileList({readOnlyPath});
    m_cleanManager->startClean(fileList);

    QVERIFY(finishedSpy.wait(2000));

    // 验证结果 - 可能成功也可能失败，取决于具体实现
    QList<QVariant> finishedArgs = finishedSpy.first();
    QVariantList failedItems = finishedArgs.at(1).toList();

    // 如果删除失败，应该在失败列表中
    if (!QFile::exists(readOnlyPath)) {
        // 删除成功
        QVERIFY(failedItems.isEmpty());
    } else {
        // 删除失败
        QCOMPARE(failedItems.size(), 1);
    }
}

void TestCleanManager::testCleanInvalidInput()
{
    // 测试无效输入
    QSignalSpy finishedSpy(m_cleanManager, &CleanManager::cleanFinished);

    // 测试无效的 QVariant
    QVariant invalidInput = QString("invalid");
    m_cleanManager->startClean(invalidInput);

    QVERIFY(finishedSpy.wait(1000));

    // 应该快速完成，没有释放空间
    QList<QVariant> finishedArgs = finishedSpy.first();
    QCOMPARE(finishedArgs.at(0).toInt(), 0);
}

void TestCleanManager::testCleanLargeFile()
{
    // 测试清理大文件
    QString largeFilePath = QDir(m_testPath).filePath("largefile.dat");
    qint64 largeFileSize = 10 * 1024 * 1024; // 10MB

    createLargeTestFile(largeFilePath, largeFileSize);
    QVERIFY(QFile::exists(largeFilePath));
    QVERIFY(QFileInfo(largeFilePath).size() >= largeFileSize);

    QSignalSpy progressSpy(m_cleanManager, &CleanManager::cleanProgress);
    QSignalSpy finishedSpy(m_cleanManager, &CleanManager::cleanFinished);

    QVariantList fileList = createFileList({largeFilePath});
    m_cleanManager->startClean(fileList);

    // 大文件可能需要更长时间
    QVERIFY(finishedSpy.wait(10000));

    // 验证文件已删除
    QVERIFY(!QFile::exists(largeFilePath));

    // 验证释放的空间
    QList<QVariant> finishedArgs = finishedSpy.first();
    QVERIFY(finishedArgs.at(0).toLongLong() >= largeFileSize);
}

void TestCleanManager::testCleanManyFiles()
{
    // 测试清理大量文件
    QStringList manyFiles;
    QDir testDir(m_testPath);

    // 创建100个小文件
    for (int i = 0; i < 100; ++i) {
        QString fileName = QString("manyfile_%1.txt").arg(i);
        QString filePath = testDir.filePath(fileName);

        QFile file(filePath);
        QVERIFY(file.open(QIODevice::WriteOnly));
        file.write(QString("Content of file %1").arg(i).toUtf8());
        file.close();

        manyFiles.append(filePath);
    }

    QSignalSpy progressSpy(m_cleanManager, &CleanManager::cleanProgress);
    QSignalSpy finishedSpy(m_cleanManager, &CleanManager::cleanFinished);

    QVariantList fileList = createFileList(manyFiles);
    m_cleanManager->startClean(fileList);

    QVERIFY(finishedSpy.wait(10000));

    // 验证所有文件都被删除
    for (const QString &filePath : manyFiles) {
        QVERIFY(!QFile::exists(filePath));
    }

    // 验证进度信号数量合理
    QVERIFY(progressSpy.count() >= 1);
    QVERIFY(progressSpy.count() <= 100); // 不应该超过文件数量
}

void TestCleanManager::testCleanNestedDirectories()
{
    // 测试清理嵌套目录结构
    QDir testDir(m_testPath);

    // 创建嵌套目录结构
    QString nestedPath = "nested/level1/level2/level3";
    QVERIFY(testDir.mkpath(nestedPath));

    // 在各级目录中创建文件
    QStringList filesToCreate = {
        "nested/file1.txt",
        "nested/level1/file2.txt",
        "nested/level1/level2/file3.txt",
        "nested/level1/level2/level3/file4.txt"
    };

    for (const QString &relativePath : filesToCreate) {
        QString fullPath = testDir.filePath(relativePath);
        QFile file(fullPath);
        QVERIFY(file.open(QIODevice::WriteOnly));
        file.write("nested content");
        file.close();
    }

    QSignalSpy finishedSpy(m_cleanManager, &CleanManager::cleanFinished);

    // 清理整个嵌套目录
    QString nestedDirPath = testDir.filePath("nested");
    QVariantList dirList = createFileList({nestedDirPath});
    m_cleanManager->startClean(dirList);

    QVERIFY(finishedSpy.wait(5000));

    // 验证整个目录结构都被删除
    QVERIFY(!QDir(nestedDirPath).exists());

    // 验证释放了空间
    QList<QVariant> finishedArgs = finishedSpy.first();
    QVERIFY(finishedArgs.at(0).toInt() > 0);
}

QTEST_MAIN(TestCleanManager)
#include "test_cleanmanager.moc"