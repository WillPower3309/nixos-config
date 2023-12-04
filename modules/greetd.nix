{ pkgs, ... }:

{
  # login automatically
  # controversial, but with encrypted /, a password is required to get to this point anyway
  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        command = "${pkgs.swayfx}/bin/sway";
        user = "will";
      };
      default_session = initial_session;
    };
  };
}
