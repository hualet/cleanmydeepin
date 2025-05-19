import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: fileTreeItem
    property var node
    property real scaleFactor: 1
    // 节点高度
    height: 32 * scaleFactor

    // 添加调试属性
    property bool debug: false

    // 添加展开信号
    signal expanded(var node)

    // 初始化
    Component.onCompleted: {
        if (debug) {
            console.log("TreeItem created:", node ? node.name : "unknown",
                        "isDir:", node ? node.isDir : false,
                        "hasChildren:", node ? node.hasChildren : false)
        }
    }

    // 节点背景 - 添加背景以增强可见性
    Rectangle {
        id: itemBackground
        anchors.fill: parent
        color: "#e0e0e0"  // 浅灰色背景
        radius: 4
        border.color: "#cccccc"
        border.width: 1
        opacity: 0.7

        // 添加鼠标区域，使整个项目可点击
        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (node && node.isDir && node.hasChildren) {
                    node.expanded = !node.expanded;
                    if (node.expanded) {
                        if (debug) console.log("MouseArea: Expanding node:", node.path);
                        fileTreeItem.expanded(node);
                    } else {
                        if (debug) console.log("MouseArea: Collapsing node:", node.path);
                    }
                }
            }
        }
    }

    Row {
        spacing: 8 * scaleFactor
        width: parent.width
        height: parent.height
        leftPadding: 8 * scaleFactor

        // 展开/收起图标（不使用按钮，因为按钮可能有问题）
        Text {
            id: expandIcon
            visible: node && node.isDir && node.hasChildren
            width: 20 * scaleFactor
            height: 20 * scaleFactor
            text: node && node.expanded ? "▼" : "▶"
            color: "#333333"
            font.pixelSize: 12 * scaleFactor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
        }

        // 文件/文件夹图标
        Rectangle {
            width: 20 * scaleFactor
            height: 20 * scaleFactor
            radius: width / 2
            color: node && node.isDir ? "#4285F4" : "#34A853"  // 目录蓝色，文件绿色
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
            font.pixelSize: 12 * scaleFactor  // 减小字体大小
            color: "#333333"  // 深灰色文本
            font.bold: node && node.isDir
            anchors.verticalCenter: parent.verticalCenter
        }

        // 大小（文件才显示）
        Text {
            visible: node && !node.isDir
            text: node && node.size > 0 ? (node.size / 1024).toFixed(1) + " KB" : ""
            font.pixelSize: 10 * scaleFactor  // 减小字体大小
            width: 80 * scaleFactor
            horizontalAlignment: Text.AlignRight
            color: "#555555"  // 中灰色文本
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // 子节点递归渲染（只在加载了子节点并且展开的情况下显示）
    Column {
        id: childrenColumn
        visible: node && node.isDir && node.expanded && node.children && node.children.length > 0
        x: 24 * scaleFactor
        width: parent.width - x
        spacing: 2 * scaleFactor

        // 调试信息
        Text {
            visible: fileTreeItem.debug
            text: "Children: " + (node && node.children ? node.children.length : 0)
            font.pixelSize: 10 * scaleFactor
            color: "red"
        }

        Repeater {
            model: node && node.children ? node.children : []
            delegate: Loader {
                width: childrenColumn.width
                sourceComponent: FileTreeItem
                property var node: modelData
                property real scaleFactor: fileTreeItem.scaleFactor
                property bool debug: fileTreeItem.debug
            }
        }
    }
}