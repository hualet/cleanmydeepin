cmake_minimum_required(VERSION 3.14)

# 查找 Qt Test 模块
find_package(Qt6 COMPONENTS Test Core Gui Qml REQUIRED)

# 启用测试
enable_testing()

# 包含源代码目录
include_directories(../src ../src/core ../src/log)

# 源文件列表（排除 main.cpp）
set(CORE_SOURCES
    ../src/core/scanmanager.cpp
    ../src/core/cleanmanager.cpp
    ../src/core/configmanager.cpp
    ../src/core/translator.cpp
    ../src/log/logger.cpp
)

set(CORE_HEADERS
    ../src/core/scanmanager.h
    ../src/core/cleanmanager.h
    ../src/core/configmanager.h
    ../src/core/translator.h
    ../src/log/logger.h
)

# 创建测试辅助库
add_library(CleanMyDeepinCore STATIC
    ${CORE_SOURCES}
    ${CORE_HEADERS}
)

target_link_libraries(CleanMyDeepinCore
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
)

# 测试宏函数
function(add_unit_test test_name test_source)
    add_executable(${test_name} ${test_source})
    target_link_libraries(${test_name}
        Qt6::Test
        Qt6::Core
        Qt6::Gui
        Qt6::Qml
        CleanMyDeepinCore
    )
    add_test(NAME ${test_name} COMMAND ${test_name})
    set_target_properties(${test_name} PROPERTIES
        AUTOMOC ON
    )
endfunction()

# 添加各个测试
add_unit_test(test_scanmanager test_scanmanager.cpp)
add_unit_test(test_cleanmanager test_cleanmanager.cpp)
add_unit_test(test_configmanager test_configmanager.cpp)
add_unit_test(test_logger test_logger.cpp)

# 集成测试
add_unit_test(test_integration test_integration.cpp)

# 测试数据目录
file(COPY testdata DESTINATION ${CMAKE_CURRENT_BINARY_DIR})