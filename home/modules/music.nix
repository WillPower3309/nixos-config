{ pkgs, ... }:

# TODO: NFS?
let musicDir = "/nix/persist/home/will/Music";

in
{
  services.mpd = {
    enable = true;
    network.startWhenNeeded = true;
    musicDirectory = musicDir;
    extraConfig = ''
      # TODO: alsa output?
      audio_output {
        type "pipewire"
        name "pipewire"
      }
      audio_output {
        type                    "fifo"
        name                    "my_fifo"
        path                    "/tmp/mpd.fifo"
        format                  "44100:16:2"
      }
    '';
  };

  programs.ncmpcpp = {
    enable = true;
    mpdMusicDir = musicDir;
  };

  home = {
    packages = with pkgs; [
      mpc_cli
      soulseekqt
    ];

    persistence."/nix/persist/home/will".directories = [ "Music" ];
  };
}
