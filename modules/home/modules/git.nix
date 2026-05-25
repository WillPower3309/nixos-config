{ inputs, ... }:

{
  flake.modules.homeManager.git = { pkgs, ... }: {
    programs.git = {
      enable = true;
      settings.user = {
        name = "William McKinnon";
        email = "contact@willmckinnon.com";
      };
    };
  };
}
