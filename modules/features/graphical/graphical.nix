{ inputs, ... }:

{
  flake.modules.nixos.graphical = { pkgs, config, ... }: {
    imports = with inputs.self.modules.nixos; [
      games
      greetd
      file-management
      fonts
      organization
      plymouth
      screen-record
      sound
      sway
      will-user
      wayland
      web-browsers
    ] ++ [ inputs.agenix.nixosModules.age ];

    hardware.graphics.enable = true;

    programs.fuse.userAllowOther = true; # persistence (TODO: it it needed? make one file?)

    age.identityPaths = [ "${config.constants.persistentDir}/etc/ssh/ssh_host_ed25519_key" ];

    environment.systemPackages = with pkgs; [
      inputs.agenix.packages.x86_64-linux.default
      deploy-rs
      pciutils
      colorls
      gtop
      libnotify
      psmisc # fuser, killall and pstree etc
    ];
  };
}
