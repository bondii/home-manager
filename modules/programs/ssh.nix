{ pkgs, ... }:
{
  programs.ssh = {
    enable = true;
    package = pkgs.openssh;
    enableDefaultConfig = false;

    settings = {
      "*" = {
        AddKeysToAgent = "yes";
        IdentitiesOnly = "yes";
      };
      "github.com" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
      };
      "ssh.dev.azure.com" = {
        HostName = "ssh.dev.azure.com";
        User = "git";
        IdentityFile = "~/.ssh/id_rsa_azure";
      };
    };
  };
}
