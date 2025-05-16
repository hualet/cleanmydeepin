import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: cleanPage
    width: parent ? parent.width : 800
    height: parent ? parent.height : 600

    // 树形文件视图（占位）
    Rectangle {
        id: treeView
        width: parent.width * 0.8
        height: parent.height * 0.5
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 40 * (parent ? parent.scaleFactor : 1)
        color: "#f0f0f0"
        // TODO: 替换为真正的 TreeView 组件
        Text {
            anchors.centerIn: parent
            text: qsTr("File tree here")
        }
    }

    // 全选/反选按钮
    Row {
        spacing: 20 * (parent ? parent.scaleFactor : 1)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: treeView.bottom
        anchors.topMargin: 20 * (parent ? parent.scaleFactor : 1)
        Button {
            text: qsTr("Select All")
            ToolTip.text: qsTr("Select all items")
            // TODO: 绑定全选逻辑
        }
        Button {
            text: qsTr("Deselect All")
            ToolTip.text: qsTr("Deselect all items")
            // TODO: 绑定反选逻辑
        }
    }

    // 底部清理按钮
    Button {
        id: cleanBtn
        text: qsTr("Clean")
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 40 * (parent ? parent.scaleFactor : 1)
        ToolTip.text: qsTr("Clean selected files")
        // TODO: 绑定清理逻辑
    }
}