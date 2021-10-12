using Gtk;

public class Settings {
    public Settings ()
    {
        dark_theme = true;
        now_playing = true;
        world_clock = true;
        regions = new List<Region> ();
        calendar = true;
    }

    public void init ()
    {
        dark_theme = true;
        now_playing = true;
        world_clock = true;
        regions = new List<Region> ();
        calendar = true;
    }

    public bool load ()
    {
        var file = File.new_for_path (user_home + filename);
        if (file.query_exists ()) {
            var dark_theme = true;
            var now_playing = true;
            var world_clock = true;
            var regions = new List<Region> ();
            var calendar = true;
            try {
                var dis = new DataInputStream (file.read ());
                string line;
                while (true) {
                    line = dis.read_line (null);
                    if (line != null && line != "") {
                        if (line.has_prefix ("dark_theme=")) {
                            dark_theme = bool.parse (line.replace ("dark_theme=", ""));
                        }
                        if (line.has_prefix ("now_playing=")) {
                            now_playing = bool.parse (line.replace ("now_playing=", ""));
                        }
                        if (line.has_prefix ("world_clock=")) {
                            world_clock = bool.parse (line.replace ("world_clock=", ""));
                        }
                        if (line.has_prefix ("calendar=")) {
                            calendar = bool.parse (line.replace ("calendar=", ""));
                        }
                        if (line.has_prefix ("region=")) {
                            var region_str = line.replace ("region=", "");
                            string[] region_str_split = region_str.split (";");
                            var region = new Region ();
                            region.name = region_str_split[0];
                            region.hour = int.parse (region_str_split[1]);
                            region.minute = int.parse (region_str_split[2]);
                            region.enabled = bool.parse (region_str_split[3]);
                            regions.insert (region, -1);
                        }
                    }
                    if (line == null) {
                        break;
                    }
                }
            } catch (Error e) {
                warning (e.message);
                return false;
            }
            this.dark_theme = dark_theme;
            this.now_playing = now_playing;
            this.world_clock = world_clock;
            this.regions.concat ((owned)regions);
            this.calendar = calendar;
            return true;
        }
        return false;
    }

    public void save ()
    {
        var file = File.new_for_path (user_home + filename);
        if (file.query_exists ()) {
            file.delete ();
        }
        var dos = new DataOutputStream (file.create (FileCreateFlags.REPLACE_DESTINATION));

        dos.put_string ("dark_theme=" + dark_theme.to_string () + "\n");
        dos.put_string ("now_playing=" + now_playing.to_string () + "\n");
        dos.put_string ("world_clock=" + world_clock.to_string () + "\n");
        dos.put_string ("calendar=" + calendar.to_string () + "\n");
        foreach (var element in regions) {
            dos.put_string ("region=" + element.name.to_string () + ";" + element.hour.to_string() + ";" + element.minute.to_string() + ";" + element.enabled.to_string() + "\n");
        }
    }

    public bool dark_theme;
    public bool now_playing;
    public bool world_clock;
    public List<Region> regions;
    public bool calendar;

    private static string user_home = GLib.Environment.get_home_dir ();
    private static string filename = "/.config/notificationcenter.conf";
}

public class ListBoxRowWithData: Gtk.ListBoxRow {
    // we are not using liststore or any data model here
    // we simply extend ListBoxRow class for handling rows easily
    public string name;
    public int hour;
    public int minute;
    public bool enabled;

    public Gtk.Entry entry_name;
    public Gtk.SpinButton entry_hour;
    public Gtk.SpinButton entry_minute;
    public Gtk.Switch entry_enabled;

    public bool eXpanded = false;

    public static int nm_width;
    public static int hr_width;
    public static int mn_width;
    public static int en_width;

    public ListBoxRowWithData (string _name, int _hour, int _minute, bool _enabled)
    {
        name = _name; hour = _hour; minute = _minute; enabled = _enabled;

        entry_name = new Gtk.Entry ();
        entry_name.set_text (name);
        entry_name.placeholder_text = "Name";
        entry_hour = new Gtk.SpinButton.with_range (-12, 12, 1);
        entry_hour.set_value (hour);
        entry_minute = new Gtk.SpinButton.with_range (0, 60, 15);
        entry_minute.set_value (minute);
        entry_enabled = new Gtk.Switch ();
        entry_enabled.set_halign (Align.END);
        entry_enabled.set_active (enabled);

        Gtk.Box rbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        Gtk.Box inner_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

        inner_box.pack_start (entry_name, true, true, 0);
        inner_box.pack_start (entry_hour, true, true, 0);
        inner_box.pack_start (entry_minute, true, true, 0);
        inner_box.pack_start (entry_enabled, true, true, 0);

        rbox.pack_start (inner_box, true, true, 0);

        this.add (rbox);
    }

    public void init_widths ()
    {
        if (nm_width == 0) {
            nm_width = entry_name.get_allocated_width ();
            hr_width = entry_hour.get_allocated_width ();
            mn_width = entry_minute.get_allocated_width ();
            en_width = entry_enabled.get_allocated_width ();
        }
    }
}

public class SettingsWindow : Dialog {
    private NotificationCenterWindow main_window;

    private Switch dark_theme;
    private Switch now_playing;
    private Switch world_clock;
    private ListBox regions;
    private Box fake_header;
    private Switch calendar;
    private Settings settings;

    public SettingsWindow (NotificationCenterWindow window, Settings settings)
    {
        this.main_window = window;
        this.settings = settings;
        this.title = "Settings";
        this.border_width = 5;
        set_default_size (350, 100);
        create_widgets ();
        setup_widgets ();
        connect_signals ();

        this.destroy.connect (Gtk.main_quit);
        this.delete_event.connect ( () => { return hide_on_delete (); } );
    }

    private void create_widgets ()
    {
        // Create and setup widgets
        this.dark_theme = new Switch ();
        this.dark_theme.set_halign (Align.END);
        this.now_playing = new Switch ();
        this.now_playing.set_halign (Align.END);
        this.world_clock = new Switch ();
        this.world_clock.set_halign (Align.END);
        this.regions = new ListBox ();
        this.regions.selection_mode = SelectionMode.MULTIPLE;
        this.calendar = new Switch ();
        this.calendar.set_halign (Align.END);

        align_my_header();

        var theme_box = new Box (Orientation.HORIZONTAL, 0);
        theme_box.add (new Label ("Dark theme"));
        theme_box.add_with_properties (this.dark_theme, "expand", true);

        var now_playing_box = new Box (Orientation.HORIZONTAL, 0);
        now_playing_box.add (new Label ("Enable"));
        now_playing_box.add_with_properties (this.now_playing, "expand", true);

        var now_playing_frame = new Frame ("Now playing");
        now_playing_frame.add (now_playing_box);

        var del_region_button = new Button.with_label ("-");
        var add_region_button = new Button.with_label ("+");
        del_region_button.clicked.connect (() => {
            foreach (var element in this.regions.get_selected_rows ()) {
                this.regions.remove (element);
            }
        });
        add_region_button.clicked.connect (() => {
            this.regions.add (new ListBoxRowWithData("", 0, 0, false));
            this.regions.show_all ();
        });

        var region_buttons_box = new Box (Orientation.HORIZONTAL, 0);
        region_buttons_box.add (del_region_button);
        region_buttons_box.add (add_region_button);

        var world_clock_box_enable = new Box (Orientation.HORIZONTAL, 0);
        world_clock_box_enable.add (new Label ("Enable"));
        world_clock_box_enable.add_with_properties (this.world_clock, "expand", true);

        var world_clock_box = new Box (Orientation.VERTICAL, 0);
        world_clock_box.pack_start (world_clock_box_enable, false, true, 0);
        world_clock_box.pack_start (regions, true, true, 0);
        world_clock_box.pack_start (region_buttons_box, false, true, 0);

        var world_clock_frame = new Frame ("World clock");
        world_clock_frame.add (world_clock_box);

        var calendar_box = new Box (Orientation.HORIZONTAL, 0);
        calendar_box.add (new Label ("Enable"));
        calendar_box.add_with_properties (this.calendar, "expand", true);

        var calendar_frame = new Frame ("Calendar");
        calendar_frame.add (calendar_box);

        var content = get_content_area () as Box;
        content.pack_start (theme_box, false, true, 0);
        content.pack_start (now_playing_frame, false, true, 0);
        content.pack_start (world_clock_frame, true, true, 0);
        content.pack_start (calendar_frame, false, true, 0);
        content.spacing = 10;

        // Add buttons to button area at the bottom
        add_button (Stock.APPLY, ResponseType.APPLY);
        add_button (Stock.OK, ResponseType.OK);
        add_button (Stock.CANCEL, ResponseType.CLOSE);
    }

    public void align_my_header ()
    {
        // listbox has no built-in something like a table header
        // my solution is to set a row header to the first row,
        // by updating title sizes based on row contents.

        regions.set_header_func ((_row, _before) => {
            var row = _row as ListBoxRowWithData;
            fake_header = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            var nm = new Gtk.Label ("name");
            var hr = new Gtk.Label ("offset hour");
            var mn = new Gtk.Label ("offset minute");
            var en = new Gtk.Label ("enable");

            fake_header.pack_start (nm, true, true, 0);
            fake_header.pack_start (hr, true, true, 0);
            fake_header.pack_start (mn, true, true, 0);
            fake_header.pack_start (en, true, true, 0);

            if (row.get_index () == 0) {
                fake_header.realize.connect (() => {
                    row.init_widths();

                    nm.set_size_request (ListBoxRowWithData.nm_width, -1);
                    hr.set_size_request (ListBoxRowWithData.hr_width, -1);
                    mn.set_size_request (ListBoxRowWithData.mn_width, -1);
                    en.set_size_request (ListBoxRowWithData.en_width, -1);
                });

                row.set_header (fake_header);
                fake_header.show_all ();
            } else {
                row.set_header (null);
            }
        });
    }

    private void connect_signals ()
    {
        this.response.connect (on_response);
    }

    private void on_response (Dialog source, int response_id)
    {
        switch (response_id) {
            case ResponseType.OK :
                apply_settings ();
                hide ();
                setup_widgets ();
                break;
            case ResponseType.APPLY :
                apply_settings ();
                break;
            case ResponseType.CLOSE :
                // destroy ();
                hide ();
                setup_widgets ();
                break;
        }
    }

    private void apply_settings ()
    {
        settings.dark_theme = this.dark_theme.get_active ();
        settings.now_playing = this.now_playing.get_active ();
        settings.world_clock = this.world_clock.get_active ();

        settings.regions = new List<Region> ();
        this.regions.get_children().foreach ((entry) => {
            var box = (entry as ListBoxRowWithData);
            var region = new Region ();
            region.name = box.entry_name.text;
            region.hour = box.entry_hour.get_value_as_int ();
            region.minute = box.entry_minute.get_value_as_int ();
            region.enabled = box.entry_enabled.get_active ();
            settings.regions.insert (region, -1);
        });

        settings.calendar = this.calendar.get_active ();
        main_window.apply_settings ();
    }

    private void setup_widgets ()
    {
        this.dark_theme.set_active (settings.dark_theme);
        this.now_playing.set_active (settings.now_playing);
        this.world_clock.set_active (settings.world_clock);
        foreach (var element in this.regions.get_children ()) {
            this.regions.remove (element);
        }
        foreach (var element in settings.regions) {
            this.regions.add (new ListBoxRowWithData(element.name, element.hour, element.minute, element.enabled));
        }
        this.regions.show_all ();
        this.calendar.set_active (settings.calendar);
    }
}
