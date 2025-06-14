import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import "." // 导入当前目录下的组件

ApplicationWindow {
    id: mainWindow
    width: 400
    height: 600
    visible: true
    title: qsTr("CleanMyDeepin")

    // 限制窗口大小
    minimumWidth: width
    maximumWidth: width
    minimumHeight: height
    maximumHeight: height

    // 高分屏缩放支持
    property real scaleFactor: Screen.pixelDensity / 2.0

    Component {
        id: scanPage

        ScanPage {
            progress: ScanManager ? ScanManager.progress : 0
            scannedFiles: ScanManager ? ScanManager.scannedFiles : 0
            scannedDirs: ScanManager ? ScanManager.scannedDirs : 0
        }
    }

    Component {
        id: cleanPage

        CleanPage {
            id: cleanPageInstance
        }
    }

    Connections {
        target: ScanManager
        function onScanFinished() {
            console.log("MainWindow: Scan finished, navigating to clean page")
            pageStack.push(cleanPage)
        }
    }

    StackView {
        id: pageStack
        initialItem: scanPage
        anchors.fill: parent
    }
}