import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: settingsPage
    width: parent ? parent.width : 800
    height: parent ? parent.height : 600

    // 开机自启开关
    Row {
        spacing: 20 * (parent ? parent.scaleFactor : 1)
        anchors.top: parent.top
        anchors.topMargin: 60 * (parent ? parent.scaleFactor : 1)
        anchors.horizontalCenter: parent.horizontalCenter
        Text {
            text: qsTr("Auto Start")
        }
        Switch {
            checked: ConfigManager.autoStart
            onCheckedChanged: ConfigManager.setAutoStart(checked)
            ToolTip.text: qsTr("Enable or disable auto start")
        }
    }

    // 忽略目录/类型列表（占位）
    Rectangle {
        width: parent.width * 0.7
        height: 120 * (parent ? parent.scaleFactor : 1)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 140 * (parent ? parent.scaleFactor : 1)
        color: "#f0f0f0"
        Text {
            anchors.centerIn: parent
            text: qsTr("Ignore list here")
        }
    }

    // 保存按钮
    Button {
        text: qsTr("Save")
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 40 * (parent ? parent.scaleFactor : 1)
        ToolTip.text: qsTr("Save settings")
        // TODO: 绑定保存逻辑
    }
}