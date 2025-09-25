{ config, lib, pkgs, ... }:
let
  cfg = config.pontus.features;
  enableModule = cfg.gui && cfg.vscode;
in
lib.mkIf enableModule {
  programs.vscode = {
    enable = true;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        asvetliakov.vscode-neovim
      ];
      userSettings = {
        "vscode-neovim.neovimExecutablePaths.linux" = "${config.home.homeDirectory}/.nix-profile/bin/nvim";
        "vscode-neovim.neovimInitPath" = "${config.xdg.configHome}/nvim/init.lua";
        "vscode-neovim.useCtrlKeys" = true;

        "editor.bracketPairColorization.enabled" = true;
        "editor.renderWhitespace" = "trailing";
        "editor.comments.insertSpace" = false;
        "files.autoSave" = "onFocusChange";
        "editor.formatOnSave" = true;
        "editor.minimap.enabled" = false;
        "typescript.updateImportsOnFileMove.enabled" = "always";
        "editor.rulers" = [ 80 100 ];
      };
      keybindings = [
        { key = "ctrl+b"; command = "workbench.action.toggleSidebarVisibility"; when = "editorTextFocus"; }
        { key = "ctrl+shift+`"; command = "workbench.action.terminal.new"; when = "editorTextFocus"; }
      ];
    };
  };

  xdg.configFile = {
    "Cursor/User/settings.json".text = builtins.toJSON {
      "vscode-neovim.neovimExecutablePaths.linux" = "${config.home.homeDirectory}/.nix-profile/bin/nvim";
      "vscode-neovim.neovimInitPath" = "${config.xdg.configHome}/nvim/init.lua";
      "vscode-neovim.useCtrlKeys" = true;

      "editor.bracketPairColorization.enabled" = true;
      "editor.renderWhitespace" = "trailing";
      "editor.comments.insertSpace" = false;
      "files.autoSave" = "onFocusChange";
      "editor.formatOnSave" = true;
      "editor.minimap.enabled" = false;
      "typescript.updateImportsOnFileMove.enabled" = "always";
      "editor.rulers" = [ 80 100 ];
    };
    "Cursor/User/keybindings.json".text = builtins.toJSON [
      { key = "ctrl+b"; command = "workbench.action.toggleSidebarVisibility"; when = "editorTextFocus"; }
    ];
  };

  home.packages = [ pkgs.code-cursor-fhs ];
}
