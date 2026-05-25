{
  flake.modules.nixos.games = { pkgs, ... }: {
    programs.steam.enable = true;

    hardware.graphics.enable32Bit = true; # needed for proton games

    environment.systemPackages = with pkgs; [
      wineWow64Packages.full
      winetricks
      mono
    ];
  };
}
