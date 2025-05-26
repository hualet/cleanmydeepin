# CleanMyDeepin 单元测试文档

本目录包含 CleanMyDeepin 项目的完整单元测试套件，专注于测试 MVC 架构中的 C（Controller）层实现。

## 测试架构

### 测试覆盖范围

根据 [DESIGN.md](../docs/DESIGN.md) 中的架构设计，我们为以下核心模块提供了全面的单元测试：

1. **ScanManager** - 扫描管理器
2. **CleanManager** - 清理管理器
3. **ConfigManager** - 配置管理器
4. **Logger** - 日志模块
5. **Integration** - 集成测试

### 测试文件结构

```
tests/
├── CMakeLists.txt          # 测试构建配置
├── README.md               # 本文档
├── run_tests.sh            # 测试运行脚本
├── testdata/               # 测试数据目录
│   ├── README.md
│   └── sample_files/
├── test_scanmanager.cpp    # ScanManager 单元测试
├── test_cleanmanager.cpp   # CleanManager 单元测试
├── test_configmanager.cpp  # ConfigManager 单元测试
├── test_logger.cpp         # Logger 单元测试
└── test_integration.cpp    # 集成测试
```

## 测试模块详解

### 1. ScanManager 测试 (`test_scanmanager.cpp`)

**测试范围：**
- 基础功能：初始状态、扫描路径配置、数据结构转换
- 扫描功能：信号发射、进度报告、停止扫描
- 数据结构：ScanItem 结构体、树形结果格式
- 边界条件：不存在目录、权限拒绝、大型目录结构

**关键测试用例：**
- `testInitialState()` - 验证初始状态
- `testScanPaths()` - 验证扫描路径常量
- `testStartScanSignals()` - 验证扫描信号发射
- `testGetChildrenWithFiles()` - 验证子节点获取
- `testLargeDirectoryStructure()` - 性能测试

### 2. CleanManager 测试 (`test_cleanmanager.cpp`)

**测试范围：**
- 基础功能：空列表清理、单文件清理、多文件清理、目录清理
- 信号测试：进度信号、完成信号
- 错误处理：不存在文件、权限拒绝、无效输入
- 边界条件：大文件、大量文件、嵌套目录

**关键测试用例：**
- `testStartCleanSingleFile()` - 单文件清理
- `testStartCleanMultipleFiles()` - 多文件清理
- `testCleanProgressSignal()` - 进度信号验证
- `testCleanNonExistentFile()` - 错误处理
- `testCleanLargeFile()` - 大文件处理

### 3. ConfigManager 测试 (`test_configmanager.cpp`)

**测试范围：**
- 基础功能：属性设置、信号发射
- 持久化：配置保存、多实例同步
- 边界条件：无效值、文件损坏

**关键测试用例：**
- `testAutoStartProperty()` - 属性设置测试
- `testAutoStartSignal()` - 信号发射测试
- `testConfigPersistence()` - 持久化测试
- `testInvalidConfigValues()` - 无效值处理

### 4. Logger 测试 (`test_logger.cpp`)

**测试范围：**
- 基础功能：不同级别日志记录
- 日志格式：时间戳、级别标识
- 边界条件：空消息、长消息、特殊字符、并发记录
- 文件操作：文件创建、权限验证

**关键测试用例：**
- `testInfoLogging()` - 信息日志测试
- `testLogFormat()` - 日志格式测试
- `testConcurrentLogging()` - 并发日志测试
- `testSpecialCharacters()` - 特殊字符处理

### 5. 集成测试 (`test_integration.cpp`)

**测试范围：**
- 扫描-清理工作流程
- 配置管理集成
- 日志记录集成
- 错误处理和恢复
- 性能和并发测试

**关键测试用例：**
- `testScanAndCleanWorkflow()` - 完整工作流程
- `testConfigPersistenceAcrossModules()` - 跨模块配置
- `testErrorHandlingAcrossModules()` - 跨模块错误处理
- `testLargeScaleWorkflow()` - 大规模性能测试

## 运行测试

### 快速运行

```bash
# 使用提供的脚本
cd tests
./run_tests.sh
```

### 手动运行

```bash
# 创建构建目录
mkdir -p tests/build
cd tests/build

# 配置和编译
cmake ..
make

# 运行所有测试
ctest

# 运行特定测试
./test_scanmanager
./test_cleanmanager
./test_configmanager
./test_logger
./test_integration
```

### 详细输出

```bash
# 运行测试并显示详细输出
ctest --verbose

# 或者直接运行测试可执行文件
./test_scanmanager -v2
```

## 测试数据

测试使用临时目录和文件，确保：
- 不会影响系统文件
- 测试后自动清理
- 可重复运行

测试数据包括：
- 临时文件和目录结构
- 模拟的垃圾文件
- 配置文件示例
- 日志文件示例

## 测试原则

### 1. 隔离性
- 每个测试独立运行
- 使用临时目录避免冲突
- 测试前后状态清理

### 2. 可重复性
- 测试结果一致
- 不依赖外部状态
- 确定性的测试数据

### 3. 全面性
- 覆盖正常流程
- 覆盖异常情况
- 覆盖边界条件

### 4. 性能考虑
- 测试执行时间合理
- 大型测试有超时设置
- 内存使用监控

## 持续集成

测试设计支持 CI/CD 集成：

```yaml
# 示例 CI 配置
test:
  script:
    - cd tests
    - ./run_tests.sh
  artifacts:
    reports:
      junit: tests/build/test_results.xml
```

## 故障排除

### 常见问题

1. **编译错误**
   - 检查 Qt6 依赖是否安装
   - 确认 CMake 版本 >= 3.14

2. **测试失败**
   - 检查文件权限
   - 确认临时目录可写
   - 查看详细错误输出

3. **性能测试超时**
   - 调整超时设置
   - 检查系统负载
   - 减少测试数据规模

### 调试技巧

```bash
# 运行单个测试并显示详细输出
./test_scanmanager -v2

# 使用 GDB 调试
gdb ./test_scanmanager
(gdb) run

# 检查内存泄漏
valgrind --leak-check=full ./test_scanmanager
```

## 扩展测试

### 添加新测试

1. 在相应的测试文件中添加新的测试方法
2. 遵循现有的命名约定
3. 添加适当的文档注释
4. 确保测试的隔离性

### 添加新测试模块

1. 创建新的测试文件 `test_newmodule.cpp`
2. 在 `CMakeLists.txt` 中添加测试目标
3. 更新 `run_tests.sh` 脚本
4. 添加相应的文档

## 测试指标

目标测试覆盖率：
- 行覆盖率：> 90%
- 分支覆盖率：> 85%
- 函数覆盖率：> 95%

可以使用 gcov/lcov 生成覆盖率报告：

```bash
# 编译时启用覆盖率
cmake .. -DCMAKE_BUILD_TYPE=Debug -DCMAKE_CXX_FLAGS="--coverage"
make

# 运行测试
ctest

# 生成覆盖率报告
lcov --capture --directory . --output-file coverage.info
genhtml coverage.info --output-directory coverage_report
```

## 贡献指南

在提交代码时，请确保：
1. 所有现有测试通过
2. 新功能有相应的测试
3. 测试覆盖率不降低
4. 遵循项目的编码规范

---

**注意**: 本测试套件是根据项目的核心设计文档创建的，专注于验证 C++ 后端的业务逻辑正确性。测试的设计遵循了项目的架构约束和模块职责边界。