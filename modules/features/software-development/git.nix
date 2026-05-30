{ inputs, ... }:

{
  flake.modules.homeManager.will = { pkgs, config, ... }: {
    programs.git = {
      enable = true;
      settings.user = {
        name = "William McKinnon";
        email = "contact@${config.constants.domain}";
      };
    };
  };
}
