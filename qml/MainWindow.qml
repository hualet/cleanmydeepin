import QtQuick 2.15
import QtQuick.Controls 2.15

ApplicationWindow {
    id: mainWindow
    width: 1200
    height: 800
    visible: true
    title: qsTr("CleanMyDeepin")

    // 高分屏缩放支持
    property real scaleFactor: Screen.pixelDensity / 2.0

    // 左侧标签栏
    Drawer {
        id: navDrawer
        width: 200 * mainWindow.scaleFactor
        // TODO: 添加标签按钮，tooltip 说明，国际化
    }

    // 右侧页面内容
    StackView {
        id: pageStack
        anchors.fill: parent
        // TODO: 页面切换逻辑
    }
}