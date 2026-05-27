{ inputs, ... }:

{
  flake.modules.homeManager.will = { pkgs, ... }: {
    programs.git = {
      enable = true;
      settings.user = {
        name = "William McKinnon";
        email = "contact@willmckinnon.com";
      };
    };
  };
}
