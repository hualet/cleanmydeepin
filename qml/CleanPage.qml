import QtQuick 2.15
import QtQuick.Controls 2.15
import "components" // 确保 FileTreeItem.qml 在 qml/components 目录下

Item {
    id: cleanPage


    // 树形结构数据
    property var treeData: []

    // 将扁平扫描结果转为树形结构
    function buildTree(flatList) {
        var rootNodes = []
        var pathMap = {}
        for (var i = 0; i < flatList.length; ++i) {
            var item = flatList[i]
            var parts = item.path.split("/")
            var name = parts.pop()
            var parentPath = parts.join("/") || "/"
            var node = {
                name: name,
                path: item.path,
                isDir: item.isDir,
                size: item.size,
                children: [],
                expanded: false
            }
            pathMap[item.path] = node
            if (parentPath === "" || parentPath === "/") {
                rootNodes.push(node)
            } else {
                if (pathMap[parentPath]) {
                    pathMap[parentPath].children.push(node)
                } else {
                    // 父节点还没出现，先创建一个占位
                    pathMap[parentPath] = {
                        name: parentPath.split("/").pop(),
                        path: parentPath,
                        isDir: true,
                        size: 0,
                        children: [node],
                        expanded: false
                    }
                    rootNodes.push(pathMap[parentPath])
                }
            }
        }
        return rootNodes
    }

    // 树形文件视图
    Rectangle {
        id: treeView
        width: parent.width * 0.8
        height: parent.height * 0.5
        color: "#f0f0f0"
        // 使用 ScrollView 包裹，支持滚动
        ScrollView {
            anchors.fill: parent
            Column {
                id: fileTreeRoot
                Repeater {
                    model: cleanPage.treeData
                    FileTreeItem {
                        node: modelData
                        scaleFactor: parent ? parent.scaleFactor : 1
                    }
                }
            }
        }
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 40 * (parent ? parent.scaleFactor : 1)
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