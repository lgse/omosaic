import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Dialogs
import QtCore
import qs.Commons
import qs.Ui
import "Model.js" as Model
import "Gradients.js" as Gradients

Item {
  id: root

  readonly property string home: Quickshell.env("HOME")
  readonly property string stateDirectory: home + "/.config/omarchy/omosaic"
  readonly property string statePath: stateDirectory + "/assignments.json"
  readonly property string currentBackgroundLink: home + "/.local/state/omarchy/current/background"

  property var configState: Model.emptyState()
  property var monitorLayout: []
  readonly property var gradientPresets: Gradients.gradients
  property string defaultBackground: ""
  property string pickerScreenKey: ""
  property string filePickerScreenKey: ""

  function keysForScreen(screen) {
    return Model.screenKeys(screen.name, screen.manufacturer, screen.model, screen.serialNumber)
  }

  function keyForScreen(screen) {
    var keys = keysForScreen(screen)
    return keys.length ? keys[0] : "unknown-display"
  }

  function assignmentForScreen(screen) {
    return Model.assignmentFor(configState, keysForScreen(screen))
  }

  function refreshMonitorLayout() {
    if (!monitorLayoutReader.running) monitorLayoutReader.running = true
  }

  function saveState(next) {
    configState = next
    stateFile.setText(JSON.stringify(next, null, 2) + "\n")
  }

  function setAssignment(key, assignment) {
    key = String(key || "").trim()
    assignment = Model.normalizeAssignment(assignment)
    if (!key || !assignment) return false

    var next = Model.parseState(JSON.stringify(configState))
    next.displays[key] = assignment
    saveState(next)
    return true
  }

  function clearAssignment(key) {
    key = String(key || "").trim()
    if (!key || !configState.displays[key]) return false

    var next = Model.parseState(JSON.stringify(configState))
    delete next.displays[key]
    saveState(next)
    return true
  }

  function applyThemePayload(colorsB64, shellB64) {
    if (colorsB64) Color.loadColors(Util.decodeBase64(colorsB64))
    if (shellB64) Color.loadShell(Util.decodeBase64(shellB64))
    Style.scheduleRefresh()
  }

  function chooseImageForKey(screenKey) {
    if (imagePicker.running) return
    pickerScreenKey = String(screenKey || "").trim()
    if (pickerScreenKey) imagePicker.running = true
  }

  function setColorForKey(screenKey, color) {
    return setAssignment(screenKey, { type: "color", color: color })
  }

  function gradientByName(name) {
    return Gradients.byName(String(name || ""))
  }

  function setGradientForKey(screenKey, name, angle) {
    var preset = gradientByName(name)
    if (!preset) return false
    return setAssignment(screenKey, {
      type: "gradient",
      name: preset.name,
      colors: preset.colors,
      angle: angle
    })
  }

  function chooseFileForKey(screenKey) {
    filePickerScreenKey = String(screenKey || "").trim()
    if (!filePickerScreenKey) return
    var pictures = String(StandardPaths.writableLocation(StandardPaths.PicturesLocation) || "")
    nativeFilePicker.currentFolder = Util.fileUrl(pictures || home)
    nativeFilePicker.open()
  }

  Process {
    id: prepareStateDirectory
    command: ["mkdir", "-p", root.stateDirectory]
    Component.onCompleted: running = true
  }

  FileView {
    id: stateFile
    path: root.statePath
    watchChanges: true
    printErrors: false
    onLoaded: root.configState = Model.parseState(text())
    onLoadFailed: root.configState = Model.emptyState()
    onFileChanged: reload()
  }

  FileDialog {
    id: nativeFilePicker
    title: "Choose a wallpaper"
    fileMode: FileDialog.OpenFile
    nameFilters: ["Images (*.jpg *.jpeg *.png *.gif *.bmp *.webp)", "All files (*)"]

    onAccepted: {
      var url = String(selectedFile || "")
      var path = url.indexOf("file://") === 0
        ? decodeURIComponent(url.substring(7)) : decodeURIComponent(url)
      if (path && root.filePickerScreenKey)
        root.setAssignment(root.filePickerScreenKey, { type: "image", path: path })
      root.filePickerScreenKey = ""
    }

    onRejected: root.filePickerScreenKey = ""
  }

  Process {
    id: monitorLayoutReader
    command: ["hyprctl", "monitors", "-j"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.monitorLayout = Model.parseMonitorLayout(text)
    }
  }

  Connections {
    target: Quickshell
    function onScreensChanged() { root.refreshMonitorLayout() }
  }

  Timer {
    interval: 5000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refreshMonitorLayout()
  }

  Process {
    id: backgroundReader
    command: ["readlink", "-f", root.currentBackgroundLink]
    stdout: StdioCollector {
      onStreamFinished: {
        var path = String(text || "").trim()
        if (path) root.defaultBackground = path
      }
    }
  }

  Timer {
    interval: 1500
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: if (!backgroundReader.running) backgroundReader.running = true
  }

  Process {
    id: imagePicker
    command: ["bash", "-lc", '\n      dirs=()\n      while IFS= read -r -d "" dir; do dirs+=("$dir"); done < <(\n        find /usr/share/omarchy/themes "$HOME/.config/omarchy/themes" \\\n          -mindepth 2 -maxdepth 2 -type d -name backgrounds -print0 2>/dev/null\n        find "$HOME/.config/omarchy/backgrounds" \\\n          -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null\n      )\n      (( ${#dirs[@]} )) || exit 1\n      omarchy-menu-images --show-labels --filterable --lazy-thumbnails "${dirs[@]}"\n    ']
    stdout: StdioCollector {
      onStreamFinished: {
        var path = String(text || "").trim()
        if (path && root.pickerScreenKey)
          root.setAssignment(root.pickerScreenKey, { type: "image", path: path })
      }
    }
  }

  IpcHandler {
    // Keep Omarchy's stock target and methods so theme commands continue to work
    // when this replacement service is enabled.
    target: "background"

    function refresh(): void {
      if (!backgroundReader.running) backgroundReader.running = true
    }

    function set(path: string): void { root.defaultBackground = path }
    function setInstant(path: string): void { root.defaultBackground = path }
    function transition(fromPath: string, path: string): void { root.defaultBackground = path }

    function themeTransition(fromPath: string, path: string, finalPath: string,
                             colorsB64: string, shellB64: string): void {
      root.defaultBackground = finalPath || path
      root.applyThemePayload(colorsB64, shellB64)
    }

    function setForScreen(screenKey: string, path: string): string {
      return root.setAssignment(screenKey, { type: "image", path: path }) ? "ok" : "invalid"
    }

    function setColorForScreen(screenKey: string, color: string): string {
      return root.setAssignment(screenKey, { type: "color", color: color }) ? "ok" : "invalid"
    }

    function clearForScreen(screenKey: string): string {
      return root.clearAssignment(screenKey) ? "ok" : "missing"
    }

    function assignments(): string {
      return JSON.stringify(root.configState)
    }

    function layout(): string {
      return JSON.stringify(root.monitorLayout)
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: panel
      required property var modelData
      screen: modelData
      visible: !remapGuard.remapping
      anchors { top: true; bottom: true; left: true; right: true }
      color: "transparent"

      property var assignment: root.assignmentForScreen(modelData)
      property bool solid: assignment && assignment.type === "color"
      property bool gradientSurface: assignment && assignment.type === "gradient"
      property string imagePath: assignment && assignment.type === "image"
        ? assignment.path : root.defaultBackground

      ScreenMoveRemap {
        id: remapGuard
        window: panel
      }

      WlrLayershell.namespace: "omosaic-background"
      WlrLayershell.layer: WlrLayer.Background
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore

      Rectangle {
        anchors.fill: parent
        color: panel.solid ? panel.assignment.color : "#000000"
      }

      GradientSurface {
        anchors.fill: parent
        visible: panel.gradientSurface
        colors: panel.gradientSurface ? panel.assignment.colors : []
        angle: panel.gradientSurface ? panel.assignment.angle : 0
      }

      Image {
        anchors.fill: parent
        visible: !panel.solid && !panel.gradientSurface && panel.imagePath !== ""
        source: visible ? Util.fileUrl(panel.imagePath) : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        smooth: true
        mipmap: true
      }

    }
  }
}
