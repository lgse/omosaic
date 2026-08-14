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
    assignmentFor: assignmentFor
  }
}
