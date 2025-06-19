{ pkgs, ... }:

{
  boot = {
    kernel.sysctl = { "fs.inotify.max_user_watches" = 524288; };
    kernelModules = [ "kvm_amd" ];
  };

  # need home module too
  programs.adb.enable = true;
  users.users.will.extraGroups = [ "adbusers" ];

  # needed here due to https://discourse.nixos.org/t/too-many-open-files-when-the-gradle-cache-is-persisted-via-impermanence/51560/6
  environment.persistence."/nix/persist".users.will.directories = [
    ".gradle"
  ];
}

