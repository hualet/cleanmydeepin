import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: helpPage
    width: parent ? parent.width : 800
    height: parent ? parent.height : 600

    // 功能说明
    Text {
        text: qsTr("Function Introduction")
        font.pixelSize: 24 * (parent ? parent.scaleFactor : 1)
        anchors.top: parent.top
        anchors.topMargin: 40 * (parent ? parent.scaleFactor : 1)
        anchors.horizontalCenter: parent.horizontalCenter
    }

    // FAQ（占位）
    Rectangle {
        width: parent.width * 0.7
        height: 200 * (parent ? parent.scaleFactor : 1)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 100 * (parent ? parent.scaleFactor : 1)
        color: "#f0f0f0"
        Text {
            anchors.centerIn: parent
            text: qsTr("FAQ here")
        }
    }
}