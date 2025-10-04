{ pkgs, ... }:

{
  # TODO https://github.com/Kreyren/nixos-config/blob/bd4765eb802a0371de7291980ce999ccff59d619/nixos/users/kreyren/home/modules/web-browsers/firefox/firefox.nix#L116-L148
  # TODO https://www.reddit.com/r/uBlockOrigin/comments/1c3uhp7/comment/kzm5srm/
  # TODO https://old.reddit.com/r/uBlockOrigin/comments/1ao5fpd/blocking_facebook_reels_and_suggested_contents/
  programs = {
    firefox = {
      enable = true;
      languagePacks = [ "en-US" ];

      # Check about:policies#documentation for options.
      policies = {
        AppAutoUpdate = false; # Disable automatic application update
        BackgroundAppUpdate = false; # Disable automatic application update in the background, when the application is not running.
        DisableBuiltinPDFViewer = true; # Considered a security liability
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableFirefoxAccounts = true;
        DisableAccounts = true;
        DisableFirefoxScreenshots = true;
        DisableFormHistory = true;
        DisablePasswordReveal = true;
        DisableForgetButton = true; # Thing that can wipe history for X time, handled differently
        DisableMasterPasswordCreation = true; # To be determined how to handle master password
        DisableProfileImport = true; # Purity enforcement: Only allow nix-defined profiles
        DisableProfileRefresh = true; # Disable the Refresh Firefox button on about:support and support.mozilla.org
        DisableSetDesktopBackground = true; # Remove the “Set As Desktop Background…” menuitem when right clicking on an image, because Nix is the only thing that can manage the backgroud
        DisplayMenuBar = "default-off";
        SearchBar = "unified";
        OverrideFirstRunPage = "";
        OverridePostUpdatePage = "";
        DontCheckDefaultBrowser = true;
        DisplayBookmarksToolbar = "never"; # alternatives: "always" or "newtab"
        OfferToSaveLogins = false; # Managed by Keepass instead
        EnableTrackingProtection = {
          Value = true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
          EmailTracking = true;
        };
        EncryptedMediaExtensions = {
          Enabled = true;
          Locked = true;
        };
        ExtensionUpdate = false;

        # Check about:support for extension/add-on ID strings.
        # To add additional extensions, find it on addons.mozilla.org, find
        # the short ID in the url (like https://addons.mozilla.org/en-US/firefox/addon/!SHORT_ID!/)
        # Then, download the XPI, rename it to <name.zip>, unzip it,
        # run `jq .browser_specific_settings.gecko.id manifest.json` or
        # `jq .applications.gecko.id manifest.json` to get the UUID
        ExtensionSettings = {
          "*".installation_mode = "blocked"; # blocks all addons except the ones specified below
          "uBlock0@raymondhill.net" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
            installation_mode = "force_installed";
          };
          "keepassxc-browser@keepassxc.org" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/keepassxc-browser/latest.xpi";
            installation_mode = "force_installed";
          };
          "{74145f27-f039-47ce-a470-a662b129930a}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/clearurls/latest.xpi";
            installation_mode = "force_installed";
          };
        };

        # Check about:config for options.
        Preferences = {
          "browser.contentblocking.category" = { Value = "strict"; Status = "locked"; };
          "extensions.pocket.enabled" = "lock-false";
          "extensions.screenshots.disabled" = "lock-true";
          "browser.topsites.contile.enabled" = "lock-false";
          "browser.formfill.enable" = "lock-false";
          "browser.search.suggest.enabled" = "lock-false";
          "browser.search.suggest.enabled.private" = "lock-false";
          "browser.urlbar.suggest.searches" = "lock-false";
          "browser.urlbar.showSearchSuggestionsFirst" = "lock-false";
          "browser.newtabpage.activity-stream.feeds.section.topstories" = "lock-false";
          "browser.newtabpage.activity-stream.feeds.snippets" = "lock-false";
          "browser.newtabpage.activity-stream.section.highlights.includePocket" = "lock-false";
          "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = "lock-false";
          "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = "lock-false";
          "browser.newtabpage.activity-stream.section.highlights.includeVisited" = "lock-false";
          "browser.newtabpage.activity-stream.showSponsored" = "lock-false";
          "browser.newtabpage.activity-stream.system.showSponsored" = "lock-false";
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = "lock-false";
        };

        SearchEngines = {
          PreventInstalls = true;
          Add = [
            # TODO: add startpage
            {
              Alias = "@np";
              Description = "Search in NixOS Packages";
              IconURL = "https://nixos.org/favicon.png";
              Method = "GET";
              Name = "NixOS Packages";
              URLTemplate = "https://search.nixos.org/packages?from=0&size=200&sort=relevance&type=packages&query={searchTerms}";
            }
            {
              Alias = "@no";
              Description = "Search in NixOS Options";
              IconURL = "https://nixos.org/favicon.png";
              Method = "GET";
              Name = "NixOS Options";
              URLTemplate = "https://search.nixos.org/options?from=0&size=200&sort=relevance&type=packages&query={searchTerms}";
            }
          ];
          Remove = [ "Amazon.com" "Bing" "Google" "Wikipedia (en)" "eBay" ];
          # Default = ""; TODO: set as startpage
        };
      };
    };
  };
}

