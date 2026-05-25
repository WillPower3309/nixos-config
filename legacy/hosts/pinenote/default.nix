{ pkgs, inputs, ... }:

{
  imports = [
    inputs.pinenote-nixos.nixosModules.default
  ];

  pinenote.config.enable = true;
  pinenote.pinenote-service.enable = true;
  hardware.opentabletdriver.enable = lib.mkForce false;

  fileSystems."/" = {
    label = "nixos";
    fsType = "ext4";
  };
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
  services.logind.settings.Login = {
    HandlePowerKey = "suspend";
    HandlePowerKeyLongPress = "poweroff";
  };
  services.journald.storage = "volatile";
}

