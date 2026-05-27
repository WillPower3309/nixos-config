{ inputs, ... }:

{
  flake.modules.nixos.android-dev = { pkgs, config, ... }: {
    boot = {
      kernel.sysctl = { "fs.inotify.max_user_watches" = 524288; };
      kernelModules = [ "kvm_amd" ];
    };

    users.users.will.extraGroups = [ "adbusers" ];

    environment = {
      systemPackages = [ pkgs.android-tools ];
      persistence."${config.constants.persistentDir}".users.will.directories = [ ".gradle" ];
    };
  };

  flake.modules.homeManager.will = { pkgs, config, ... }: {
    home = {
      packages = with pkgs; [ android-studio android-tools ];

      persistence."${config.constants.persistentDir}".directories = [
        ".android"
        ".java"
        "Android"
        ".cache/Google"
        ".config/Google"
        ".local/share/Google"
      ];
    };
  };
}

