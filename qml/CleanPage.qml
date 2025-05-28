import QtQuick
import QtQuick.Controls
import QtQuick.Window

Item {
    id: cleanPage

    // 高分屏缩放支持
    property real scaleFactor: Screen.pixelDensity / 6.0

    // 添加选中状态管理
    property int selectedCount: 0
    property real selectedSize: 0

    // 监听 ScanManager 的 treeModel 变化
    Connections {
        target: ScanManager
        function onTreeModelChanged() {
            console.log("Tree model updated");
            // 重置选择状态
            cleanPage.selectedCount = 0;
            cleanPage.selectedSize = 0;
            updateSelectionStats();
        }

        function onScanFinished(result) {
            console.log("Scan finished, tree model updated");
            updateSelectionStats();
        }
    }

    // 更新选择统计信息
    function updateSelectionStats() {
        var count = 0;
        var size = 0;

        if (ScanManager && ScanManager.treeModel) {
            // 遍历模型计算选中项目
            function countSelected(parentIndex) {
                var rowCount = ScanManager.treeModel.rowCount(parentIndex);
                for (var i = 0; i < rowCount; i++) {
                    var index = ScanManager.treeModel.index(i, 0, parentIndex);
                    var selected = ScanManager.treeModel.data(index, 261); // SelectedRole = 261
                    var isDir = ScanManager.treeModel.data(index, 259); // IsDirRole = 259
                    var itemSize = ScanManager.treeModel.data(index, 260); // SizeRole = 260

                    if (selected) {
                        if (!isDir) {
                            count++;
                        }
                        size += itemSize || 0;
                    }

                    // 递归处理子节点
                    countSelected(index);
                }
            }

            countSelected(ScanManager.treeModel.index(-1, -1)); // 根索引
        }

        cleanPage.selectedCount = count;
        cleanPage.selectedSize = size;
    }

    // 递归设置节点选中状态
    function setNodeSelection(index, selected) {
        if (!ScanManager || !ScanManager.treeModel || !index.valid) {
            console.log("setNodeSelection: Invalid parameters");
            return;
        }

        // 获取节点信息用于调试
        var nodeName = ScanManager.treeModel.data(index, 257); // NameRole = 257
        var isDir = ScanManager.treeModel.data(index, 259); // IsDirRole = 259

        // 设置当前节点选中状态
        var success = ScanManager.treeModel.setData(index, selected, 261); // SelectedRole = 261
        if (!success) {
            console.log("setNodeSelection: Failed to set selection for '" + nodeName + "'");
            return;
        }

        // 递归处理子节点
        var rowCount = ScanManager.treeModel.rowCount(index);
        for (var i = 0; i < rowCount; i++) {
            var childIndex = ScanManager.treeModel.index(i, 0, index);
            if (childIndex && childIndex.valid) {
                setNodeSelection(childIndex, selected);
            }
        }
    }

    // 全选所有节点
    function selectAll() {
        console.log("Selecting all nodes");

        if (!ScanManager || !ScanManager.treeModel)
            return;

        // 遍历所有根节点
        var rootRowCount = ScanManager.treeModel.rowCount();
        for (var i = 0; i < rootRowCount; i++) {
            var rootIndex = ScanManager.treeModel.index(i, 0);
            setNodeSelection(rootIndex, true);
        }

        updateSelectionStats();
    }

    // 取消全选
    function deselectAll() {
        console.log("Deselecting all nodes");

        if (!ScanManager || !ScanManager.treeModel)
            return;

        // 遍历所有根节点
        var rootRowCount = ScanManager.treeModel.rowCount();
        for (var i = 0; i < rootRowCount; i++) {
            var rootIndex = ScanManager.treeModel.index(i, 0);
            setNodeSelection(rootIndex, false);
        }

        updateSelectionStats();
    }

    // 组件初始化完成时尝试获取数据
    Component.onCompleted: {
        if (ScanManager && ScanManager.treeModel) {
            console.log("CleanPage initialized with tree model");
            updateSelectionStats();
        }
    }

    // 树形文件视图 - 使用真正的 TreeView
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
            id: treeViewBackground
            anchors.fill: parent
            color: "#f5f5f5"
            radius: 8
            border.color: "#dddddd"
            border.width: 1
            z: 1

            // 显示树状结构为空时的提示
            Text {
                anchors.centerIn: parent
                visible: !ScanManager || !ScanManager.treeModel || ScanManager.treeModel.rowCount() === 0
                text: qsTr("暂无扫描结果，请先执行扫描操作")
                font.pixelSize: 14 * cleanPage.scaleFactor
                color: "#666666"
            }

            Column {
                anchors.fill: parent
                anchors.margins: 5 * scaleFactor

                // 头部信息
                Item {
                    width: parent.width
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

                // 使用真正的 TreeView
                TreeView {
                    id: treeView
                    width: parent.width
                    height: parent.height - headerText.height - 10 * scaleFactor
                    clip: true
                    model: ScanManager ? ScanManager.treeModel : null

                    // 选择模型
                    selectionModel: ItemSelectionModel {
                        model: treeView.model
                    }

                    // 自定义委托
                    delegate: Item {
                        implicitWidth: treeView.width
                        implicitHeight: 32 * cleanPage.scaleFactor

                        readonly property real indentation: 20 * cleanPage.scaleFactor
                        readonly property real padding: 5 * cleanPage.scaleFactor

                        // TreeView 提供的必需属性
                        required property TreeView treeView
                        required property bool isTreeNode
                        required property bool expanded
                        required property bool hasChildren
                        required property int depth
                        required property int row
                        required property int column
                        required property bool current

                        // 获取模型数据
                        readonly property string itemName: model.name || ""
                        readonly property string itemPath: model.path || ""
                        readonly property bool itemIsDir: model.isDir || false
                        readonly property real itemSize: model.size || 0
                        readonly property bool itemSelected: model.selected || false

                        // 获取当前项的模型索引
                        readonly property var modelIndex: treeView.index(row, column)

                        // 背景
                        Rectangle {
                            anchors.fill: parent
                            color: current ? "#0085F8" : (row % 2 === 0 ? "#f0f0f0" : "#e8e8e8")
                            radius: 4
                            opacity: 0.8
                        }

                        Row {
                            spacing: 8 * cleanPage.scaleFactor
                            width: parent.width
                            height: parent.height
                            leftPadding: padding + (isTreeNode ? depth * indentation : 0)

                            // 复选框
                            CheckBox {
                                width: 20 * cleanPage.scaleFactor
                                height: 20 * cleanPage.scaleFactor
                                anchors.verticalCenter: parent.verticalCenter
                                checked: itemSelected

                                onCheckedChanged: {
                                    if (checked !== itemSelected && modelIndex && ScanManager && ScanManager.treeModel) {
                                        console.log("CheckBox: Setting '" + itemName + "' to " + checked);

                                        // 设置当前节点选中状态
                                        var success = ScanManager.treeModel.setData(modelIndex, checked, 261); // SelectedRole = 261
                                        if (!success) {
                                            console.log("CheckBox: Failed to set selection for '" + itemName + "'");
                                            return;
                                        }

                                        // 递归设置子节点选中状态（不重复设置当前节点）
                                        var rowCount = ScanManager.treeModel.rowCount(modelIndex);
                                        for (var i = 0; i < rowCount; i++) {
                                            var childIndex = ScanManager.treeModel.index(i, 0, modelIndex);
                                            if (childIndex && childIndex.valid) {
                                                cleanPage.setNodeSelection(childIndex, checked);
                                            }
                                        }

                                        // 更新统计信息
                                        cleanPage.updateSelectionStats();
                                    }
                                }
                            }

                            // 展开/收起图标
                            Item {
                                width: 20 * cleanPage.scaleFactor
                                height: 20 * cleanPage.scaleFactor
                                visible: isTreeNode && hasChildren
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: expanded ? "▼" : "▶"
                                    color: "#333333"
                                    font.pixelSize: 12 * cleanPage.scaleFactor
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (hasChildren && modelIndex) {
                                            console.log("Toggling expansion for row:", row, "expanded:", expanded);
                                            treeView.selectionModel.setCurrentIndex(modelIndex, ItemSelectionModel.NoUpdate);
                                            treeView.toggleExpanded(row);
                                        }
                                    }
                                }
                            }

                            // 文件/文件夹图标
                            Rectangle {
                                width: 20 * cleanPage.scaleFactor
                                height: 20 * cleanPage.scaleFactor
                                radius: width / 2
                                color: itemIsDir ? "#4285F4" : "#34A853"
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: itemIsDir ? "D" : "F"
                                    color: "white"
                                    font.pixelSize: 10 * cleanPage.scaleFactor
                                    font.bold: true
                                }
                            }

                            // 路径名
                            Text {
                                text: itemName
                                width: parent.width - 200 * cleanPage.scaleFactor
                                elide: Text.ElideMiddle
                                font.pixelSize: 12 * cleanPage.scaleFactor
                                color: "#333333"
                                font.bold: itemIsDir
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            // 大小（文件才显示）
                            Text {
                                visible: !itemIsDir
                                text: itemSize > 0 ? (itemSize / 1024).toFixed(1) + " KB" : ""
                                font.pixelSize: 10 * cleanPage.scaleFactor
                                width: 80 * cleanPage.scaleFactor
                                horizontalAlignment: Text.AlignRight
                                color: "#555555"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
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