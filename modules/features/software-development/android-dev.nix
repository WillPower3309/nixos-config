{ inputs, ... }:

{
  flake.modules.nixos.android-dev = { pkgs, ... }: {
    boot = {
      kernel.sysctl = { "fs.inotify.max_user_watches" = 524288; };
      kernelModules = [ "kvm_amd" ];
    };

    users.users.will.extraGroups = [ "adbusers" ];

    environment = {
      systemPackages = [ pkgs.android-tools ];
      persistence."/nix/persist".users.will.directories = [ ".gradle" ];
    };
  };

  flake.modules.homeManager.will = { pkgs, ... }: {
    home = {
      packages = with pkgs; [ android-studio android-tools ];

      persistence."/nix/persist".directories = [
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

