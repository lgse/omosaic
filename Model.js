function text(value) {
  return String(value || "").trim()
}

function screenKeys(name, manufacturer, model, serialNumber) {
  var connector = text(name)
  var make = text(manufacturer)
  var product = text(model)
  var serial = text(serialNumber)
  var keys = []

  // A serial-backed identity survives connector renumbering and layout changes.
  if (serial) keys.push([make, product, serial].filter(Boolean).join(":"))
  if (connector) keys.push(connector)
  return keys
}

function emptyState() {
  return { version: 1, displays: {} }
}

function normalizeAssignment(value) {
  if (!value || typeof value !== "object") return null
  if (value.type === "image" && text(value.path))
    return { type: "image", path: text(value.path) }
  if (value.type === "color") {
    var color = normalizeColor(value.color)
    if (color) return { type: "color", color: color }
  }
  return null
}

function normalizeColor(value) {
  var color = text(value)
  if (!/^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(color)) return ""
  return color.toUpperCase()
}

function parseState(raw) {
  try {
    var parsed = JSON.parse(String(raw || ""))
    if (!parsed || typeof parsed !== "object" || parsed.version !== 1)
      return emptyState()

    var source = parsed.displays && typeof parsed.displays === "object"
      ? parsed.displays : {}
    var displays = {}
    Object.keys(source).forEach(function(key) {
      var assignment = normalizeAssignment(source[key])
      if (text(key) && assignment) displays[text(key)] = assignment
    })
    return { version: 1, displays: displays }
  } catch (error) {
    return emptyState()
  }
}

function parseMonitorLayout(raw) {
  try {
    var monitors = JSON.parse(String(raw || "[]"))
    if (!(monitors instanceof Array)) return []

    return monitors.filter(function(monitor) {
      return monitor && monitor.disabled !== true
    }).map(function(monitor) {
      var scale = Math.max(0.01, Number(monitor.scale || 1))
      var transform = Number(monitor.transform || 0)
      var rotated = transform === 1 || transform === 3 || transform === 5 || transform === 7
      var physicalWidth = Math.max(1, Number(monitor.width || 1))
      var physicalHeight = Math.max(1, Number(monitor.height || 1))
      return {
        id: Number(monitor.id || 0),
        name: text(monitor.name) || "Display",
        model: text(monitor.model),
        serial: text(monitor.serial),
        x: Number(monitor.x || 0),
        y: Number(monitor.y || 0),
        width: (rotated ? physicalHeight : physicalWidth) / scale,
        height: (rotated ? physicalWidth : physicalHeight) / scale,
        transform: transform,
        focused: monitor.focused === true
      }
    })
  } catch (error) {
    return []
  }
}

function layoutBounds(displays) {
  var list = displays instanceof Array ? displays : []
  if (!list.length) return { x: 0, y: 0, width: 1, height: 1 }

  var minX = Infinity
  var minY = Infinity
  var maxX = -Infinity
  var maxY = -Infinity
  list.forEach(function(display) {
    var x = Number(display.x || 0)
    var y = Number(display.y || 0)
    var width = Math.max(1, Number(display.width || 1))
    var height = Math.max(1, Number(display.height || 1))
    minX = Math.min(minX, x)
    minY = Math.min(minY, y)
    maxX = Math.max(maxX, x + width)
    maxY = Math.max(maxY, y + height)
  })

  return { x: minX, y: minY, width: maxX - minX, height: maxY - minY }
}

function layoutRect(display, bounds, canvasWidth, canvasHeight, padding) {
  var item = display || {}
  var area = bounds || layoutBounds([])
  var pad = Math.max(0, Number(padding || 0))
  var availableWidth = Math.max(1, Number(canvasWidth || 1) - pad * 2)
  var availableHeight = Math.max(1, Number(canvasHeight || 1) - pad * 2)
  var scale = Math.min(availableWidth / Math.max(1, area.width), availableHeight / Math.max(1, area.height))
  var drawnWidth = area.width * scale
  var drawnHeight = area.height * scale
  var offsetX = pad + (availableWidth - drawnWidth) / 2
  var offsetY = pad + (availableHeight - drawnHeight) / 2

  return {
    x: offsetX + (Number(item.x || 0) - area.x) * scale,
    y: offsetY + (Number(item.y || 0) - area.y) * scale,
    width: Math.max(1, Number(item.width || 1) * scale),
    height: Math.max(1, Number(item.height || 1) * scale)
  }
}

function assignmentFor(state, keys) {
  var displays = state && state.displays && typeof state.displays === "object"
    ? state.displays : {}
  var candidates = keys instanceof Array ? keys : []
  for (var i = 0; i < candidates.length; i++) {
    var assignment = normalizeAssignment(displays[candidates[i]])
    if (assignment) return assignment
  }
  return null
}

if (typeof module !== "undefined") {
  module.exports = {
    screenKeys: screenKeys,
    emptyState: emptyState,
    normalizeAssignment: normalizeAssignment,
    normalizeColor: normalizeColor,
    parseState: parseState,
    parseMonitorLayout: parseMonitorLayout,
    layoutBounds: layoutBounds,
    layoutRect: layoutRect,
    assignmentFor: assignmentFor
  }
}
