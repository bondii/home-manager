{ config, pkgs, lib, ... }:

#let
#  # NixGL (valfritt men bra på Arch för GL-appar byggda via Nix)
#  nixGL = pkgs.callPackage (pkgs.fetchFromGitHub {
#    owner = "guibou"; repo = "nixGL"; rev = "master"; sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"; # byt till rätt hash vid behov
#  }) {};
#in
{
  home.username = "pontus";
  home.homeDirectory = "/home/pontus";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;
  xdg.enable = true;
  fonts.fontconfig.enable = true;

  home.sessionPath = [ "${config.home.homeDirectory}/.nix-profile/bin" ];
  home.sessionVariables = {
    # Make .desktop/icons from Nix findable
    XDG_DATA_DIRS = "${config.home.homeDirectory}/.nix-profile/share:/usr/local/share:/usr/share";
    EDITOR = "nvim";
  };

  imports = [
    ./modules/nvim.nix
  ];

  # ZSH + oh-my-zsh (+ autosuggest + syntax highlighting) och Starship
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [ "git" "sudo" "docker" "fzf" ];
    };

    initContent = ''
      # Optional: wrapper for GL-apps from Nix
      #alias glkitty="DOLLAR {lib.getExe nixGL}/bin/nixGL ${lib.getExe pkgs.kitty}"
      #alias glimv="DOLLAR {lib.getExe nixGL}/bin/nixGL ${lib.getExe pkgs.imv}"
      alias nv="nvim"
    '';
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$username$hostname$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = { success_symbol = "❯"; error_symbol = "❯"; };
    };
  };

  # Kitty
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11.0;
    };
    settings = {
      confirm_os_window_close = 0;
      enable_audio_bell = "no";
      scrollback_lines = 10000;
      term = "xterm-kitty";
    };
  };

  # Rofi
  programs.rofi = {
    enable = true;
    #terminal = "${pkgs.nixgl.nixGLMesa}/bin/nixGLMesa ${pkgs.kitty}/bin/kitty";
    terminal = "kitty-gl";
    theme = "Arc-Dark";
    extraConfig = {
      modi = "drun,run,ssh";
      show-icons = true;
    };
  }; # :contentReference[oaicite:8]{index=8}

  # Dunst (notifieringar)
  services.dunst = {
    enable = true;
    settings = {
      global = {
        font = "JetBrainsMono Nerd Font 10";
        frame_color = "#5e81ac";
        separator_color = "frame";
        padding = 8;
        horizontal_padding = 8;
        icon_position = "left";
      };
      urgency_low     = { background = "#2e3440"; foreground = "#d8dee9"; timeout = 3; };
      urgency_normal  = { background = "#2b303b"; foreground = "#eceff4"; timeout = 6; };
      urgency_critical= { background = "#bf616a"; foreground = "#2e3440"; frame_color = "#bf616a"; timeout = 0; };
    };
  };

  # Picom (kompositor) — startas som systemd-user service av HM (inte via XDG .desktop)
  services.picom = {
    enable = true;
    settings = {
      backend = "glx";
      vsync = true;
      detect-client-leader = true;
      detect-rounded-corners = true;
      corner-radius = 8;
      shadow = true;
    };
  }; # (undviker kända autostart-konflikter). :contentReference[oaicite:9]{index=9}

  # Skärmlås: i3lock-color via xss-lock
  services.screen-locker = {
    enable = true;
    lockCmd = "${pkgs.i3lock-color}/bin/i3lock-color -n --blur 5 --clock";
    inactiveInterval = 10; # minuter
    xss-lock.extraOptions = [ "--transfer-sleep-lock" ];
  }; # :contentReference[oaicite:10]{index=10}

  services.redshift = {
    enable = true;
    settings = {
      redshift = {
        temp-day         = lib.mkForce 6500;
        temp-night       = lib.mkForce 1000;
        brightness-day   = lib.mkForce 1.0;
        brightness-night = lib.mkForce 0.1;
        transition       = 1;
        #adjustment-method = randr;
        
        dawn-time = "06:59-07:00";
        dusk-time = "18:30-20:00";
      };
    };
  };

  # i3 + i3status-rust
  programs.i3status-rust = {
    enable = true;

    bars = {
      default = {
        settings = {
          theme = { theme = "gruvbox-dark"; };
          icons = { icons = "material-nf"; };
        };

        blocks = [
          { block = "cpu"; }
          { block = "memory"; }
          { block = "battery"; }
          { block = "net"; }
          { block = "sound"; }
          { block = "time"; interval = 60; format = "%a %d %H:%M"; }
        ];
      };
    };
  }; # HM skapar toml under ~/.config/i3status-rust; i3 måste peka dit. :contentReference[oaicite:11]{index=11}

  #programs.neovim = {
  #  enable = true;
  #  package = config.programs.nixvim.build.package;
  #  defaultEditor = true;
  #  viAlias = false;
  #  vimAlias = false;
  #};

  #programs.nixvim = {
  #  plugins.lint.enable = true;  # nvim-lint

  #  # Konfigurera vilka linters som ska köras när (rent Lua via Nix)
  #  extraConfigLua = ''
  #    local lint = require("lint")
  #    lint.linters_by_ft = {
  #      javascript = { "eslint_d" },
  #      typescript = { "eslint_d" },
  #      tsx        = { "eslint_d" },
  #      jsx        = { "eslint_d" },
  #      lua        = { "luacheck" },
  #      python     = { "ruff" },
  #      nix        = { "deadnix" },
  #      sh         = { "shellcheck" },
  #      bash       = { "shellcheck" },
  #      zsh        = { "shellcheck" },
  #      go         = { "golangci_lint" },
  #      markdown   = { "markdownlint" },
  #      -- ['*'] = { 'typos' },      -- global linter exempel
  #      -- ['_'] = { 'fallback' },   -- fallback-filtyp
  #    }

  #    -- Kör linters automatiskt vid vettiga events
  #    vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
  #      callback = function() require("lint").try_lint() end,
  #    })
  #  '';
  #};


  xsession.enable = true;
  xsession.windowManager.i3 = {
    enable = true;
    package = pkgs.i3-gaps;
    config = {
      modifier = "Mod1";
      #terminal = "${pkgs.kitty}/bin/kitty";
      terminal = "kitty-gl";
      fonts = { names = [ "JetBrainsMono Nerd Font" ]; size = 10.0; };

      # i3bar -> i3status-rs konfig som HM genererar
      bars = [{
        position = "bottom";
        statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ${config.xdg.configHome}/i3status-rust/config-default.toml";
      }];

      startup = [
        { command = "nm-applet"; always = true; notification = false; }
        { command = "blueman-applet"; always = true; notification = false; }
        { command = "xfce4-clipman"; always = true; notification = false; } # Clipman (X11); starta tray-varianten
        { command = "feh --no-fehbg --bg-fill $HOME/Pictures/wallpapers/default.jpg"; always = true; }
	{ command = "setxkbmap -layout se,us -option grp:caps_toggle"; always = true; notification = false; }
      ];

      # Några standardbinds
      keybindings = lib.mkOptionDefault {
        "Mod4+Return" = "exec --no-startup-id ${pkgs.nixgl.nixGLMesa}/bin/nixGLMesa ${pkgs.kitty}/bin/kitty";
        #"Mod4+Return" = "exec --no-startup-id ${pkgs.kitty}/bin/kitty";
        "Mod4+Shift+Return" = "exec --no-startup-id ${pkgs.xterm}/bin/xterm";
        "Mod4+d"      = "exec rofi -show drun";
        "Mod4+Shift+e"= "exec i3-msg exit";
        "Mod4+Shift+r"= "restart";
        "Mod4+l"      = "exec ${pkgs.i3lock-color}/bin/i3lock-color -n --blur 5 --clock";

        "XF86MonBrightnessUp"   = "exec --no-startup-id ${pkgs.brightnessctl}/bin/brightnessctl set +10%";
        "XF86MonBrightnessDown" = "exec --no-startup-id ${pkgs.brightnessctl}/bin/brightnessctl set 10%-";
      };
    };

    extraConfig = ''
      bar {
        font pango:JetBrainsMono Nerd Font 11
      }
    '';
  }; # :contentReference[oaicite:12]{index=12}

  # Paket som installeras användarlokalt via Nix
  home.packages = with pkgs; [
    # NixGL wrappers
    (pkgs.writeShellScriptBin "kitty-gl" ''
      exec ${pkgs.nixgl.nixGLMesa}/bin/nixGLMesa ${pkgs.kitty}/bin/kitty "$@"
    '')
    (pkgs.writeShellScriptBin "imv-gl" ''
      exec ${pkgs.nixgl.nixGLMesa}/bin/nixGLMesa ${pkgs.imv}/bin/imv "$@"
    '')

    xterm
    brightnessctl
    nixgl.nixGLMesa

    # UI/verktyg
    feh imv zathura blueman networkmanagerapplet libnotify xss-lock
    xfce.xfce4-clipman-plugin
    redshift

    # dev
    git
    ripgrep fd gcc nodejs
    lua-language-server
    rust-analyzer gopls
    typescript-language-server typescript
    pyright

    # LSP
    nodePackages.vscode-langservers-extracted  # jsonls, cssls, html etc
    nodePackages.yaml-language-server          # yamlls
    nodePackages.bash-language-server          # bashls

    # fonts
    #(nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji

    # Linters / formatters / checkers
    nodePackages.eslint_d
    ruff
    deadnix
    shellcheck
    golangci-lint
    markdownlint-cli

    lua54Packages.luacheck

    config.programs.nixvim.build.package
  ];

  programs.zsh.shellAliases = {
    nv = "nvim";
    vim = "nvim";
    vimdiff = "nvim -d";
  };

  # Shared VSCode / Cursor settings
  xdg.configFile."Cursor/User/settings.json".text = builtins.toJSON {
    "vscode-neovim.neovimExecutablePaths.linux" = "${config.home.homeDirectory}/.nix-profile/bin/nvim";
    "vscode-neovim.neovimInitPath" = "${config.xdg.configHome}/nvim/init.lua";
    "vscode-neovim.useCtrlKeys" = true;
  };
  xdg.configFile."Cursor/User/keybindings.json".text = builtins.toJSON [
    { key = "ctrl+b"; command = "workbench.action.toggleSidebarVisibility"; when = "editorTextFocus"; }
  ];

  # Exempel på egen systemd-user service med Home Manager (om du hellre vill köra applets som tjänster):
  # systemd.user.services."clipman" = {
  #   Unit = { Description = "Xfce4 Clipman"; After = [ "graphical-session.target" ]; };
  #   Service = { ExecStart = "${pkgs.xfce.xfce4-clipman-plugin}/bin/xfce4-clipman"; Restart = "on-failure"; };
  #   Install = { WantedBy = [ "default.target" ]; };
  # };
}

