import QtQuick
import Quickshell
import qs.Ui
import qs.Commons

BarWidget {
  id: root
  moduleName: "lgse.omosaic"

  readonly property var omosaicService: bar?.shell?.serviceFor("lgse.omosaic")
  property bool popupOpen: false

  function close() { popupOpen = false }

  implicitWidth: barSize
  implicitHeight: barSize

  Text {
    anchors.centerIn: parent
    text: "󰸉"
    color: root.bar.barForeground
    font.family: root.bar.fontFamily
    font.pixelSize: Style.font.body
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.popupOpen = !root.popupOpen
    onEntered: if (root.bar) root.bar.showTooltip(root, "Omosaic wallpapers")
    onExited: if (root.bar) root.bar.hideTooltip(root)
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(430))
    contentHeight: popup.fittedContentHeight(content.implicitHeight)

    Column {
      id: content
      anchors.fill: parent
      spacing: Style.space(10)

      Column {
        width: parent.width
        spacing: Style.space(3)

        Text {
          text: "Omosaic"
          color: Color.foreground
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.title
          font.bold: true
        }

        Text {
          text: "Choose a surface for each connected display"
          color: Util.alpha(Color.foreground, 0.65)
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.caption
        }
      }

      Column {
        id: displayList
        width: parent.width
        spacing: Style.space(8)

        Repeater {
          model: Quickshell.screens

          Rectangle {
            id: displayCard
            required property var modelData
            readonly property string screenKey: root.omosaicService
              ? root.omosaicService.keyForScreen(modelData) : modelData.name
            readonly property var assignment: root.omosaicService
              ? root.omosaicService.assignmentForScreen(modelData) : null
            readonly property string assignmentLabel: {
              if (!assignment) return "Using Omarchy default"
              if (assignment.type === "color") return assignment.color
              var parts = String(assignment.path || "").split("/")
              return parts.length ? parts[parts.length - 1] : "Wallpaper"
            }

            width: displayList.width
            height: Style.space(94)
            radius: Style.cornerRadius
            color: Util.alpha(Color.foreground, 0.045)
            border.width: 1
            border.color: Util.alpha(Color.foreground, 0.12)

            Column {
              anchors.fill: parent
              anchors.margins: Style.space(10)
              spacing: Style.space(7)

              Row {
                width: parent.width
                spacing: Style.space(8)

                Text {
                  text: "󰍹"
                  color: Color.accent
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.body
                }

                Column {
                  width: parent.width - Style.space(28)
                  spacing: Style.space(1)

                  Text {
                    width: parent.width
                    text: displayCard.modelData.model || displayCard.modelData.name
                    color: Color.foreground
                    font.family: root.bar.fontFamily
                    font.pixelSize: Style.font.body
                    font.bold: true
                    elide: Text.ElideRight
                  }

                  Text {
                    width: parent.width
                    text: displayCard.modelData.name + " · " + displayCard.assignmentLabel
                    color: Util.alpha(Color.foreground, 0.62)
                    font.family: root.bar.fontFamily
                    font.pixelSize: Style.font.caption
                    elide: Text.ElideMiddle
                  }
                }
              }

              Row {
                id: actions
                width: parent.width
                spacing: Style.space(6)

                ActionButton {
                  width: (actions.width - actions.spacing * 2) / 3
                  label: "Wallpaper"
                  onActivated: {
                    root.popupOpen = false
                    if (root.omosaicService)
                      root.omosaicService.chooseImageForKey(displayCard.screenKey)
                  }
                }

                ActionButton {
                  width: (actions.width - actions.spacing * 2) / 3
                  label: "Solid color"
                  onActivated: {
                    root.popupOpen = false
                    if (root.omosaicService)
                      root.omosaicService.chooseColorForKey(displayCard.screenKey)
                  }
                }

                ActionButton {
                  width: (actions.width - actions.spacing * 2) / 3
                  label: "Reset"
                  available: displayCard.assignment !== null
                  onActivated: {
                    if (root.omosaicService)
                      root.omosaicService.clearAssignment(displayCard.screenKey)
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  component ActionButton: Rectangle {
    id: actionButton
    property string label: ""
    property bool available: true
    signal activated()

    height: Style.space(28)
    radius: Style.cornerRadius > 0 ? height / 3 : 0
    color: buttonMouse.containsMouse
      ? Util.alpha(Color.foreground, 0.14)
      : Util.alpha(Color.foreground, 0.075)
    opacity: available ? 1 : 0.38

    Text {
      anchors.centerIn: parent
      text: actionButton.label
      color: Color.foreground
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.caption
    }

    MouseArea {
      id: buttonMouse
      anchors.fill: parent
      enabled: actionButton.available
      hoverEnabled: true
      cursorShape: actionButton.available ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: actionButton.activated()
    }
  }
}
