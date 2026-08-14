const test = require("node:test")
const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const Model = require("../Model.js")

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
  assert.doesNotMatch(qml, /onDoubleClicked/)
})

test("bar widget exposes per-display wallpaper controls", () => {
  const qml = fs.readFileSync(path.join(root, "Widget.qml"), "utf8")
  assert.match(qml, /serviceFor\("lgse\.omosaic"\)/)
  assert.match(qml, /model: Quickshell\.screens/)
  assert.match(qml, /chooseImageForKey/)
  assert.match(qml, /chooseColorForKey/)
  assert.match(qml, /clearAssignment/)
})
