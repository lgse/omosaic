import QtQuick
import qs.Commons

Rectangle {
  id: root

  property string label: ""
  property string fontFamily: ""
  property bool available: true
  property bool active: false
  signal activated()

  height: Style.space(28)
  radius: Style.cornerRadius > 0 ? height / 3 : 0
  color: active
    ? Util.alpha(Color.accent, 0.24)
    : (buttonMouse.containsMouse
      ? Util.alpha(Color.foreground, 0.14)
      : Util.alpha(Color.foreground, 0.075))
  border.width: active ? 1 : 0
  border.color: Color.accent
  opacity: available ? 1 : 0.38

  Text {
    anchors.centerIn: parent
    text: root.label
    color: Color.foreground
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
  }

  MouseArea {
    id: buttonMouse
    anchors.fill: parent
    enabled: root.available
    hoverEnabled: true
    cursorShape: root.available ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: root.activated()
  }
}
