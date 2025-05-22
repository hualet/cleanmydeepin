import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import "components" // 确保 FileTreeItem.qml 在 qml/components 目录下

Item {
    id: cleanPage

    // 高分屏缩放支持 - 降低缩放比例
    property real scaleFactor: Screen.pixelDensity / 6.0  // 减小缩放因子，之前是2.0

    // 使用 ScanManager 提供的树形结构数据
    property var treeData: []

    // 添加选中状态管理
    property var selectedNodes: ({})
    property int selectedCount: 0
    property real selectedSize: 0

    // 监听 ScanManager 的 treeResult 变化
    Connections {
        target: ScanManager
        function onTreeResultChanged() {
            cleanPage.treeData = ScanManager.treeResult;
            console.log("Tree data updated, root nodes count: " + cleanPage.treeData.length);
            // 重置选择状态
            cleanPage.selectedNodes = {};
            cleanPage.selectedCount = 0;
            cleanPage.selectedSize = 0;
        }

        function onScanFinished(result) {
            cleanPage.treeData = result;
            console.log("Scan finished, tree data updated");
        }
    }

    // 请求加载子节点
    function loadChildrenFor(node) {
        console.log("Loading children for:", node.path,
            "childrenLoaded:", node.childrenLoaded,
            "expanded:", node.expanded);

        // 获取子节点（无论是否已加载过）
        var children = ScanManager.getChildren(node.path);
        console.log("Children loaded:", children ? children.length : 0, "for path:", node.path);

        if (children && children.length > 0) {
            for (var i = 0; i < Math.min(children.length, 5); i++) {
                console.log("Child", i, ":", children[i].name, "path:", children[i].path);
            }
            if (children.length > 5) {
                console.log("... and", (children.length - 5), "more children");
            }
        }

        // 更新节点状态和子节点
        node.children = children || [];
        node.childrenLoaded = true;
        node.expanded = true;

        // 在树形数据中找到并更新这个节点
        function updateNodeInTree(nodes) {
            for (var i = 0; i < nodes.length; i++) {
                if (nodes[i].path === node.path) {
                    nodes[i] = node;
                    return true;
                }
                if (nodes[i].children && nodes[i].children.length > 0) {
                    if (updateNodeInTree(nodes[i].children)) {
                        return true;
                    }
                }
            }
            return false;
        }

        // 创建新的树形数据副本并更新节点
        var newTreeData = [];
        for (var j = 0; j < cleanPage.treeData.length; j++) {
            var rootNode = Object.assign({}, cleanPage.treeData[j]);
            if (rootNode.children) {
                rootNode.children = rootNode.children.slice();
            }
            newTreeData.push(rootNode);
        }

        // 更新节点
        if (updateNodeInTree(newTreeData)) {
            console.log("Node updated in tree:", node.path);
        } else {
            console.log("Failed to update node in tree:", node.path);
        }

        // 更新树形数据
        cleanPage.treeData = newTreeData;
    }

    // 递归设置节点选中状态
    function setNodeSelection(node, selected) {
        if (!node) return;

        node.selected = selected;
        if (selected) {
            selectedNodes[node.path] = node;
            if (!node.isDir) {
                selectedCount++;
                selectedSize += node.size || 0;
            }
        } else {
            delete selectedNodes[node.path];
            if (!node.isDir) {
                selectedCount--;
                selectedSize -= node.size || 0;
            }
        }

        // 递归处理子节点
        if (node.children) {
            for (var i = 0; i < node.children.length; i++) {
                setNodeSelection(node.children[i], selected);
            }
        }
    }

    // 全选所有节点
    function selectAll() {
        console.log("Selecting all nodes");
        for (var i = 0; i < treeData.length; i++) {
            setNodeSelection(treeData[i], true);
        }
        // 强制更新视图
        var temp = treeData;
        treeData = [];
        treeData = temp;
    }

    // 取消全选
    function deselectAll() {
        console.log("Deselecting all nodes");
        for (var i = 0; i < treeData.length; i++) {
            setNodeSelection(treeData[i], false);
        }
        // 强制更新视图
        var temp = treeData;
        treeData = [];
        treeData = temp;
    }

    // 组件初始化完成时尝试获取数据
    Component.onCompleted: {
        console.log("CleanPage completed, tree data count:", cleanPage.treeData.length);
        var result = ScanManager.treeResult;
        console.log("Manual check treeResult count:", result ? result.length : 0);
        if (result && result.length > 0) {
            // 初始化根节点的状态
            for (var i = 0; i < result.length; i++) {
                result[i].expanded = false;
                result[i].childrenLoaded = false;
                result[i].selected = false;
                // 默认设置目录都有子节点，实际加载时再更新
                result[i].hasChildren = result[i].isDir;
            }
            cleanPage.treeData = result;
        }
    }

    // 观察 treeData 变化
    onTreeDataChanged: {
        console.log("treeData changed, new count:", treeData.length);
    }

    // 临时按钮 - 测试树形数据
    Button {
        id: testBtn
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 10 * scaleFactor
        text: qsTr("刷新树形数据")
        onClicked: {
            console.log("Manual refresh, current tree data:", ScanManager.treeResult.length);
            cleanPage.treeData = ScanManager.treeResult;
        }
    }

    // 树形文件视图 - 不使用阴影效果，改为使用多层矩形模拟
    Item {
        id: treeViewContainer
        width: parent.width * 0.8
        height: parent.height * 0.5
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 40 * cleanPage.scaleFactor

        // 添加背景层，模拟阴影效果
        Rectangle {
            id: shadowRect
            anchors.fill: parent
            anchors.leftMargin: -3
            anchors.topMargin: -3
            anchors.rightMargin: -3
            anchors.bottomMargin: -3
            color: "#cccccc"
            radius: 8
            z: 0
        }

        Rectangle {
            id: treeView
            anchors.fill: parent
            color: "#f5f5f5"  // 使用更亮的背景色
            radius: 8         // 圆角矩形
            border.color: "#dddddd"
            border.width: 1
            z: 1

            // 显示树状结构为空时的提示
            Text {
                anchors.centerIn: parent
                visible: cleanPage.treeData.length === 0
                text: qsTr("暂无扫描结果，请先执行扫描操作")
                font.pixelSize: 14 * cleanPage.scaleFactor
                color: "#666666"
            }

            // 使用 ScrollView 包裹，支持滚动
            ScrollView {
                id: treeScrollView
                anchors.fill: parent
                anchors.margins: 5 * scaleFactor
                clip: true

                ListView {
                    id: treeListView
                    anchors.fill: parent
                    anchors.margins: 5 * scaleFactor
                    spacing: 4 * scaleFactor

                    header: Item {
                        width: treeListView.width
                        height: headerText.height + 10 * scaleFactor

                        Rectangle {
                            anchors.fill: parent
                            color: "#e8e8e8"
                            radius: 4
                        }

                        Text {
                            id: headerText
                            anchors.centerIn: parent
                            text: qsTr("已选择 %1 个文件，共 %2 MB").arg(cleanPage.selectedCount)
                                .arg((cleanPage.selectedSize / (1024 * 1024)).toFixed(2))
                            font.pixelSize: 14 * cleanPage.scaleFactor
                            color: "#333333"
                            font.bold: true
                        }
                    }

                    model: cleanPage.treeData
                    delegate: FileTreeItem {
                        width: treeListView.width
                        node: modelData
                        scaleFactor: cleanPage.scaleFactor
                        debug: true

                        // 修改为使用函数处理信号
                        function handleExpanded(expandedNode) {
                            console.log("Item expanded signal received, loading children for:", expandedNode.path);
                            cleanPage.loadChildrenFor(expandedNode);
                        }

                        function handleSelected(selectedNode, checked) {
                            console.log("Item selected signal received:", selectedNode.path, checked);
                            cleanPage.setNodeSelection(selectedNode, checked);
                        }

                        onExpanded: handleExpanded(node)
                        onSelected: handleSelected(node, checked)
                    }
                }
            }
        }
    }

    // 全选/反选按钮
    Row {
        spacing: 20 * cleanPage.scaleFactor
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: treeViewContainer.bottom
        anchors.topMargin: 20 * cleanPage.scaleFactor

        // 为按钮添加样式
        Button {
            text: qsTr("全选")
            ToolTip.text: qsTr("选择所有项目")
            background: Rectangle {
                radius: 4
                color: parent.pressed ? "#555555" : "#666666"
            }
            contentItem: Text {
                text: parent.text
                color: "white"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 12 * cleanPage.scaleFactor
            }
            onClicked: {
                cleanPage.selectAll();
            }
        }

        Button {
            text: qsTr("取消全选")
            ToolTip.text: qsTr("取消选择所有项目")
            background: Rectangle {
                radius: 4
                color: parent.pressed ? "#555555" : "#666666"
            }
            contentItem: Text {
                text: parent.text
                color: "white"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 12 * cleanPage.scaleFactor
            }
            onClicked: {
                cleanPage.deselectAll();
            }
        }
    }

    // 底部清理按钮
    Button {
        id: cleanBtn
        text: qsTr("清理")
        width: 120 * scaleFactor
        height: 40 * scaleFactor
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 40 * cleanPage.scaleFactor
        ToolTip.text: qsTr("清理选中的文件")
        enabled: cleanPage.selectedCount > 0

        background: Rectangle {
            radius: 4
            color: parent.enabled ? (parent.pressed ? "#0D6EFD" : "#0D6EFD") : "#cccccc"
            opacity: parent.pressed ? 0.8 : 1.0
        }
        contentItem: Text {
            text: parent.text
            color: "white"
            font.pixelSize: 16 * cleanPage.scaleFactor
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        onClicked: {
            // TODO: 实现清理逻辑
        }
    }
}