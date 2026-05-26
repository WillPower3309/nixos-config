{ inputs, lib, ... }:

{
  flake.nixosConfigurations = inputs.self.lib.mkNixos "aarch64-linux" "pinenote";

  flake.modules.nixos.pinenote = { config, pkgs, lib, ... }: {
    networking.hostName = "pinenote";

    imports = with inputs.self.modules.nixos; [
      common
    ] ++ [
      inputs.pinenote-nixos.nixosModules.default
    ];

    pinenote.config.enable = true;
    pinenote.pinenote-service.enable = true;
    hardware.opentabletdriver.enable = lib.mkForce false;

    fileSystems."/" = {
      label = "nixos";
      fsType = "ext4";
    };

    services.logind.settings.Login = {
      HandlePowerKey = "suspend";
      HandlePowerKeyLongPress = "poweroff";
    };
    services.journald.storage = "volatile";
  };
}
