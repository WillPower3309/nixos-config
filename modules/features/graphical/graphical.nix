{ inputs, ... }:

{
  flake.modules.nixos.graphical = { pkgs, ... }: {
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
      users
      wayland
      web-browsers
    ] ++ [ inputs.agenix.nixosModules.age ];

    hardware.graphics = {
      enable = true;
      extraPackages = [ pkgs.rocmPackages.clr.icd ]; # opencl TODO: just for darktable?
    };

    programs.fuse.userAllowOther = true; # persistence (TODO: make one file)

    age.identityPaths = [ "/nix/persist/etc/ssh/ssh_host_ed25519_key" ];

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
