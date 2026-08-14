#!/usr/bin/env python3
"""Open a GTK file dialog out of process and print the selected image path."""

from pathlib import Path
import sys

import gi

gi.require_version("Gtk", "4.0")
from gi.repository import Gio, GLib, Gtk  # noqa: E402


def main() -> int:
    dialog = Gtk.FileDialog(title="Choose a wallpaper", modal=True)

    image_filter = Gtk.FileFilter(name="Images")
    for pattern in ("*.jpg", "*.jpeg", "*.png", "*.gif", "*.bmp", "*.webp"):
        image_filter.add_pattern(pattern)
        image_filter.add_pattern(pattern.upper())

    all_filter = Gtk.FileFilter(name="All files")
    all_filter.add_pattern("*")

    filters = Gio.ListStore.new(Gtk.FileFilter)
    filters.append(image_filter)
    filters.append(all_filter)
    dialog.set_filters(filters)
    dialog.set_default_filter(image_filter)

    pictures = Path.home() / "Pictures"
    dialog.set_initial_folder(Gio.File.new_for_path(str(pictures if pictures.is_dir() else Path.home())))

    loop = GLib.MainLoop()
    selected = {"path": ""}

    def completed(source, result):
        try:
            file = source.open_finish(result)
            selected["path"] = file.get_path() or ""
        except GLib.Error:
            pass
        finally:
            loop.quit()

    dialog.open(None, None, completed)
    loop.run()

    if selected["path"]:
        print(selected["path"], flush=True)
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
