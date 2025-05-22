import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15

Item {
    id: scanPage

    property real scaleFactor: Screen.pixelDensity / 6.0
    property real progress: ScanManager.progress
    property int scannedFiles: ScanManager.scannedFiles
    property int scannedDirs: ScanManager.scannedDirs
    property bool scanning: false

    // 扫描按钮
    Button {
        id: scanButton
        width: 160 * scaleFactor
        height: 40 * scaleFactor
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.2

        text: scanning ? qsTr("停止扫描") : qsTr("开始扫描")
        ToolTip.text: scanning ? qsTr("停止当前扫描任务") : qsTr("开始扫描垃圾文件")

        background: Rectangle {
            radius: 4
            color: scanning ? "#dc3545" : "#0D6EFD"
            opacity: parent.pressed ? 0.8 : 1.0
        }

        contentItem: Text {
            text: parent.text
            color: "white"
            font.pixelSize: 16 * scaleFactor
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        onClicked: {
            if (scanning) {
                ScanManager.stopScan();
                scanning = false;
            } else {
                ScanManager.startScan();
                scanning = true;
            }
        }
    }

    // 进度条和状态信息容器
    Rectangle {
        id: progressContainer
        width: parent.width * 0.8
        height: 120 * scaleFactor
        radius: 8
        color: "#f8f9fa"
        border.color: "#dee2e6"
        border.width: 1

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: scanButton.bottom
        anchors.topMargin: 40 * scaleFactor

        // 进度条
        ProgressBar {
            id: progressBar
            width: parent.width * 0.9
            height: 8 * scaleFactor
            value: progress

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 20 * scaleFactor

            background: Rectangle {
                color: "#e9ecef"
                radius: 4
            }

            contentItem: Item {
                Rectangle {
                    width: progressBar.visualPosition * parent.width
                    height: parent.height
                    radius: 4
                    color: "#0D6EFD"
                }
            }
        }

        // 状态文本
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: progressBar.bottom
            anchors.topMargin: 20 * scaleFactor
            spacing: 10 * scaleFactor

            Text {
                text: scanning ? qsTr("正在扫描...") : qsTr("等待开始扫描")
                color: "#212529"
                font.pixelSize: 14 * scaleFactor
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                text: qsTr("已扫描 %1 个目录、%2 个文件").arg(scannedDirs).arg(scannedFiles)
                color: "#6c757d"
                font.pixelSize: 12 * scaleFactor
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    // 扫描路径列表
    Rectangle {
        id: pathListContainer
        width: parent.width * 0.8
        height: parent.height * 0.3
        radius: 8
        color: "#f8f9fa"
        border.color: "#dee2e6"
        border.width: 1

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: progressContainer.bottom
        anchors.topMargin: 20 * scaleFactor

        Column {
            anchors.fill: parent
            anchors.margins: 15 * scaleFactor
            spacing: 5 * scaleFactor

            Text {
                text: qsTr("扫描路径")
                font.pixelSize: 14 * scaleFactor
                font.bold: true
                color: "#212529"
            }

            Repeater {
                model: ListModel {
                    ListElement { path: "/tmp" }
                    ListElement { path: "/var/tmp" }
                    ListElement { path: "/var/log" }
                    ListElement { path: "~/.cache" }
                    ListElement { path: "~/.local/share/Trash" }
                    ListElement { path: "~/.thumbnails" }
                }
                delegate: Text {
                    text: model.path
                    font.pixelSize: 12 * scaleFactor
                    color: "#6c757d"
                }
            }
        }
    }

    // 监听扫描状态变化
    Connections {
        target: ScanManager
        function onScanFinished() {
            scanning = false;
        }
    }
}