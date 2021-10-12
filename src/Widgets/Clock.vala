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

public class Region {
    public Region (string name = "", int hour = 0, int minute = 0, bool enabled = true)
    {
        this.name = name;
        this.hour = hour;
        this.minute = minute;
        this.enabled = enabled;
    }

    public string name;
    public int hour;
    public int minute;
    public bool enabled;
}

namespace NotificationCenter {

    public class ClockWidget : Gtk.Box {
        public ClockWidget (List<Region> regions = new List<Region> ()) {
            var wrapper = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            wrapper.get_style_context ().add_class ("clock");

			var clock_box = new Box (Orientation.HORIZONTAL, 0);
			clock_box.get_style_context().add_class ("today_box_horizontal");

			var clock_image = new Image();
			clock_image.get_style_context().add_class ("today_image");
			clock_image.set_from_icon_name("time", IconSize.SMALL_TOOLBAR);

			var clock_app_name_label = new Gtk.Label("WORLD CLOCK");
			clock_app_name_label.get_style_context().add_class ("today_app_name");

            clock_box.add(clock_image);
            clock_box.add(clock_app_name_label);

			wrapper.add(clock_box);

			var clock_body_box = new Box (Orientation.HORIZONTAL, 0);
			clock_body_box.get_style_context().add_class ("today_box_body");

            var index = 0;
            foreach (var region in regions) {
                if (region.enabled) {
                    if (index == 3) {
                        wrapper.add(clock_body_box);
                        clock_body_box = new Box (Orientation.HORIZONTAL, 0);
                        clock_body_box.get_style_context().add_class ("today_box_body");
                        index = 0;
                    }
                    var clock_container_box = new Box (Orientation.VERTICAL, 0);
                    clock_container_box.get_style_context().add_class ("today_box_body_clock_widget");

                    var clock = new ClockWidgetDraw(region.name, region.hour, region.minute);
                    var clock_label = new Gtk.Label(region.name);

                    clock_container_box.add(clock);
                    clock_container_box.add(clock_label);

                    clock_body_box.add_with_properties (clock_container_box, "expand", true);
                    ++index;
                }
            }

			wrapper.add(clock_body_box);            

            this.add(wrapper);
        }
    }

    public class ClockWidgetDraw : DrawingArea {

        private Time time;
        private int minute_offset;
        private int hour_offset;
        private string loc;

        public signal void time_changed (int hour, int minute);

        public ClockWidgetDraw (string location, int hour_offset, int minute_offset) {
            update ();

			// Set widget size
        	set_size_request (80, 80);

        	this.loc = location;
        	this.hour_offset = hour_offset;
        	this.minute_offset = minute_offset;

            // update the clock once a second
            Timeout.add (1000, update);
        }

        public override bool draw (Cairo.Context cr) {
            var x = get_allocated_width () / 2;
            var y = get_allocated_height () / 2;
            var radius = double.min (get_allocated_width () / 2,
                                     get_allocated_height () / 2) - 5;


            // clock back
            cr.arc (x, y, radius, 0, 2 * Math.PI);

            // clock hands
            var hours = this.time.hour + this.hour_offset;
			var minutes = this.time.minute + (this.hour_offset >= 0 ? this.minute_offset : -this.minute_offset);
            var seconds = this.time.second;

    		if (((hours + 24) % 24) < 6 || ((hours + 24) % 24) >= 18) {
        		cr.set_source_rgb (0, 0, 0);
        		cr.fill_preserve ();
        		cr.set_source_rgb (1, 1, 1);
    		}
    		else {
        		cr.set_source_rgb (1, 1, 1);
        		cr.fill_preserve ();
        		cr.set_source_rgb (0, 0, 0);
    		}

            cr.stroke ();

            // clock ticks
            for (int i = 0; i < 12; i++) {
                int inset;

                cr.save ();     // stack pen-size

                if (i % 3 == 0) {
                    inset = (int) (0.2 * radius);
                } else {
                    inset = (int) (0.1 * radius);
                    cr.set_line_width (0.5 * cr.get_line_width ());
                }

                cr.move_to (x + (radius - inset) * Math.cos (i * Math.PI / 6),
                            y + (radius - inset) * Math.sin (i * Math.PI / 6));
                cr.line_to (x + radius * Math.cos (i * Math.PI / 6),
                            y + radius * Math.sin (i * Math.PI / 6));
                cr.stroke ();
                cr.restore ();  // stack pen-size
            }
                        
            // hour hand:
            // the hour hand is rotated 30 degrees (pi/6 r) per hour +
            // 1/2 a degree (pi/360 r) per minute
            cr.save ();
            cr.set_line_width (2.5 * cr.get_line_width ());
            cr.move_to (x, y);
            cr.line_to (x + radius / 2 * Math.sin (Math.PI / 6 * hours
                                                 + Math.PI / 360 * minutes),
                        y + radius / 2 * -Math.cos (Math.PI / 6 * hours
                                                  + Math.PI / 360 * minutes));
            cr.stroke ();
            cr.restore ();

            // minute hand:
            // the minute hand is rotated 6 degrees (pi/30 r) per minute
            cr.move_to (x, y);
            cr.line_to (x + radius * 0.75 * Math.sin (Math.PI / 30 * minutes),
                        y + radius * 0.75 * -Math.cos (Math.PI / 30 * minutes));
            cr.stroke ();
                        
            // seconds hand:
            // operates identically to the minute hand
            cr.save ();
            cr.set_source_rgb (1, 0, 0); // red
            cr.move_to (x, y);
            cr.line_to (x + radius * 0.7 * Math.sin (Math.PI / 30 * seconds),
                        y + radius * 0.7 * -Math.cos (Math.PI / 30 * seconds));
            cr.stroke ();
            cr.restore ();

            return false;
        }

        private bool update () {
            // update the time
            this.time = Time.gm (time_t());
            redraw_canvas ();
            return true;        // keep running this event
        }

        private void redraw_canvas () {
            var window = get_window ();
            if (null == window) {
                return;
            }

            var region = window.get_clip_region ();
            // redraw the cairo canvas completely by exposing it
            window.invalidate_region (region, true);
            window.process_updates (true);
        }
    }
}
