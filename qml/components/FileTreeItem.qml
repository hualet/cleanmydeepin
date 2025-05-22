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

    // 添加内部状态管理
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

        onExpanded: function(expandedNode) {
            // 更新内部状态
            if (expandedNode === fileTreeItem.node) {
                fileTreeItem.isExpanded = !fileTreeItem.isExpanded;
                if (fileTreeItem.isExpanded) {
                    expandedNode.expanded = true;
                    fileTreeItem.expanded(expandedNode);
                } else {
                    expandedNode.expanded = false;
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
                           ", Expanded: " + fileTreeItem.isExpanded +
                           ", Loaded: " + node.childrenLoaded;
                }
                font.pixelSize: 10 * scaleFactor
                color: "red"
            }

            // 子节点列表
            Repeater {
                id: childRepeater
                model: node ? (node.children || []) : []

                Item {
                    id: childItem
                    width: childrenColumn.width
                    height: childNodeDelegate.height + (childChildrenContainer.visible ? childChildrenContainer.height + (4 * scaleFactor) : 0)

                    // 子节点的节点委托
                    TreeNodeDelegate {
                        id: childNodeDelegate
                        width: parent.width
                        node: modelData
                        scaleFactor: fileTreeItem.scaleFactor
                        debug: fileTreeItem.debug

                        onExpanded: function(expandedNode) {
                            fileTreeItem.expanded(expandedNode);
                        }
                        onSelected: function(selectedNode, checked) {
                            fileTreeItem.selected(selectedNode, checked);
                        }
                    }

                    // 子节点的子节点容器
                    Item {
                        id: childChildrenContainer
                        y: childNodeDelegate.height + (4 * scaleFactor)
                        x: indentWidth
                        width: parent.width - x
                        height: childChildrenColumn.height
                        visible: {
                            if (!modelData) return false;
                            return modelData.expanded && modelData.children && modelData.children.length > 0;
                        }

                        Column {
                            id: childChildrenColumn
                            width: parent.width
                            spacing: 4 * scaleFactor

                            // 子节点的子节点列表
                            Repeater {
                                model: modelData ? (modelData.children || []) : []

                                TreeNodeDelegate {
                                    width: childChildrenColumn.width
                                    node: modelData
                                    scaleFactor: fileTreeItem.scaleFactor
                                    debug: fileTreeItem.debug

                                    onExpanded: function(expandedNode) {
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

    Component.onCompleted: {
        if (node) {
            isExpanded = node.expanded || false;
        }
    }
}