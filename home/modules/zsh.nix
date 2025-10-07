{ nixosConfig, pkgs, lib, ... }:

let
  nixosConfigPath = "~/Projects/nixos-config";

in
{
  # TODO: transient prompt
  programs = {
    zsh = {
      # TODO: already enabled system wide?
      enable = true;
      defaultKeymap = "viins";
      autosuggestion.enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;

      sessionVariables = {
        TERM="xterm-256color";
      };

      shellAliases = {
        ls = "colorls";
        os-rebuild = "nixos-rebuild switch --flake ${nixosConfigPath}#${nixosConfig.networking.hostName}";
        fetch = "SPRITE=$(pokeget random --hide-name); HEIGHT=$(echo \"$SPRITE\" | wc -l); fastfetch --data-raw \"$SPRITE\"; echo \"$HEIGHT\""; # TODO: vertical align to sprite https://github.com/fastfetch-cli/fastfetch/issues/458
      };

      # show fetch on new terminal windows & set up transient prompt
      initContent = lib.mkOrder 1500 ''
        if [[ $TERM != "dumb" ]]; then
          fetch
        
          eval "$(starship init zsh)"
        fi
      '';
    };

    starship = {
      enable = true;
      settings = {
        format = lib.concatStrings [
          "[](#9A348E)"
          "$os"
          "[](bg:#DA627D fg:#9A348E)"
          "$directory"
          "[](fg:#DA627D bg:#FCA17D)"
          "$git_branch"
          "$git_status"
          "[](fg:#FCA17D bg:#86BBD8)"
          "$nix_shell"
          "$c"
          "$elixir"
          "$elm"
          "$golang"
          "$gradle"
          "$haskell"
          "$java"
          "$julia"
          "$nodejs"
          "$nim"
          "$rust"
          "$scala"
          "[](fg:#86BBD8 bg:#06969A)"
          "$docker_context"
          "[](fg:#06969A bg:#33658A)"
          "$time"
          "[ ](fg:#33658A)"
        ];

        os = {
          style = "bg:#9A348E";
          disabled = false;
        };

        directory = {
          style = "bg:#DA627D";
          format = "[ $path ]($style)";
          truncation_length = 3;
          truncation_symbol = "…/";

          substitutions = {
            # Keep in mind that the order matters. For example:
            # "Important Documents" = " 󰈙 "
            # will not be replaced, because "Documents" was already substituted before.
            # So either put "Important Documents" before "Documents" or use the substituted version:
            # "Important 󰈙 " = " 󰈙 "
            Documents = "󰈙 ";
            Downloads = " ";
            Music = " ";
            Pictures = " ";
          };
        };

        git_branch = {
          symbol = "";
          style = "bg:#FCA17D";
          format = "[ $symbol $branch ]($style)";
        };

        git_status = {
          style = "bg:#FCA17D";
          format = "[$all_status$ahead_behind ]($style)";
        };

        docker_context = {
          symbol = " ";
          style = "bg:#06969A";
          format = "[ $symbol $context ]($style)";
        };
      };
    };
  };

  home.packages = [ pkgs.pokeget-rs ]; # TODO: use ${pkgs.pokeget-rs/bin/pokeget} in fetch alias
}
