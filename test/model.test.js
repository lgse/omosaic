const test = require("node:test")
const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const Model = require("../Model.js")
const Gradients = require("../Gradients.js")

const root = path.resolve(__dirname, "..")

test("serial identity is preferred and connector remains a fallback", () => {
  assert.deepEqual(
    Model.screenKeys("DP-3", "Samsung", "U32J59x", "HCJTB01500"),
    ["Samsung:U32J59x:HCJTB01500", "DP-3"]
  )
})

test("connector is used when hardware identity has no serial", () => {
  assert.deepEqual(Model.screenKeys("eDP-1", "BOE", "Display", ""), ["eDP-1"])
})

test("Hyprland monitor layout uses logical dimensions and rotation", () => {
  const layout = Model.parseMonitorLayout(JSON.stringify([
    { id: 0, name: "DP-3", x: 0, y: 900, width: 2560, height: 1440, scale: 1.6, transform: 0 },
    { id: 1, name: "DP-4", x: 0, y: 0, width: 2560, height: 1440, scale: 1.6, transform: 0 },
    { id: 2, name: "DP-5", x: 1600, y: 338, width: 2560, height: 1440, scale: 1.6, transform: 3 }
  ]))

  assert.deepEqual(layout.map(({ name, x, y, width, height }) => ({ name, x, y, width, height })), [
    { name: "DP-3", x: 0, y: 900, width: 1600, height: 900 },
    { name: "DP-4", x: 0, y: 0, width: 1600, height: 900 },
    { name: "DP-5", x: 1600, y: 338, width: 900, height: 1600 }
  ])
})

test("uiGradients catalog is complete and searchable", () => {
  assert.equal(Gradients.gradients.length, 382)
  assert.deepEqual(Gradients.byName("Deep Space").colors, ["#000000", "#434343"])
})

test("gradient assignments normalize colors and arbitrary angles", () => {
  assert.deepEqual(Model.normalizeAssignment({
    type: "gradient",
    name: "Test",
    colors: ["#aabbcc", "#112233"],
    angle: -45
  }), {
    type: "gradient",
    name: "Test",
    colors: ["#AABBCC", "#112233"],
    angle: 315
  })
})

test("state parser keeps valid assignments and drops invalid values", () => {
  const state = Model.parseState(JSON.stringify({
    version: 1,
    displays: {
      "DP-3": { type: "image", path: "/tmp/wall.png" },
      "DP-4": { type: "color", color: "#aabbcc" },
      broken: { type: "color", color: "red" }
    }
  }))

  assert.deepEqual(state.displays, {
    "DP-3": { type: "image", path: "/tmp/wall.png" },
    "DP-4": { type: "color", color: "#AABBCC" }
  })
})

test("display layout preserves monitor positions and proportions", () => {
  const displays = [
    { x: 0, y: 0, width: 1920, height: 1080 },
    { x: 1920, y: -360, width: 2560, height: 1440 }
  ]
  const bounds = Model.layoutBounds(displays)
  assert.deepEqual(bounds, { x: 0, y: -360, width: 4480, height: 1440 })

  const left = Model.layoutRect(displays[0], bounds, 448, 144, 0)
  const right = Model.layoutRect(displays[1], bounds, 448, 144, 0)
  assert.equal(left.x, 0)
  assert.equal(right.x, 192)
  assert.equal(right.y, 0)
  assert.equal(right.width, 256)
})

test("assignment lookup follows stable-to-fallback key order", () => {
  const state = {
    version: 1,
    displays: {
      "Samsung:U32J59x:SERIAL": { type: "color", color: "#112233" },
      "DP-3": { type: "color", color: "#445566" }
    }
  }

  assert.deepEqual(
    Model.assignmentFor(state, ["Samsung:U32J59x:SERIAL", "DP-3"]),
    { type: "color", color: "#112233" }
  )
})

test("manifest replaces the stock background service", () => {
  const manifest = JSON.parse(fs.readFileSync(path.join(root, "manifest.json"), "utf8"))
  assert.equal(manifest.schemaVersion, 1)
  assert.equal(manifest.omarchy.clonedFrom, "omarchy.background")
  assert.ok(manifest.kinds.includes("service"))
  assert.ok(manifest.kinds.includes("bar-widget"))
  assert.equal(manifest.entryPoints.service, "Omosaic.qml")
  assert.equal(manifest.entryPoints.barWidget, "Widget.qml")
  assert.equal(manifest.barWidget.defaultSection, "right")
})

test("renderer preserves stock IPC and exposes per-screen methods", () => {
  const qml = fs.readFileSync(path.join(root, "Omosaic.qml"), "utf8")
  assert.match(qml, /target: "background"/)
  assert.match(qml, /function themeTransition\(/)
  assert.match(qml, /function setForScreen\(/)
  assert.match(qml, /function setColorForScreen\(/)
  assert.match(qml, /model: Quickshell\.screens/)
  assert.match(qml, /command: \["hyprctl", "monitors", "-j"\]/)
  assert.match(qml, /chooseFileForKey/)
  assert.match(qml, /chooseGradientForKey/)
  assert.match(qml, /GradientSurface/)
  assert.doesNotMatch(qml, /onDoubleClicked/)
})

test("bar widget exposes per-display wallpaper controls", () => {
  const qml = fs.readFileSync(path.join(root, "Widget.qml"), "utf8")
  assert.match(qml, /serviceFor\("lgse\.omosaic"\)/)
  assert.match(qml, /model: Quickshell\.screens/)
  assert.match(qml, /chooseImageForKey/)
  assert.match(qml, /colorPalette/)
  assert.match(qml, /setColorForKey/)
  assert.match(qml, /Model\.normalizeColor\(hexInput\.text\)/)
  assert.match(qml, /hostWindow\.screen/)
  assert.match(qml, /\(this monitor\)/)
  assert.match(qml, /text: "Display layout"/)
  assert.match(qml, /Model\.layoutRect/)
  assert.match(qml, /model: root\.displayGeometries/)
  assert.ok((qml.match(/displayCard\.colorEditorOpen = false/g) || []).length >= 3)
  assert.match(qml, /All 382 gradients/)
  assert.match(qml, /gradientAngleInput/)
  assert.match(qml, /chooseFileForKey/)
  assert.match(qml, /clearAssignment/)
})
