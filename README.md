# Omosaic

**Different walls for every display.**

Omosaic is a multi-display wallpaper service for the Omarchy Quattro shell. It replaces Omarchy's stock background renderer while preserving the standard `background` IPC target and global wallpaper fallback.

![Omosaic panel showing wallpaper controls for three displays](preview.png)

## Current features

- Manage every connected display from an Omarchy bar widget.
- Assign a different image to each connected display.
- Browse backgrounds from every installed stock and user theme.
- Pick custom image files outside the Omarchy theme library.
- Assign solid colors, including custom hex colors.
- Use any of the 382 uiGradients presets with a custom angle.
- Remember displays by manufacturer, model, and serial number when available.
- Fall back to the connector name and Omarchy's current global background.
- React to monitor hotplug through `Quickshell.screens`.

## Install

```bash
omarchy plugin add https://github.com/lgse/omosaic.git --enable
```

Plugins run as unsandboxed code inside `omarchy-shell`. Review third-party plugin code before enabling it.

## Use

Click the **Omosaic** icon in the Omarchy bar. Its panel lists every connected display with three actions:

- **Themes** browses backgrounds from all installed Omarchy themes.
- **File** selects an image from your Pictures or Downloads folders.
- **Solid color** offers presets and custom hex colors.
- **Gradient** provides an in-panel, scrollable gallery of all 382 uiGradients and a custom angle.
- **Reset** returns that display to Omarchy's global background.

Assignments are stored in:

```text
~/.config/omarchy/omosaic/assignments.json
```

The plugin never modifies files under `/usr/share/omarchy`.

## IPC

Omosaic retains Omarchy's `background` IPC target and adds these methods:

```bash
omarchy-shell -q background setForScreen DP-3 /path/to/wallpaper.png
omarchy-shell -q background setColorForScreen DP-4 '#111318'
omarchy-shell -q background clearForScreen DP-3
omarchy-shell -q background assignments
```

A serial-backed key shown by `assignments` is preferred over a connector such as `DP-3` because connector names may change.

## Compatibility behavior

- `omarchy theme bg set` changes the fallback used by displays without an explicit assignment.
- Theme changes preserve explicit per-display assignments.
- The lock screen continues to use Omarchy's global current background.
- Disabling or removing Omosaic restores the stock `omarchy.background` service.

## Roadmap

- A spatial display-map editor.
- Group wallpaper results by theme.
- Optional hyprmoncfg profile and hotplug integration.
- Profile-specific wallpaper sets.
- Animated background transitions.

## Development

Requirements: Node.js and an installed Omarchy system for QML integration testing.

```bash
npm test
omarchy plugin validate .
```

## License

[MIT](LICENSE). Gradient names and colors are sourced from the MIT-licensed [uiGradients](https://uigradients.com/) project; see [third-party notices](THIRD_PARTY_NOTICES.md).
