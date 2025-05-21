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
    property var initialTreeData: []

    /*
    // 监听 ScanManager 的 treeResult 变化
    Connections {
        target: ScanManager
        function onTreeResultChanged() {
            var newResult = ScanManager.treeResult;
            console.log("CleanPage: ScanManager.treeResult changed (signal), new count:", newResult ? newResult.length : "null/undefined");
            if (newResult && Array.isArray(newResult)) {
                cleanPage.treeData = newResult;
            } else {
                // If newResult is null, undefined, or not an array, set treeData to empty array
                // to avoid errors in ListView model.
                cleanPage.treeData = [];
            }
            console.log("CleanPage: onTreeResultChanged final treeData count:", cleanPage.treeData.length);
        }

        // The onScanFinished connection in CleanPage is likely redundant now.
        // For now, let's comment it out to see if the new mechanism is sufficient.
        /*
        function onScanFinished() {
            console.log("Scan finished, requesting tree data");
            var result = ScanManager.treeResult;
            console.log("Current tree data node count:", result ? result.length : 0);
            cleanPage.treeData = result;
        }
        */
    }
    */

    // 请求加载子节点
    function loadChildrenFor(node) {
        console.log("Loading children for:", node.path);
        if (!node.childrenLoaded) {
            // 通过 ScanManager 获取子节点
            var children = ScanManager.getChildren(node.path);
            console.log("Children loaded:", children ? children.length : 0, "for path:", node.path);

            // 打印子节点信息
            if (children && children.length > 0) {
                for (var i = 0; i < Math.min(children.length, 5); i++) { // 只打印前5个，避免日志过长
                    console.log("Child", i, ":", children[i].name, "path:", children[i].path);
                }
                if (children.length > 5) {
                    console.log("... and", (children.length - 5), "more children");
                }
            }

            // 设置子节点并更新模型
            node.children = children || [];
            node.childrenLoaded = true;

            // 强制刷新视图 - 通过重新分配数据
            var tempData = cleanPage.treeData;
            cleanPage.treeData = [];
            cleanPage.treeData = tempData;
        }
    }

    // 组件初始化完成时尝试获取数据
    Component.onCompleted: {
        console.log("CleanPage: Component.onCompleted started.");
        console.log("CleanPage: Received initialTreeData type:", typeof initialTreeData, "is array:", Array.isArray(initialTreeData));

        // Attempt to log initialTreeData content. JSON.stringify might be problematic for QML/C++ objects.
        // If it causes errors, this specific log line might need to be removed or adjusted.
        try {
            console.log("CleanPage: initialTreeData (JSON):", JSON.stringify(initialTreeData));
            if (initialTreeData && typeof initialTreeData.length === 'number') {
                 console.log("CleanPage: initialTreeData.length:", initialTreeData.length);
            }
        } catch (e) {
            console.log("CleanPage: Could not JSON.stringify initialTreeData or get length directly. Error:", e.message);
        }

        if (initialTreeData && Array.isArray(initialTreeData) && initialTreeData.length > 0) {
            console.log("CleanPage: Using initialTreeData. Count:", initialTreeData.length);
            cleanPage.treeData = initialTreeData;
            console.log("CleanPage: treeData length after assignment from initialTreeData:", cleanPage.treeData.length);
        } else {
            console.log("CleanPage: initialTreeData is not suitable. Falling back to ScanManager.treeResult.");
            var currentResult = ScanManager.treeResult;
            console.log("CleanPage: Fallback ScanManager.treeResult type:", typeof currentResult, "is array:", Array.isArray(currentResult));
            if (currentResult && typeof currentResult.length === 'number') {
                 console.log("CleanPage: Fallback ScanManager.treeResult.length:", currentResult.length);
            }

            if (currentResult && Array.isArray(currentResult)) {
                cleanPage.treeData = currentResult;
                console.log("CleanPage: treeData length after assignment from fallback ScanManager.treeResult:", cleanPage.treeData.length);
            } else {
                console.log("CleanPage: Fallback ScanManager.treeResult is also not a valid array. Setting treeData to empty.");
                cleanPage.treeData = [];
                console.log("CleanPage: treeData length after setting to empty array:", cleanPage.treeData.length);
            }
        }
        console.log("CleanPage: Component.onCompleted final treeData count:", cleanPage.treeData.length);
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
                            text: qsTr("已加载 %1 个根目录").arg(cleanPage.treeData.length)
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
                        debug: true // 启用调试信息以便于排错
                        onExpanded: {
                            // 当节点展开时，加载子节点
                            console.log("Item expanded signal received, loading children for:", node.path);
                            cleanPage.loadChildrenFor(node);
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
            text: qsTr("Select All")
            ToolTip.text: qsTr("Select all items")
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
            // TODO: 绑定全选逻辑
        }

        Button {
            text: qsTr("Deselect All")
            ToolTip.text: qsTr("Deselect all items")
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
            // TODO: 绑定反选逻辑
        }
    }

    // 底部清理按钮
    Button {
        id: cleanBtn
        text: qsTr("Clean")
        width: 120 * scaleFactor
        height: 40 * scaleFactor
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 40 * cleanPage.scaleFactor
        ToolTip.text: qsTr("Clean selected files")

        background: Rectangle {
            radius: 4
            color: parent.pressed ? "#0D6EFD" : "#0D6EFD"
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
        // TODO: 绑定清理逻辑
    }
}