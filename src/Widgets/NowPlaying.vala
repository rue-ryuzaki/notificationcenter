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

namespace NotificationCenter {
    public class NowPlayingWidget : Gtk.Box {
        public NowPlayingWidget () {
            var wrapper = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
            this.add (wrapper);

            var label = new Gtk.Label ("No info");
            // Mode to compress the text and add "..."
            label.set_ellipsize (Pango.EllipsizeMode.START);
            label.set_alignment(0.0f, 0.5f);
            label.selectable = true;
            label.can_focus = false;
            label.set_single_line_mode (true);
            wrapper.pack_start (label, true, true, 0);
            
            this.draw.connect (this.draw_background);
        }

        private bool draw_background (Gtk.Widget widget, Cairo.Context ctx) {
            widget.get_style_context ().add_class ("nowplaying");
            return false;
        }
    }
}