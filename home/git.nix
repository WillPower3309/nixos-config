{ pkgs, ... }:

{
  programs.git = {
    enable = true;

    userName = "William McKinnon";
    userEmail = "contact@willmckinnon.com";

    ignores = [ ".direnv" ];
  };
}
