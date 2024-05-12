{
  # needs upower running to have battery widget work
  # needs network manager running to have network widget work
  programs.ags = {
    enable = true;
    configDir = ./config/ags;
  };
}
