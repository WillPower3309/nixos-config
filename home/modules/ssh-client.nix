{ pkgs, ... }:

{
  programs.ssh = {
    enable = true;

    matchBlocks = {
      "server*" = {
        hostname = "server.willmckinnon.com";
        user = "root";
      };

      "server-boot" = {
        port = 2222;
      };

      "lighthouse" = {
        hostname = "lighthouse.willmckinnon.com";
        user = "root";
        port = 2222;
      };

      "router" = {
        hostname = "10.27.27.1";
        user = "root";
      };
    };
  };

  home = {
    persistence."/nix/persist".files = [
      ".ssh/id_ed25519"
      ".ssh/known_hosts"
    ];
    file.".ssh/id_ed25519.pub".source = ../id_ed25519.pub;
  };
}
