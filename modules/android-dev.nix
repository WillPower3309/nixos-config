{ pkgs, ... }:

{
  boot = {
    kernel.sysctl = { "fs.inotify.max_user_watches" = 524288; };
    kernelModules = [ "kvm_amd" ];
  };

  # need home module too
  users.users.will.extraGroups = [ "adbusers" ]; # TODO: still needed?

  # needed here due to https://discourse.nixos.org/t/too-many-open-files-when-the-gradle-cache-is-persisted-via-impermanence/51560/6
  environment = {
    systemPackages = [ pkgs.android-tools ];
    persistence."/nix/persist".users.will.directories = [ ".gradle" ];
  };
}

