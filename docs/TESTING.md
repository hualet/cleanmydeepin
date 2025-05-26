# CleanMyDeepin 测试框架总结

本文档总结了为 CleanMyDeepin 项目创建的完整单元测试框架，重点覆盖 MVC 架构中的 C（Controller）层实现。

## 测试框架概述

### 设计原则

根据 [DESIGN.md](DESIGN.md) 中的核心架构设计，测试框架遵循以下原则：

1. **模块化测试** - 每个核心模块都有独立的测试套件
2. **架构边界尊重** - 测试严格遵循模块职责边界
3. **数据流验证** - 重点测试 C++ 到 QML 的数据转换
4. **信号槽机制** - 全面测试 Qt 信号槽通信
5. **异步操作** - 验证多线程和异步处理的正确性

### 测试覆盖矩阵

| 模块 | 功能测试 | 信号测试 | 错误处理 | 性能测试 | 集成测试 |
|------|----------|----------|----------|----------|----------|
| ScanManager | ✅ | ✅ | ✅ | ✅ | ✅ |
| CleanManager | ✅ | ✅ | ✅ | ✅ | ✅ |
| ConfigManager | ✅ | ✅ | ✅ | ❌ | ✅ |
| Logger | ✅ | ❌ | ✅ | ✅ | ✅ |

## 核心测试模块

### 1. ScanManager 测试

**测试重点：**
- 扫描路径常量验证
- 异步扫描流程
- 数据结构转换（C++ ScanItem ↔ QML QVariantMap）
- 树形数据的延迟加载
- 进度报告和信号发射

**关键验证点：**
```cpp
// 数据结构转换验证
QVariantMap itemMap = scanManager->itemToVariantMap(scanItem);
QVERIFY(itemMap.contains("name"));
QVERIFY(itemMap.contains("path"));
QVERIFY(itemMap.contains("isDir"));
QVERIFY(itemMap.contains("size"));

// 信号发射验证
QSignalSpy finishedSpy(scanManager, &ScanManager::scanFinished);
scanManager->startScan();
QVERIFY(finishedSpy.wait(5000));
```

### 2. CleanManager 测试

**测试重点：**
- 文件删除操作
- 进度报告机制
- 错误处理和失败项收集
- 批量操作性能

**关键验证点：**
```cpp
// 清理结果验证
QList<QVariant> cleanResult = cleanFinishedSpy.first();
int freedSpace = cleanResult.at(0).toInt();
QVariantList failedItems = cleanResult.at(1).toList();
QVERIFY(freedSpace > 0);
QVERIFY(!QFile::exists(testFilePath));
```

### 3. ConfigManager 测试

**测试重点：**
- Qt 属性系统集成
- 配置持久化
- 信号发射机制
- 多实例同步

**关键验证点：**
```cpp
// 属性绑定和信号测试
QSignalSpy autoStartSpy(configManager, &ConfigManager::autoStartChanged);
configManager->setAutoStart(true);
QCOMPARE(autoStartSpy.count(), 1);
QCOMPARE(configManager->autoStart(), true);
```

### 4. Logger 测试

**测试重点：**
- 多级别日志记录
- 线程安全性
- 特殊字符处理
- 并发访问

### 5. 集成测试

**测试重点：**
- 完整的扫描→清理工作流程
- 跨模块数据传递
- 错误传播和恢复
- 性能和内存使用

## 测试数据管理

### 临时目录策略

```cpp
// 每个测试使用独立的临时目录
QTemporaryDir *m_testDir = new QTemporaryDir();
QString m_testPath = m_testDir->path();

// 测试后自动清理
void cleanup() {
    QDir dir(m_testPath);
    dir.removeRecursively();
}
```

### 测试文件结构

```
临时测试目录/
├── tmp_simulation/          # 模拟临时文件
│   ├── temp_file_0.tmp
│   └── temp_file_1.tmp
├── log_simulation/          # 模拟日志文件
│   ├── app.log
│   └── error.log
└── cache_simulation/        # 模拟缓存文件
    ├── thumbnails/
    └── web_cache/
```

## 信号槽测试模式

### QSignalSpy 使用模式

```cpp
// 标准信号监听模式
QSignalSpy progressSpy(manager, &Manager::progressChanged);
QSignalSpy finishedSpy(manager, &Manager::operationFinished);

// 执行操作
manager->startOperation();

// 验证信号发射
QVERIFY(progressSpy.count() >= 1);
QVERIFY(finishedSpy.wait(5000));

// 验证信号参数
QList<QVariant> finishedArgs = finishedSpy.first();
QCOMPARE(finishedArgs.size(), 2);
```

### 异步操作测试

```cpp
// 异步操作测试模式
QSignalSpy finishedSpy(scanManager, &ScanManager::scanFinished);
scanManager->startScan();

// 等待异步操作完成
QVERIFY(finishedSpy.wait(10000)); // 10秒超时

// 验证最终状态
QCOMPARE(scanManager->progress(), 1.0);
```

## 错误处理测试

### 边界条件覆盖

1. **文件系统错误**
   - 不存在的路径
   - 权限拒绝
   - 磁盘空间不足

2. **数据格式错误**
   - 无效的 QVariant 数据
   - 损坏的配置文件
   - 空输入处理

3. **并发访问错误**
   - 多线程竞争
   - 信号槽连接问题
   - 资源锁定

### 错误恢复验证

```cpp
// 错误恢复测试模式
manager->startOperation();
manager->stopOperation(); // 中断操作

// 验证可以重新开始
QSignalSpy finishedSpy(manager, &Manager::operationFinished);
manager->startOperation();
QVERIFY(finishedSpy.wait(5000));
```

## 性能测试策略

### 大规模数据测试

```cpp
void createLargeTestStructure() {
    // 创建大量文件和目录
    for (int dir = 0; dir < 5; ++dir) {
        for (int file = 0; file < 50; ++file) {
            // 创建测试文件
        }
    }
}

void testLargeScaleWorkflow() {
    QElapsedTimer timer;
    timer.start();

    // 执行大规模操作
    manager->startOperation();

    qint64 elapsed = timer.elapsed();
    QVERIFY(elapsed < 30000); // 30秒内完成
}
```

### 内存使用监控

```cpp
void testMemoryUsageInWorkflow() {
    // 执行多次操作循环
    for (int cycle = 0; cycle < 3; ++cycle) {
        // 执行操作
        // 强制垃圾回收
        QCoreApplication::processEvents();
    }
    // 验证内存没有泄漏
}
```

## 构建和运行

### CMake 集成

```cmake
# 测试构建配置
find_package(Qt6 COMPONENTS Test REQUIRED)
enable_testing()

# 创建测试辅助库
add_library(CleanMyDeepinCore STATIC ${CORE_SOURCES})

# 添加测试目标
function(add_unit_test test_name test_source)
    add_executable(${test_name} ${test_source})
    target_link_libraries(${test_name} Qt6::Test CleanMyDeepinCore)
    add_test(NAME ${test_name} COMMAND ${test_name})
endfunction()
```

### 自动化脚本

```bash
#!/bin/bash
# 完整的测试运行流程
cmake .. -DCMAKE_BUILD_TYPE=Debug
make -j$(nproc)

# 运行所有测试
for test in test_*; do
    echo "Running $test..."
    ./$test || exit 1
done
```

## 持续集成支持

### CI/CD 配置示例

```yaml
test:
  stage: test
  script:
    - cd tests
    - ./run_tests.sh
  artifacts:
    reports:
      junit: tests/build/test_results.xml
    paths:
      - tests/build/coverage_report/
  coverage: '/lines......: \d+\.\d+%/'
```

### 覆盖率报告

```bash
# 生成覆盖率报告
cmake .. -DCMAKE_CXX_FLAGS="--coverage"
make && ctest
lcov --capture --directory . --output-file coverage.info
genhtml coverage.info --output-directory coverage_report
```

## 测试最佳实践

### 1. 测试命名约定

```cpp
class TestScanManager : public QObject {
    // 测试方法命名：test + 功能描述 + 测试场景
    void testStartScanSignals();           // 基础功能测试
    void testScanNonExistentDirectory();   // 边界条件测试
    void testLargeDirectoryStructure();    // 性能测试
};
```

### 2. 断言使用指南

```cpp
// 基础断言
QVERIFY(condition);                    // 布尔条件
QCOMPARE(actual, expected);            // 值比较
QVERIFY2(condition, "error message");  // 带错误信息

// 信号断言
QVERIFY(spy.wait(timeout));           // 等待信号
QCOMPARE(spy.count(), expectedCount); // 信号次数

// 异常断言
QVERIFY_EXCEPTION_THROWN(code, ExceptionType);
```

### 3. 测试数据管理

```cpp
// 测试数据创建
void createTestFileStructure() {
    // 创建确定性的测试数据
    // 使用相对路径
    // 控制文件大小
}

// 测试数据清理
void cleanup() {
    // 确保完全清理
    // 避免测试间干扰
}
```

## 故障排除指南

### 常见问题解决

1. **编译错误**
   ```bash
   # 检查 Qt6 安装
   pkg-config --modversion Qt6Core

   # 检查 CMake 版本
   cmake --version
   ```

2. **测试超时**
   ```cpp
   // 增加超时时间
   QVERIFY(spy.wait(30000)); // 30秒

   // 检查系统负载
   // 减少测试数据规模
   ```

3. **信号未发射**
   ```cpp
   // 检查信号连接
   QObject::connect(sender, &Sender::signal,
                   receiver, &Receiver::slot);

   // 使用 QSignalSpy 调试
   QSignalSpy spy(sender, &Sender::signal);
   ```

## 扩展和维护

### 添加新测试

1. 确定测试范围和目标
2. 选择合适的测试类别
3. 创建测试数据和环境
4. 编写测试用例
5. 验证测试覆盖率

### 维护现有测试

1. 定期运行测试套件
2. 更新测试数据
3. 优化测试性能
4. 修复失效的测试

---

## 总结

本测试框架为 CleanMyDeepin 项目提供了全面的单元测试覆盖，特别是针对 C++ 后端的核心业务逻辑。测试设计严格遵循项目的架构原则，确保了：

- **完整性** - 覆盖所有核心模块和关键功能
- **可靠性** - 稳定的测试环境和可重复的结果
- **可维护性** - 清晰的测试结构和文档
- **扩展性** - 易于添加新测试和模块

通过这个测试框架，开发团队可以：
- 及早发现和修复缺陷
- 确保代码重构的安全性
- 验证新功能的正确性
- 维护代码质量标准

测试框架的设计充分考虑了 Qt/QML 应用的特点，特别是信号槽机制、异步操作和数据绑定等方面，为项目的长期维护和发展提供了坚实的质量保障。