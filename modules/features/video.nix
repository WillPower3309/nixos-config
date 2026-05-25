{ inputs, ... }:

{
  flake.modules.homeManager.will = { pkgs, ... }: {
    programs.mpv = {
      enable = true;
      config = {
        profile = "gpu-hq";
      };
    };

    home.packages = with pkgs; [
      ffmpeg
      ani-cli
      yt-dlp
    ];
  };
}
