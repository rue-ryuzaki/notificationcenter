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

namespace NotificationCenter {
    public class NowPlayingWidget : Gtk.Box {
        public NowPlayingWidget () {
            var wrapper = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            wrapper.get_style_context ().add_class ("nowplaying");

            var nowplaying_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            nowplaying_box.get_style_context().add_class ("today_box_horizontal");

            var nowplaying_image = new Gtk.Image();
            nowplaying_image.get_style_context().add_class ("today_image");
            nowplaying_image.set_from_icon_name("gnome-music", Gtk.IconSize.SMALL_TOOLBAR);

            var nowplaying_app_name_label = new Gtk.Label("NOW PLAYING");
            nowplaying_app_name_label.get_style_context().add_class ("today_app_name");

            nowplaying_box.add(nowplaying_image);
            nowplaying_box.add(nowplaying_app_name_label);

            wrapper.add (nowplaying_box);

            var nowplaying_body_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            nowplaying_body_box.get_style_context ().add_class ("today_box_body");

            var watcher = new Mpris2Watcher();
            watcher.client_appeared.connect ((name) => {
                var controller = new Mpris2Controller (name);
                var prev_button = new Gtk.Button.with_label ("<<");
                prev_button.set_sensitive (false);
                prev_button.clicked.connect (() => { controller.player.Previous.begin (); });
                var play_button = new Gtk.Button.with_label (controller.player.PlaybackStatus == "Playing" ? "||" : ">");
                play_button.set_sensitive (false);
                play_button.clicked.connect (() => { controller.player.PlayPause.begin (); });
                var next_button = new Gtk.Button.with_label (">>");
                next_button.set_sensitive (false);
                next_button.clicked.connect (() => { controller.player.Next.begin (); });
                var label = new Gtk.Label (controller.player.Metadata.lookup ("xesam:title")?.get_string ());
                label.set_ellipsize (Pango.EllipsizeMode.START);
                label.set_alignment (0.0f, 0.5f);
                label.selectable = true;
                label.can_focus = false;
                label.set_single_line_mode (true);

                var image = new Gtk.Image ();
                image.get_style_context ().add_class ("today_image");
                image.set_from_icon_name (name.replace (MPRIS_PREFIX, "").split (".")[0], Gtk.IconSize.SMALL_TOOLBAR);

                Timeout.add (250, () =>
                {
                    prev_button.set_sensitive (controller.player.CanGoPrevious);
                    play_button.set_sensitive (controller.player.CanPlay);
                    next_button.set_sensitive (controller.player.CanGoNext);
                    play_button.set_label (controller.player.PlaybackStatus == "Playing" ? "||" : ">");
                    var metadata = controller.player.Metadata;
                    label.set_text (metadata.lookup ("xesam:title")?.get_string ());
                    return true;
                });

                var player_body_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
                player_body_box.get_style_context ().add_class ("player");
                player_body_box.add (image);
                player_body_box.add (prev_button);
                player_body_box.add (play_button);
                player_body_box.add (next_button);
                player_body_box.add (label);
                nowplaying_body_box.add (player_body_box);
                this.show_all ();
            });
            watcher.check_for_active_clients.begin ();

            wrapper.add (nowplaying_body_box);

            this.add(wrapper);
        }
    }
}
