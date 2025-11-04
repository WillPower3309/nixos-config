{ pkgs, nixosConfig, ... }:

with nixosConfig.networking;

# TODO: https://mpd.readthedocs.io/en/stable/user.html#satellite-setup
# TODO: xdg dirs?
let musicDir = if hostName == "desktop" then "/mnt/music" else "/nix/persist/home/will/Music";

in
{
  services.mpd = {
    enable = true;
    network.startWhenNeeded = true;
    musicDirectory = musicDir;
    # TODO: alsa output?
    extraConfig = ''
      audio_output {
        type "pipewire"
        name "pipewire"
      }
      audio_output {
        type   "fifo"
        name   "my_fifo"
        path   "/tmp/mpd.fifo"
        format "44100:16:2"
      }
    '';
  };

  programs.ncmpcpp = {
    enable = true;
    mpdMusicDir = musicDir;
    settings = {
      # TODO: https://wiki.archlinux.org/title/Ncmpcpp#With_album_art
      execute_on_song_change = "notify-send \"Now Playing\" \"$(mpc --format '%title% \\n%artist% - %album%' current)\"";
    };
  };

  home = {
    packages = with pkgs; [ mpc ];

    persistence."/nix/persist/home/will".directories = if hostName == "desktop" then [] else [ "Music" ];
  };
}
