cmake_minimum_required(VERSION 3.14)
project(CleanMyDeepin LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# 查找 Qt 包
find_package(Qt6 COMPONENTS Core Gui Qml Quick LinguistTools REQUIRED)

# 源文件
file(GLOB_RECURSE SOURCES
    src/*.cpp
)
file(GLOB_RECURSE HEADERS
    src/*.h
)

# 创建可执行文件
add_executable(${PROJECT_NAME}
    ${SOURCES}
    ${HEADERS}
)

# 设置输出文件名，避免与目录名冲突
set_target_properties(${PROJECT_NAME} PROPERTIES
    OUTPUT_NAME "cleanmydeepin"
)

target_include_directories(${PROJECT_NAME} PRIVATE src src/core src/log)

# QML 资源
qt_add_qml_module(${PROJECT_NAME}
    URI CleanMyDeepin
    QML_FILES
        qml/MainWindow.qml
        qml/ScanPage.qml
        qml/CleanPage.qml
        qml/SettingsPage.qml
        qml/HelpPage.qml
        qml/components/FileTreeItem.qml
    # 可添加更多 QML 组件
    RESOURCES
        # 可添加资源文件
)

# 统一使用关键字签名方式
target_link_libraries(${PROJECT_NAME} PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
)

# 安装规则
install(TARGETS ${PROJECT_NAME} DESTINATION bin)