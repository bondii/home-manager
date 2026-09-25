{
  enable = true;
  settings = {
    notify_on_error = false;
    format_on_save = {
      lsp_format = "fallback";
      timeout_ms = 5000;
    };
    formatters_by_ft = {
      nix = [ "nixfmt" ];
      lua = [ "stylua" ];
      terraform = [ "terraform_fmt" ];
      dockerfile = [ "dockfmt" ];
      python = [
        "black"
        "ruff"
      ];
      json = [
        "prettierd"
        "prettier"
      ];
      jsonc = [
        "prettierd"
        "prettier"
      ];
      javascript = [
        "prettierd"
        "prettier"
      ];
      javascriptreact = [
        "prettierd"
        "prettier"
      ];
      typescript = [
        "prettierd"
        "prettier"
      ];
      typescriptreact = [
        "prettierd"
        "prettier"
      ];
      html = [
        "prettierd"
        "prettier"
      ];
      css = [
        "prettierd"
        "prettier"
      ];
      scss = [
        "prettierd"
        "prettier"
      ];
      less = [
        "prettierd"
        "prettier"
      ];
      yaml = [
        "prettierd"
        "prettier"
      ];
      markdown = [
        "prettierd"
        "prettier"
      ];
      sh = [ "shfmt" ];
      bash = [ "shfmt" ];
      zsh = [ "shfmt" ];
    };
    formatters = {
      shfmt.prepend_args = [
        "-i"
        "2"
        "-ci"
      ];
      prettier.timeout_ms = 5000;
      prettierd.timeout_ms = 5000;
    };
  };
}
