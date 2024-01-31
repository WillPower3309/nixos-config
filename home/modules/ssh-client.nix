{ pkgs, ... }:

{
  programs.ssh = {
    enable = true;

    matchBlocks = {
      "server*" = {
        hostname = "10.27.27.3";
        user = "root";
      };

      "server-boot" = {
        port = 2222;
      };

      "lighthouse" = {
        hostname = "143.110.232.34";
        user = "root";
      };
    };
  };

  home = {
    persistence."/nix/persist/home/will".files = [
      ".ssh/id_ed25519"
      ".ssh/known_hosts"
    ];
    file.".ssh/id_ed25519.pub".source = ../id_ed25519.pub;
  };
}
