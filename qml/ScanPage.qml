import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: scanPage
    width: parent ? parent.width : 800
    height: parent ? parent.height : 600

    // 扫描按钮
    Button {
        id: scanBtn
        text: qsTr("Scan")
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 80 * (parent ? parent.scaleFactor : 1)
        onClicked: ScanManager.startScan()
        ToolTip.text: qsTr("Start scanning for junk files")
    }

    // 进度条
    ProgressBar {
        id: progressBar
        width: parent.width * 0.6
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: scanBtn.bottom
        anchors.topMargin: 40 * (parent ? parent.scaleFactor : 1)
        value: 0 // TODO: 绑定进度
    }

    // 状态文本
    Text {
        id: statusText
        text: qsTr("Ready to scan.")
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: progressBar.bottom
        anchors.topMargin: 20 * (parent ? parent.scaleFactor : 1)
    }

    // 中断按钮
    Button {
        id: stopBtn
        text: qsTr("Interrupt")
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: statusText.bottom
        anchors.topMargin: 30 * (parent ? parent.scaleFactor : 1)
        onClicked: ScanManager.stopScan()
        ToolTip.text: qsTr("Interrupt scanning process")
    }
}