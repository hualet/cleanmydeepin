import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15

Item {
    id: scanPage

    property real scaleFactor: Screen.pixelDensity / 6.0
    property real progress: ScanManager.progress
    property int scannedFiles: ScanManager.scannedFiles
    property int scannedDirs: ScanManager.scannedDirs
    property bool scanning: false
    property real totalSize: 0  // 已扫描文件的总大小

    // 监听扫描状态变化
    Connections {
        target: ScanManager
        function onScanFinished() {
            scanning = false;
            // 计算扫描出的文件总大小
            if (ScanManager.treeModel) {
                calculateTotalSize();
            }
        }
        function onProgressChanged() {
            // 进度变化时计算当前总大小
            calculateTotalSize();
        }
    }

    // 计算总文件大小
    function calculateTotalSize() {
        var size = 0;
        if (ScanManager && ScanManager.treeModel) {
            // 遍历模型计算总大小
            function countSize(parentIndex) {
                var rowCount = ScanManager.treeModel.rowCount(parentIndex);
                for (var i = 0; i < rowCount; i++) {
                    var index = ScanManager.treeModel.index(i, 0, parentIndex);
                    var itemSize = ScanManager.treeModel.data(index, 260); // SizeRole = 260
                    size += itemSize || 0;
                    // 递归处理子节点
                    countSize(index);
                }
            }
            countSize(ScanManager.treeModel.index(-1, -1)); // 根索引
        }
        totalSize = size;
    }

    // 圆形扫描按钮
    Item {
        id: circularScanButton
        width: 120 * scaleFactor
        height: 120 * scaleFactor
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.25

        // 背景圆环（灰色底色）
        Rectangle {
            id: backgroundRing
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.color: "#e9ecef"
            border.width: 8 * scaleFactor
        }

        // 进度圆环（动态显示进度）
        Canvas {
            id: progressRing
            anchors.fill: parent

            property real angle: progress * 360

            onAngleChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                if (scanning && progress > 0) {
                    // 绘制进度圆弧
                    ctx.beginPath();
                    ctx.lineWidth = 8 * scaleFactor;
                    ctx.strokeStyle = "#0D6EFD";
                    ctx.lineCap = "round";

                    var centerX = width / 2;
                    var centerY = height / 2;
                    var radius = (width - ctx.lineWidth) / 2;
                    var startAngle = -Math.PI / 2; // 从顶部开始
                    var endAngle = startAngle + (angle * Math.PI / 180);

                    ctx.arc(centerX, centerY, radius, startAngle, endAngle);
                    ctx.stroke();

                    // 添加发光效果
                    ctx.shadowColor = "#0D6EFD";
                    ctx.shadowBlur = 10 * scaleFactor;
                    ctx.stroke();
                }
            }
        }

        // 中心按钮
        Rectangle {
            id: centerButton
            width: parent.width - 20 * scaleFactor
            height: parent.height - 20 * scaleFactor
            radius: width / 2
            color: scanning ? "#dc3545" : "#0D6EFD"
            anchors.centerIn: parent

            // 按钮按下效果
            scale: buttonMouseArea.pressed ? 0.95 : 1.0
            Behavior on scale {
                NumberAnimation { duration: 100 }
            }

            // 扫描文字
            Text {
                anchors.centerIn: parent
                text: scanning ? qsTr("停止") : qsTr("扫描")
                color: "white"
                font.pixelSize: 18 * scaleFactor
                font.bold: true
            }

            // 鼠标区域
            MouseArea {
                id: buttonMouseArea
                anchors.fill: parent
                onClicked: {
                    if (scanning) {
                        ScanManager.stopScan();
                        scanning = false;
                    } else {
                        ScanManager.startScan();
                        scanning = true;
                        totalSize = 0; // 重置总大小
                    }
                }
            }

            // 工具提示
            ToolTip {
                id: buttonTooltip
                visible: buttonMouseArea.containsMouse
                text: scanning ? qsTr("停止当前扫描任务") : qsTr("开始扫描垃圾文件")
                delay: 500
            }
        }
    }

    // 扫描信息区域
    Column {
        id: scanInfoColumn
        width: parent.width * 0.8
        spacing: 20 * scaleFactor
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: circularScanButton.bottom
        anchors.topMargin: 40 * scaleFactor

        // 状态信息
        Text {
            id: statusText
            anchors.horizontalCenter: parent.horizontalCenter
            text: scanning ? qsTr("正在扫描...") : (totalSize > 0 ? qsTr("扫描完成") : qsTr("等待开始扫描"))
            color: "#212529"
            font.pixelSize: 16 * scaleFactor
            font.bold: true
        }

        // 扫描统计信息
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8 * scaleFactor

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("已扫描 %1 个目录、%2 个文件").arg(scannedDirs).arg(scannedFiles)
                color: "#6c757d"
                font.pixelSize: 14 * scaleFactor
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("待清理内容大小: %1 MB").arg((totalSize / (1024 * 1024)).toFixed(2))
                color: "#28a745"
                font.pixelSize: 14 * scaleFactor
                font.bold: true
                visible: totalSize > 0
            }
        }
    }
}