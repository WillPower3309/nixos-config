{ pkgs, ... }:

{
  programs.ssh = {
    enable = true;

    matchBlocks = {
      "server*" = {
        hostname = "10.27.27.3";
        user = "root";
        identityFile = "~/.ssh/server";
      };

      "server-boot" = {
        port = 2222;
      };
    };
  };

  home.persistence."/nix/persist/home/will".directories = [ ".ssh" ];
}
