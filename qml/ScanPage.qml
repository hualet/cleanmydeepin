import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: scanPage

    property real progress: 0
    property int scannedFiles: 0
    property int scannedDirs: 0

    // 进度条
    ProgressBar {
        id: progressBar
        width: parent.width * 0.6
        value: progress

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.3
    }

    // 状态文本
    Column {
        id: statusText
        width: parent.width * 0.6

        spacing: 10

        Text {
            text: qsTr("扫描中，已扫描文件：")
            color: "white"
        }

        Text {
            text: qsTr("%1 个目录、%2个文件").arg(scannedDirs).arg(scannedFiles)
            color: "white"
        }

        anchors.top: progressBar.bottom
        anchors.topMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter
    }

    // TODO(hualet): add log view and animation.
}