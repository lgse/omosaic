import QtQuick
import Quickshell
import qs.Ui
import qs.Commons
import "Model.js" as Model

BarWidget {
  id: root
  moduleName: "lgse.omosaic"

  readonly property var omosaicService: bar?.shell?.serviceFor("lgse.omosaic")
  readonly property var hostWindow: root.QsWindow ? root.QsWindow.window : null
  readonly property string hostScreenName: hostWindow && hostWindow.screen
    ? String(hostWindow.screen.name || "") : ""
  readonly property var colorPalette: [
    String(Color.background), String(Color.foreground), String(Color.accent),
    String(Color.urgent), String(Color.muted),
    "#F38BA8", "#FAB387", "#F9E2AF", "#A6E3A1", "#89DCEB", "#89B4FA", "#CBA6F7",
    "#000000", "#FFFFFF", "#808080", "#1E1E2E", "#282828", "#111318"
  ]
  readonly property var displayGeometries: {
    if (omosaicService && omosaicService.monitorLayout.length)
      return omosaicService.monitorLayout

    // Quickshell exposes output dimensions but not compositor coordinates.
    // Keep a visible horizontal fallback until the initial hyprctl read lands.
    var displays = []
    var x = 0
    for (var i = 0; i < Quickshell.screens.length; i++) {
      var screen = Quickshell.screens[i]
      var width = Number(screen.width || 1)
      displays.push({
        name: String(screen.name || ""),
        model: String(screen.model || ""),
        x: x,
        y: 0,
        width: width,
        height: Number(screen.height || 1)
      })
      x += width
    }
    return displays
  }
  readonly property var displayBounds: Model.layoutBounds(displayGeometries)
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
            property bool colorEditorOpen: false

            function applyHexColor() {
              var color = Model.normalizeColor(hexInput.text)
              if (color && root.omosaicService)
                root.omosaicService.setColorForKey(screenKey, color)
            }

            onColorEditorOpenChanged: {
              if (colorEditorOpen)
                hexInput.text = assignment && assignment.type === "color"
                  ? assignment.color : "#"
            }

            width: displayList.width
            height: cardContent.implicitHeight + Style.space(20)
            radius: Style.cornerRadius
            color: Util.alpha(Color.foreground, 0.045)
            border.width: 1
            border.color: Util.alpha(Color.foreground, 0.12)

            Column {
              id: cardContent
              x: Style.space(10)
              y: Style.space(10)
              width: parent.width - Style.space(20)
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
                    text: (displayCard.modelData.model || displayCard.modelData.name)
                      + (displayCard.modelData.name === root.hostScreenName ? " (this monitor)" : "")
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
                  fontFamily: root.bar.fontFamily
                  onActivated: {
                    displayCard.colorEditorOpen = false
                    root.popupOpen = false
                    if (root.omosaicService)
                      root.omosaicService.chooseImageForKey(displayCard.screenKey)
                  }
                }

                ActionButton {
                  width: (actions.width - actions.spacing * 2) / 3
                  label: "Solid color"
                  fontFamily: root.bar.fontFamily
                  onActivated: displayCard.colorEditorOpen = !displayCard.colorEditorOpen
                }

                ActionButton {
                  width: (actions.width - actions.spacing * 2) / 3
                  label: "Reset"
                  fontFamily: root.bar.fontFamily
                  available: displayCard.assignment !== null
                  onActivated: {
                    displayCard.colorEditorOpen = false
                    if (root.omosaicService)
                      root.omosaicService.clearAssignment(displayCard.screenKey)
                  }
                }
              }

              Column {
                id: colorEditor
                width: parent.width
                spacing: Style.space(8)
                visible: displayCard.colorEditorOpen

                Grid {
                  width: parent.width
                  columns: 8
                  columnSpacing: Style.space(7)
                  rowSpacing: Style.space(7)

                  Repeater {
                    model: root.colorPalette

                    Rectangle {
                      id: swatch
                      required property var modelData
                      width: Style.space(38)
                      height: Style.space(30)
                      radius: Style.cornerRadius > 0 ? Style.space(5) : 0
                      color: String(modelData)
                      border.width: displayCard.assignment
                        && displayCard.assignment.type === "color"
                        && Model.normalizeColor(displayCard.assignment.color) === Model.normalizeColor(modelData) ? 3 : 1
                      border.color: border.width === 3
                        ? Color.foreground : Util.alpha(Color.foreground, 0.25)

                      MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.omosaicService)
                          root.omosaicService.setColorForKey(displayCard.screenKey, String(swatch.modelData))
                      }
                    }
                  }
                }

                Row {
                  width: parent.width
                  spacing: Style.space(7)

                  Rectangle {
                    width: parent.width - applyHex.width - parent.spacing
                    height: Style.space(30)
                    radius: Style.cornerRadius > 0 ? height / 4 : 0
                    color: Util.alpha(Color.foreground, 0.06)
                    border.width: 1
                    border.color: Model.normalizeColor(hexInput.text)
                      ? Util.alpha(Color.foreground, 0.22) : Color.urgent

                    TextInput {
                      id: hexInput
                      anchors.fill: parent
                      anchors.leftMargin: Style.space(9)
                      anchors.rightMargin: Style.space(9)
                      verticalAlignment: TextInput.AlignVCenter
                      color: Color.foreground
                      selectionColor: Color.accent
                      selectedTextColor: Color.background
                      font.family: root.bar.fontFamily
                      font.pixelSize: Style.font.body
                      selectByMouse: true
                      maximumLength: 9
                      onAccepted: displayCard.applyHexColor()
                    }
                  }

                  ActionButton {
                    id: applyHex
                    width: Style.space(72)
                    label: "Apply"
                    fontFamily: root.bar.fontFamily
                    available: Model.normalizeColor(hexInput.text) !== ""
                    onActivated: displayCard.applyHexColor()
                  }
                }
              }
            }
          }
        }
      }

      Column {
        id: layoutSection
        width: parent.width
        spacing: Style.space(6)

        Text {
          text: "Display layout"
          color: Color.foreground
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.body
          font.bold: true
        }

        Rectangle {
          id: layoutCanvas
          width: parent.width
          height: Style.space(125)
          radius: Style.cornerRadius
          color: Util.alpha(Color.foreground, 0.035)
          border.width: 1
          border.color: Util.alpha(Color.foreground, 0.12)

          Repeater {
            model: root.displayGeometries

            Rectangle {
              id: monitorTile
              required property var modelData
              readonly property var mapped: Model.layoutRect(modelData,
                root.displayBounds, layoutCanvas.width, layoutCanvas.height, Style.space(10))
              readonly property bool current: modelData.name === root.hostScreenName

              x: mapped.x
              y: mapped.y
              width: mapped.width
              height: mapped.height
              radius: Style.cornerRadius > 0 ? Style.space(4) : 0
              color: current
                ? Util.alpha(Color.accent, 0.24)
                : Util.alpha(Color.foreground, 0.075)
              border.width: current ? 2 : 1
              border.color: current ? Color.accent : Util.alpha(Color.foreground, 0.32)

              Column {
                anchors.centerIn: parent
                width: parent.width - Style.space(8)
                spacing: 0

                Text {
                  width: parent.width
                  horizontalAlignment: Text.AlignHCenter
                  text: monitorTile.modelData.name
                  color: Color.foreground
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  elide: Text.ElideRight
                }

                Text {
                  width: parent.width
                  horizontalAlignment: Text.AlignHCenter
                  text: monitorTile.current ? "this monitor" : (monitorTile.modelData.model || "display")
                  color: Util.alpha(Color.foreground, 0.65)
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                  visible: monitorTile.height >= Style.space(34)
                }
              }
            }
          }
        }
      }
    }
  }
}
