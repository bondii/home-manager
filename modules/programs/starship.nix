{...}: {
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$username$hostname$directory$virtualenv$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "❯";
        error_symbol = "❯";
      };
    };
  };
}
