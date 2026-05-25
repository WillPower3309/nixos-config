{ pkgs, ... }:

{
  programs.mpv = {
    enable = true;
    config = {
      profile = "gpu-hq";
    };
  };

  home.packages = with pkgs; [
    ffmpeg
    ani-cli
    # TODO: replace youtube-dl with mpv.youtubeSupport = true (unless defaults to true)
    yt-dlp
  ];
}
