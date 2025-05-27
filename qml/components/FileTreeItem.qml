import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: fileTreeItem
    width: parent.width
    height: contentHeight

    property var node: null
    property real scaleFactor: 1
    property bool debug: false
    property int itemHeight: 32 * scaleFactor
    property int indentWidth: 24 * scaleFactor
    property int contentHeight: nodeDelegate.height + (childrenContainer.visible ? childrenContainer.height + (4 * scaleFactor) : 0)

    // 界面自行控制展开状态，不依赖数据中的 expanded 字段
    property bool isExpanded: false

    signal expanded(var node)
    signal selected(var node, bool checked)

    // 节点委托
    TreeNodeDelegate {
        id: nodeDelegate
        width: parent.width
        node: fileTreeItem.node
        scaleFactor: fileTreeItem.scaleFactor
        debug: fileTreeItem.debug
        // 传递界面控制的展开状态
        isExpanded: fileTreeItem.isExpanded

        onExpanded: function(expandedNode) {
            // 只更新界面状态，不修改数据中的 expanded 字段
            if (expandedNode === fileTreeItem.node) {
                fileTreeItem.isExpanded = !fileTreeItem.isExpanded;
                // 如果是展开操作且子节点未加载，则触发加载
                if (fileTreeItem.isExpanded && (!expandedNode.childrenLoaded || !expandedNode.children)) {
                    fileTreeItem.expanded(expandedNode);
                }
            }
        }
        onSelected: function(selectedNode, checked) {
            fileTreeItem.selected(selectedNode, checked);
        }
    }

    // 子节点容器
    Item {
        id: childrenContainer
        y: nodeDelegate.height + (4 * scaleFactor)
        x: indentWidth
        width: parent.width - x
        height: childrenColumn.height
        visible: {
            if (!node) return false;
            return fileTreeItem.isExpanded && node.children && node.children.length > 0;
        }

        Column {
            id: childrenColumn
            width: parent.width
            spacing: 4 * scaleFactor

            // 调试信息
            Text {
                visible: fileTreeItem.debug
                text: {
                    if (!node) return "";
                    return "Children count: " + (node.children ? node.children.length : 0) +
                           ", UI Expanded: " + fileTreeItem.isExpanded +
                           ", Loaded: " + (node.childrenLoaded || false);
                }
                font.pixelSize: 10 * scaleFactor
                color: "red"
            }

            // 子节点列表 - 直接使用 TreeNodeDelegate 避免递归
            Repeater {
                id: childRepeater
                model: node ? (node.children || []) : []

                Item {
                    width: childrenColumn.width
                    height: childNodeDelegate.height + (grandChildrenContainer.visible ? grandChildrenContainer.height + (4 * scaleFactor) : 0)

                    property bool childExpanded: false

                    TreeNodeDelegate {
                        id: childNodeDelegate
                        width: parent.width
                        node: modelData
                        scaleFactor: fileTreeItem.scaleFactor
                        debug: fileTreeItem.debug
                        isExpanded: parent.childExpanded

                        onExpanded: function(expandedNode) {
                            if (expandedNode === modelData) {
                                parent.childExpanded = !parent.childExpanded;
                                if (parent.childExpanded && (!expandedNode.childrenLoaded || !expandedNode.children)) {
                                    fileTreeItem.expanded(expandedNode);
                                }
                            }
                        }
                        onSelected: function(selectedNode, checked) {
                            fileTreeItem.selected(selectedNode, checked);
                        }
                    }

                    // 孙子节点容器（限制到三级避免过深嵌套）
                    Item {
                        id: grandChildrenContainer
                        y: childNodeDelegate.height + (4 * scaleFactor)
                        x: indentWidth
                        width: parent.width - x
                        height: grandChildrenColumn.height
                        visible: {
                            if (!modelData) return false;
                            return parent.childExpanded && modelData.children && modelData.children.length > 0;
                        }

                        Column {
                            id: grandChildrenColumn
                            width: parent.width
                            spacing: 4 * scaleFactor

                            Repeater {
                                model: modelData ? (modelData.children || []) : []

                                TreeNodeDelegate {
                                    width: grandChildrenColumn.width
                                    node: modelData
                                    scaleFactor: fileTreeItem.scaleFactor
                                    debug: fileTreeItem.debug
                                    isExpanded: false // 第三级不支持展开

                                    onExpanded: function(expandedNode) {
                                        // 第三级节点如果需要展开，传递给上级处理
                                        fileTreeItem.expanded(expandedNode);
                                    }
                                    onSelected: function(selectedNode, checked) {
                                        fileTreeItem.selected(selectedNode, checked);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}