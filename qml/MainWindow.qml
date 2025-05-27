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
        id: homePage
        Item {

            Button {
                text: qsTr("Scan")
                anchors.centerIn: parent
                onClicked: {
                    console.log("Starting scan")
                    ScanManager.startScan()
                    pageStack.push(scanPage)
                }
            }
        }
    }

    Component {
        id: scanPage

        ScanPage {
            progress: ScanManager.progress
            scannedFiles: ScanManager.scannedFiles
            scannedDirs: ScanManager.scannedDirs
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
        initialItem: homePage
        anchors.fill: parent
    }
}