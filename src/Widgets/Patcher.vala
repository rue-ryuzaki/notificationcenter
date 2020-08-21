/*
* Copyright (c) 2011-2020 NotificationCenter
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Kris Henriksen <krishenriksen.work@gmail.com>
*/

using Gtk;
using GLib;

namespace NotificationCenter {
    public class PatcherWidget : Gtk.Box {
    	private static string user_home = GLib.Environment.get_variable ("HOME");

        public PatcherWidget () {
            var wrapper = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            wrapper.get_style_context ().add_class ("patcher");

			var patcher_box = new Box (Orientation.HORIZONTAL, 0);
			patcher_box.get_style_context().add_class ("today_box_horizontal");

			var patcher_image = new Image();
			patcher_image.get_style_context().add_class ("today_image");
			patcher_image.set_from_icon_name("rabbitvcs-applypatch", IconSize.SMALL_TOOLBAR);

			var patcher_app_name_label = new Gtk.Label("Twister-OS-Patcher");
			patcher_app_name_label.get_style_context().add_class ("today_app_name");

            patcher_box.add(patcher_image);
            patcher_box.add(patcher_app_name_label);

			var patcher_body_box = new Box (Orientation.HORIZONTAL, 0);
			patcher_body_box.get_style_context().add_class ("today_box_body");

			var button = new Gtk.Button.with_label ("Patch TwisterOS to the latest version");

			button.clicked.connect (() => {
		        try {
		        	GLib.AppInfo info = AppInfo.create_from_commandline("xfce4-terminal --title=Patcher --hide-menubar --hide-borders --hide-scrollbar -e \"" + user_home + "/patcher/patch.sh\"", null, AppInfoCreateFlags.SUPPORTS_STARTUP_NOTIFICATION);
		        	info.launch(null,Gdk.Display.get_default().get_app_launch_context());
		        } catch (GLib.Error e){warning ("Could not load patcher: %s", e.message);}
			});

            patcher_body_box.add(button);

			wrapper.add(patcher_box);
			wrapper.add(patcher_body_box);            

            this.add(wrapper);
        }
    }
}