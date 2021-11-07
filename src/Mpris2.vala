const string MPRIS_PREFIX = "org.mpris.MediaPlayer2.";
const string MPRIS_MEDIA_PLAYER_PATH = "/org/mpris/MediaPlayer2";
const string FREEDESKTOP_SERVICE = "org.freedesktop.DBus";
const string FREEDESKTOP_OBJECT = "/org/freedesktop/DBus";

[DBus (name = "org.freedesktop.DBus")]
public interface FreeDesktopObject : Object {
    public abstract async string[] list_names () throws GLib.Error;
    public abstract signal void name_owner_changed ( string name,
                                                     string old_owner,
                                                     string new_owner );
}

[DBus (name = "org.mpris.MediaPlayer2")]
public interface MprisRoot : Object {
    // properties
    public abstract bool HasTracklist { owned get; set; }
    public abstract bool CanQuit { owned get; set; }
    public abstract bool CanRaise { owned get; set; }
    public abstract string Identity { owned get; set; }
    public abstract string DesktopEntry { owned get; set; }
    // methods
    public abstract async void Quit () throws GLib.Error;
    public abstract async void Raise () throws GLib.Error;
}

[DBus (name = "org.mpris.MediaPlayer2.Player")]
public interface MprisPlayer : Object {
    // properties
    public abstract HashTable<string, Variant?> Metadata { owned get; set; }
    public abstract int64 Position { owned get; set; }
    public abstract string PlaybackStatus { owned get; set; }
    public abstract bool CanPlay { owned get; set; }
    public abstract bool CanGoNext { owned get; set; }
    public abstract bool CanGoPrevious { owned get; set; }
    // methods
    public abstract async void PlayPause () throws GLib.Error;
    public abstract async void Next () throws GLib.Error;
    public abstract async void Previous () throws GLib.Error;
    public abstract async void Seek (int64 offset) throws GLib.Error;
    // signals
    public signal void Seeked (int64 new_position);
}

// Playlist container
public struct PlaylistDetails {
    public ObjectPath path;
    public string name;
    public string icon_name;
}

// Active playlist property container
public struct ActivePlaylistContainer {
    public bool valid;
    public PlaylistDetails details;
}

[DBus (name = "org.mpris.MediaPlayer2.Playlists")]
public interface MprisPlaylists : Object {
    //properties
    public abstract string[] Orderings { owned get; set; }
    public abstract uint32 PlaylistCount { owned get; set; }
    public abstract ActivePlaylistContainer ActivePlaylist { owned get; set; }

    //methods
    public abstract async void ActivatePlaylist (ObjectPath playlist_id) throws GLib.Error;
    public abstract async PlaylistDetails[] GetPlaylists ( uint32 index,
                                                           uint32 max_count,
                                                           string order,
                                                           bool reverse_order ) throws GLib.Error;
    //signals
    public signal void PlaylistChanged (PlaylistDetails details);
}

public class Mpris2Watcher : GLib.Object
{
    FreeDesktopObject fdesktop_obj;

    public signal void client_appeared (string name);
    public signal void client_disappeared ();

    public Mpris2Watcher ()
    {
    }

    construct
    {
        try {
            this.fdesktop_obj = Bus.get_proxy_sync ( BusType.SESSION,
                                                     FREEDESKTOP_SERVICE,
                                                     FREEDESKTOP_OBJECT,
                                                     DBusProxyFlags.DO_NOT_LOAD_PROPERTIES );
            this.fdesktop_obj.name_owner_changed.connect (this.name_changes_detected);
        }
        catch (GLib.IOError e) {
            warning( "Mpris2watcher could not set up a watch for mpris clients appearing on the bus: %s",
                     e.message );
        }
    }

    // At startup check to see if there are clients up that we are interested in
    public async void check_for_active_clients()
    {
        string[] interfaces;
        try {
            interfaces = yield this.fdesktop_obj.list_names ();
        }
        catch (GLib.Error e) {
            warning( "Mpris2watcher could fetch active interfaces at startup: %s",
                     e.message );
            return;
        }
        foreach (var address in interfaces) {
            if (address.has_prefix (MPRIS_PREFIX)) {
                MprisRoot? mpris2_root = this.create_mpris_root (address);
                if (mpris2_root == null) {
                    return;
                }
                client_appeared (address);
            }
        }
    }

    private void name_changes_detected ( FreeDesktopObject dbus_obj,
                                         string name,
                                         string previous_owner,
                                         string current_owner )
    {
        MprisRoot? mpris2_root = this.create_mpris_root (name);
        if (mpris2_root == null) {
            return;
        }
        if (previous_owner == "" && current_owner != "") {
            debug ("Client '%s' has appeared", name);
            client_appeared (name);
        }
    }

    private MprisRoot? create_mpris_root (string name) {
        MprisRoot mpris2_root = null;
        if (name.has_prefix (MPRIS_PREFIX)) {
            try {
                mpris2_root = Bus.get_proxy_sync ( BusType.SESSION,
                                                   name,
                                                   MPRIS_MEDIA_PLAYER_PATH );
            }
            catch (GLib.IOError e) {
                warning( "Mpris2watcher could not create a root interface: %s",
                         e.message );
            }
        }
        return mpris2_root;
    }
}

public class Mpris2Controller : GLib.Object
{
    public string dbus_name { get; construct; }

    public MprisRoot mpris2_root;
    public MprisPlayer player;
    public MprisPlaylists playlists;
    //public HashTable<string, PlaylistDetails?> name_changed_playlistdetails { get; construct; }
    public Mpris2Controller (string name)
    {
        GLib.Object (dbus_name : name);
    }
    construct {
        try {
            //this.name_changed_playlistdetails = new HashTable<string, PlaylistDetails?> ();
            this.mpris2_root = Bus.get_proxy_sync ( BusType.SESSION,
                                                    dbus_name,
                                                    "/org/mpris/MediaPlayer2" );
            this.player = Bus.get_proxy_sync ( BusType.SESSION,
                                               dbus_name,
                                               "/org/mpris/MediaPlayer2" );
            this.playlists = Bus.get_proxy_sync ( BusType.SESSION,
                                                  dbus_name,
                                                  "/org/mpris/MediaPlayer2" );
            this.playlists.PlaylistChanged.connect (on_playlistdetails_changed);
        }
        catch (GLib.IOError e) {
            critical("Can't create our DBus interfaces - %s", e.message);
        }
    }

    private void on_playlistdetails_changed (PlaylistDetails details)
    {
        //this.name_changed_playlistdetails.set (details.name, details);
    }
}

