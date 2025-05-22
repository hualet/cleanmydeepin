import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: fileTreeItem
    property var node: null  // 初始化为 null
    property real scaleFactor: 1
    property bool debug: false
    property int itemHeight: 32 * scaleFactor

    // 添加展开和选择信号
    signal expanded(var node)
    signal selected(var node, bool checked)

    // 辅助函数：安全地获取节点属性
    function getNodeProperty(propertyName, defaultValue) {
        return node ? (node[propertyName] || defaultValue) : defaultValue;
    }

    // 辅助函数：安全地获取布尔属性
    function getNodeBoolProperty(propertyName) {
        return Boolean(getNodeProperty(propertyName, false));
    }

    // 初始化
    Component.onCompleted: {
        if (fileTreeItem.debug) {
            console.log("TreeItem created:",
                "name:", getNodeProperty("name", "unknown"),
                "isDir:", getNodeBoolProperty("isDir"),
                "hasChildren:", getNodeBoolProperty("hasChildren"));
        }
    }

    // 监听展开状态变化
    onNodeChanged: {
        if (node) {
            if (fileTreeItem.debug) {
                console.log("Node changed:",
                    "path:", getNodeProperty("path", ""),
                    "expanded:", getNodeBoolProperty("expanded"),
                    "childrenLoaded:", getNodeBoolProperty("childrenLoaded"),
                    "children count:", (node.children || []).length);
            }
            updateHeight();
        }
    }

    // 更新高度
    function updateHeight() {
        var hasChildren = node && node.children && node.children.length > 0;
        var isExpanded = getNodeBoolProperty("expanded");
        height = hasChildren && isExpanded ? itemHeight + childrenColumn.height : itemHeight;
    }

    // 节点背景
    Rectangle {
        id: itemBackground
        height: itemHeight
        width: parent.width
        color: "#e0e0e0"
        radius: 4
        border.color: "#cccccc"
        border.width: 1
        opacity: 0.7

        // 添加鼠标区域，使整个项目可点击
        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (!node) return;

                var isDir = getNodeBoolProperty("isDir");
                var hasChildren = getNodeBoolProperty("hasChildren");

                if (isDir && hasChildren) {
                    if (fileTreeItem.debug) {
                        console.log("MouseArea: Clicked on node:",
                            "path:", getNodeProperty("path", ""),
                            "current expanded state:", getNodeBoolProperty("expanded"),
                            "children loaded:", getNodeBoolProperty("childrenLoaded"));
                    }

                    // 切换展开状态
                    node.expanded = !getNodeBoolProperty("expanded");

                    // 如果是展开操作，确保加载子节点
                    if (node.expanded) {
                        fileTreeItem.expanded(node);
                    }

                    if (fileTreeItem.debug) {
                        console.log("MouseArea: New expanded state:", getNodeBoolProperty("expanded"));
                    }
                    updateHeight();
                }
            }
        }

        Row {
            spacing: 8 * scaleFactor
            width: parent.width
            height: parent.height
            leftPadding: 8 * scaleFactor

            // 添加复选框
            CheckBox {
                id: itemCheckBox
                width: 20 * scaleFactor
                height: 20 * scaleFactor
                anchors.verticalCenter: parent.verticalCenter
                checked: getNodeBoolProperty("selected")
                onCheckedChanged: {
                    if (node) {
                        node.selected = checked;
                        fileTreeItem.selected(node, checked);
                    }
                }
            }

            // 展开/收起图标
            Text {
                id: expandIcon
                visible: getNodeBoolProperty("isDir") && getNodeBoolProperty("hasChildren")
                width: 20 * scaleFactor
                height: 20 * scaleFactor
                text: getNodeBoolProperty("expanded") ? "▼" : "▶"
                color: "#333333"
                font.pixelSize: 12 * scaleFactor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                anchors.verticalCenter: parent.verticalCenter

                // 添加点击区域
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (!node) return;

                        var isDir = getNodeBoolProperty("isDir");
                        var hasChildren = getNodeBoolProperty("hasChildren");

                        if (isDir && hasChildren) {
                            if (fileTreeItem.debug) {
                                console.log("ExpandIcon: Clicked on node:", getNodeProperty("path", ""));
                            }

                            // 切换展开状态
                            node.expanded = !getNodeBoolProperty("expanded");

                            // 如果是展开操作，确保加载子节点
                            if (node.expanded) {
                                fileTreeItem.expanded(node);
                            }

                            if (fileTreeItem.debug) {
                                console.log("ExpandIcon: New expanded state:", getNodeBoolProperty("expanded"));
                            }
                            updateHeight();
                        }
                    }
                }
            }

            // 文件/文件夹图标
            Rectangle {
                width: 20 * scaleFactor
                height: 20 * scaleFactor
                radius: width / 2
                color: getNodeBoolProperty("isDir") ? "#4285F4" : "#34A853"
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: getNodeBoolProperty("isDir") ? "D" : "F"
                    color: "white"
                    font.pixelSize: 10 * scaleFactor
                    font.bold: true
                }
            }

            // 路径名
            Text {
                text: getNodeProperty("name", "未知")
                width: parent.width - 160 * scaleFactor
                elide: Text.ElideMiddle
                font.pixelSize: 12 * scaleFactor
                color: "#333333"
                font.bold: getNodeBoolProperty("isDir")
                anchors.verticalCenter: parent.verticalCenter
            }

            // 大小（文件才显示）
            Text {
                visible: !getNodeBoolProperty("isDir")
                text: node && node.size > 0 ? (node.size / 1024).toFixed(1) + " KB" : ""
                font.pixelSize: 10 * scaleFactor
                width: 80 * scaleFactor
                horizontalAlignment: Text.AlignRight
                color: "#555555"
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // 子节点容器
    Column {
        id: childrenColumn
        y: itemHeight
        x: 24 * scaleFactor
        width: parent.width - x
        height: visible ? implicitHeight : 0
        spacing: 2 * scaleFactor
        visible: {
            if (!node) return false;
            var isDir = getNodeBoolProperty("isDir");
            var isExpanded = getNodeBoolProperty("expanded");
            var hasChildren = node.children && node.children.length > 0;
            return isDir && isExpanded && hasChildren;
        }

        // 调试信息
        Text {
            visible: fileTreeItem.debug
            text: {
                if (!node) return "";
                return "Children count: " + (node.children ? node.children.length : 0) +
                       ", Expanded: " + getNodeBoolProperty("expanded") +
                       ", Loaded: " + getNodeBoolProperty("childrenLoaded");
            }
            font.pixelSize: 10 * scaleFactor
            color: "red"
        }

        // 子节点列表
        Repeater {
            id: childRepeater
            model: node ? (node.children || []) : []

            // 使用 Loader 来加载子节点
            Loader {
                width: childrenColumn.width
                source: "FileTreeItem.qml"

                property var node: modelData
                property real scaleFactor: fileTreeItem.scaleFactor
                property bool debug: fileTreeItem.debug

                onLoaded: {
                    item.expanded.connect(function(expandedNode) {
                        fileTreeItem.expanded(expandedNode);
                    });
                    item.selected.connect(function(selectedNode, checked) {
                        fileTreeItem.selected(selectedNode, checked);
                    });
                }
            }
        }
    }
}