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
            var result = ScanManager.treeResult;
            // 初始化根节点状态，不设置 expanded
            for (var i = 0; i < result.length; i++) {
                result[i].childrenLoaded = false;
                result[i].selected = false;
                result[i].hasChildren = result[i].isDir;
            }
            cleanPage.treeData = result;
            console.log("Tree data updated, root nodes count:", cleanPage.treeData.length);
            // 重置选择状态
            cleanPage.selectedNodes = {};
            cleanPage.selectedCount = 0;
            cleanPage.selectedSize = 0;
        }

        function onScanFinished(result) {
            // 初始化根节点状态，不设置 expanded
            for (var i = 0; i < result.length; i++) {
                result[i].childrenLoaded = false;
                result[i].selected = false;
                result[i].hasChildren = result[i].isDir;
            }
            cleanPage.treeData = result;
            console.log("Scan finished, tree data updated");
        }
    }

    // 请求加载子节点
    function loadChildrenFor(node) {
        console.log("Loading children for:", node.path);

        // 获取子节点（无论是否已加载过）
        var children = ScanManager.getChildren(node.path);

        if (children && children.length > 0) {
            // 初始化子节点的状态
            for (var j = 0; j < children.length; j++) {
                // 不再设置 expanded 状态，界面自行控制
                children[j].childrenLoaded = false;
                // 继承父节点的选中状态
                children[j].selected = node.selected || false;
                children[j].hasChildren = children[j].isDir;

                // 如果父节点被选中，需要将子节点也添加到选择列表中
                if (node.selected) {
                    selectedNodes[children[j].path] = children[j];
                    selectedSize += children[j].size || 0;
                    if (!children[j].isDir) {
                        selectedCount++;
                    }
                }
            }
        }

        // 更新节点状态和子节点
        node.children = children || [];
        node.childrenLoaded = true;
        // 不再设置 expanded 状态，界面自行控制

        // 在树形数据中找到并更新这个节点
        function updateNodeInTree(nodes) {
            for (var i = 0; i < nodes.length; i++) {
                if (nodes[i].path === node.path) {
                    // 使用深度复制来保持状态
                    nodes[i] = deepCopyNodeWithSelection(node);
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
            newTreeData.push(deepCopyNodeWithSelection(cleanPage.treeData[j]));
        }

        // 更新节点
        updateNodeInTree(newTreeData);

        // 更新树形数据
        cleanPage.treeData = newTreeData;

        // 强制更新视图以确保新加载的子节点状态正确显示
        forceTreeViewUpdate();
    }

    // 递归设置节点选中状态
    function setNodeSelection(node, selected) {
        if (!node) {
            console.log("setNodeSelection: node is null or undefined");
            return;
        }

        node.selected = selected;
        if (selected) {
            selectedNodes[node.path] = node;
            selectedSize += node.size || 0;
            if (!node.isDir) {
                selectedCount++;
            }
        } else {
            delete selectedNodes[node.path];
            selectedSize -= node.size || 0;
            if (!node.isDir) {
                selectedCount--;
            }
        }

        // 递归处理子节点
        if (node.children && node.children.length > 0) {
            for (var i = 0; i < node.children.length; i++) {
                setNodeSelection(node.children[i], selected);
            }
        }

        // 验证状态是否正确设置（仅在出现问题时输出警告）
        if (selected && !selectedNodes.hasOwnProperty(node.path)) {
            console.log("WARNING: node not found in selectedNodes:", node.path);
        } else if (!selected && selectedNodes.hasOwnProperty(node.path)) {
            console.log("WARNING: node still in selectedNodes:", node.path);
        }
    }

    // 全选所有节点
    function selectAll() {
        console.log("Selecting all nodes");

        // 重置选择状态
        selectedNodes = {};
        selectedCount = 0;
        selectedSize = 0;

        for (var i = 0; i < treeData.length; i++) {
            setNodeSelection(treeData[i], true);
        }

        // 使用新的强制更新函数
        forceTreeViewUpdate();
    }

    // 取消全选
    function deselectAll() {
        console.log("Deselecting all nodes");

        for (var i = 0; i < treeData.length; i++) {
            setNodeSelection(treeData[i], false);
        }

        // 使用新的强制更新函数
        forceTreeViewUpdate();
    }

    // 组件初始化完成时尝试获取数据
    Component.onCompleted: {
        var result = ScanManager.treeResult;
        if (result && result.length > 0) {
            // 初始化根节点的状态
            for (var i = 0; i < result.length; i++) {
                // 不再设置 expanded 状态，界面自行控制
                result[i].childrenLoaded = false;
                result[i].selected = false;
                // 默认设置目录都有子节点，实际加载时再更新
                result[i].hasChildren = result[i].isDir;
            }
            cleanPage.treeData = result;
            console.log("CleanPage initialized with", result.length, "root nodes");
        }
    }

    // 观察 treeData 变化
    onTreeDataChanged: {
        // 移除详细日志
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
                            cleanPage.loadChildrenFor(expandedNode);
                        }

                        function handleSelected(selectedNode, checked) {
                            cleanPage.setNodeSelection(selectedNode, checked);

                            // 强制更新视图以确保UI同步
                            cleanPage.forceTreeViewUpdate();
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

    // 深度复制树节点并保持选中状态
    function deepCopyNodeWithSelection(node) {
        if (!node) return null;

        var newNode = {};
        // 复制所有基本属性
        newNode.path = node.path;
        newNode.name = node.name;
        newNode.size = node.size;
        newNode.isDir = node.isDir;
        // 不再复制 expanded 状态，界面自行控制
        newNode.childrenLoaded = node.childrenLoaded;
        newNode.hasChildren = node.hasChildren;

        // 从 selectedNodes 中获取正确的选中状态
        newNode.selected = selectedNodes.hasOwnProperty(node.path);

        // 递归复制子节点
        if (node.children && node.children.length > 0) {
            newNode.children = [];
            for (var i = 0; i < node.children.length; i++) {
                newNode.children.push(deepCopyNodeWithSelection(node.children[i]));
            }
        }

        return newNode;
    }

    // 强制更新树形视图
    function forceTreeViewUpdate() {
        // 深度复制树数据并保持选中状态
        var newTreeData = [];
        for (var i = 0; i < treeData.length; i++) {
            newTreeData.push(deepCopyNodeWithSelection(treeData[i]));
        }

        // 使用新的数据替换原有数据
        treeData = [];
        treeData = newTreeData;

        // 强制更新选择状态属性
        selectedNodesChanged();
        selectedCountChanged();
        selectedSizeChanged();
    }
}