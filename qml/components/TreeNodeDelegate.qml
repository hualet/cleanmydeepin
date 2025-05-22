import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: nodeDelegate
    width: parent.width
    height: itemHeight

    required property var node
    required property real scaleFactor
    property bool debug: false
    property int itemHeight: 32 * scaleFactor

    // 添加默认值
    property bool isSelected: node ? node.selected || false : false
    property bool isExpanded: node ? node.expanded || false : false
    property bool hasChildren: node ? (node.isDir && node.hasChildren) || false : false

    signal expanded(var node)
    signal selected(var node, bool checked)

    Rectangle {
        id: background
        height: itemHeight
        width: parent.width
        color: "#e0e0e0"
        radius: 4
        border.color: "#cccccc"
        border.width: 1
        opacity: 0.7

        Row {
            spacing: 8 * scaleFactor
            width: parent.width
            height: parent.height
            leftPadding: 8 * scaleFactor

            // 添加复选框
            CheckBox {
                width: 20 * scaleFactor
                height: 20 * scaleFactor
                anchors.verticalCenter: parent.verticalCenter
                checked: isSelected
                onCheckedChanged: {
                    if (node) {
                        nodeDelegate.selected(node, checked);
                    }
                }
            }

            // 展开/收起图标
            Item {
                width: 20 * scaleFactor
                height: 20 * scaleFactor
                visible: hasChildren
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: isExpanded ? "▼" : "▶"
                    color: "#333333"
                    font.pixelSize: 12 * scaleFactor
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (!hasChildren) return;
                        if (node) {
                            nodeDelegate.expanded(node);
                        }
                    }
                }
            }

            // 文件/文件夹图标
            Rectangle {
                width: 20 * scaleFactor
                height: 20 * scaleFactor
                radius: width / 2
                color: node && node.isDir ? "#4285F4" : "#34A853"
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: node && node.isDir ? "D" : "F"
                    color: "white"
                    font.pixelSize: 10 * scaleFactor
                    font.bold: true
                }
            }

            // 路径名
            Text {
                text: node ? node.name : "未知"
                width: parent.width - 160 * scaleFactor
                elide: Text.ElideMiddle
                font.pixelSize: 12 * scaleFactor
                color: "#333333"
                font.bold: node && node.isDir
                anchors.verticalCenter: parent.verticalCenter
            }

            // 大小（文件才显示）
            Text {
                visible: node && !node.isDir
                text: node && node.size > 0 ? (node.size / 1024).toFixed(1) + " KB" : ""
                font.pixelSize: 10 * scaleFactor
                width: 80 * scaleFactor
                horizontalAlignment: Text.AlignRight
                color: "#555555"
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}