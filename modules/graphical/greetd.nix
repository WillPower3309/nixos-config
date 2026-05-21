{ pkgs, ... }:

{
  # login automatically
  # controversial, but with encrypted /, a password is required to get to this point anyway
  services.getty = {
    autologinUser = "will";
    autologinOnce = true;
  };
  environment.loginShellInit = ''
    [[ "$(tty)" = "/dev/tty1" ]] && dbus-run-session ${pkgs.swayfx}/bin/sway
  '';

  # TODO https://vincent.bernat.ch/en/blog/2021-startx-systemd
}
