#!/usr/bin/env python
""" a minimalistic example from python gtk3 tutorial

to have something opening when one double-clicks pythonbase.app
"""
import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk


if __name__ == '__main__':
	win = Gtk.Window()
	win.connect("destroy", Gtk.main_quit)
	win.show_all()
	Gtk.main()
