{
  programs.alacritty = {
    enable = true;

    settings = {
      window = {
        padding.x = 10;
        padding.y = 10;
      };

      font = {
        normal.family = "MesloLGS NF";
        bold.family = "MesloLGS NF";
        italic.family = "MesloLGS NF";
      };

      colors = {
        primary = {
          background =     "0x2e3440";
          foreground =     "0xd8dee9";
          dim_foreground = "0xa5abb6";
        };

	cursor = {
          text =    "0x2e3440";
          cursor =  "0xd8dee9";
	};

        normal = {
          black =   "0x3b4252";
          red =     "0xbf616a";
          green =   "0xa3be8c";
          yellow =  "0xebcb8b";
          blue =    "0x81a1c1";
          magenta = "0xb48ead";
          cyan =    "0x88c0d0";
          white =   "0xe5e9f0";
        };

        bright = {
          black =   "0x4c566a";
          red =     "0xbf616a";
          green =   "0xa3be8c";
          yellow =  "0xebcb8b";
          blue =    "0x81a1c1";
          magenta = "0xb48ead";
          cyan =    "0x8fbcbb";
          white =   "0xeceff4";
        };

	dim = {
          black =   "0x373e4d";
          red =     "0x94545d";
          green =   "0x809575";
          yellow =  "0xb29e75";
          blue =    "0x68809a";
          magenta = "0x8c738c";
          cyan =    "0x6d96a5";
          white =   "0xaeb3bb";
	};
      };
    };
  };
}
