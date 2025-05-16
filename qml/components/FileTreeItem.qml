import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: fileTreeItem
    property var node
    property real scaleFactor: 1
    // 节点高度
    height: 32 * scaleFactor

    Row {
        spacing: 8 * scaleFactor
        // 展开/收起按钮（仅目录显示）
        Button {
            visible: node.isDir && node.children && node.children.length > 0
            text: node.expanded ? "▼" : "▶"
            ToolTip.text: qsTr("Expand/Collapse")
            onClicked: node.expanded = !node.expanded
            anchors.verticalCenter: parent.verticalCenter
        }
        // 文件/文件夹图标
        Image {
            source: node.isDir ? "qrc:/icons/folder.svg" : "qrc:/icons/file.svg"
            width: 20 * scaleFactor
            height: 20 * scaleFactor
            anchors.verticalCenter: parent.verticalCenter
        }
        // 路径名
        Text {
            text: node.name
            font.pixelSize: 14 * scaleFactor
            anchors.verticalCenter: parent.verticalCenter
        }
        // 大小（文件才显示）
        Text {
            visible: !node.isDir
            text: node.size > 0 ? (node.size / 1024).toFixed(1) + " KB" : ""
            font.pixelSize: 12 * scaleFactor
            color: "#888"
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    // 子节点递归渲染
    Column {
        visible: node.isDir && node.children && node.children.length > 0 && node.expanded
        anchors.leftMargin: 24 * scaleFactor
        Repeater {
            model: node.children ? node.children : []
            Loader {
                sourceComponent: FileTreeItem
                property var node: modelData
                property real scaleFactor: fileTreeItem.scaleFactor
            }
        }
    }
}