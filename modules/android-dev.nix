{ pkgs, ... }:

{
  boot = {
    kernel.sysctl = { "fs.inotify.max_user_watches" = 524288; };
    kernelModules = [ "kvm_amd" ];
  };

  # need home module too
  programs.adb.enable = true;
  users.users.will.extraGroups = [ "adbusers" ];
}
