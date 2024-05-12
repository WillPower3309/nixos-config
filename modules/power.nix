{
  services = {
    upower = {
      enable = true;
      noPollBatteries = true;
    };

    auto-cpufreq.settings = {
      battery = {
        governor = "powersave";
        turbo = "never";
      };
      charger = {
        governor = "performance";
        turbo = "auto";
      };
    };
  };
}
