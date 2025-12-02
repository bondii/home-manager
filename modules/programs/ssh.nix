{ pkgs, ... }:
{
  programs.ssh = {
    enable = true;
    package = pkgs.openssh;
    enableDefaultConfig = false;

    matchBlocks = {
      "*" = {
        extraOptions = {
          AddKeysToAgent = "yes";
          IdentitiesOnly = "yes";
        };
      };
      "github.com" = {
        hostname = "github.com";
        identityFile = [ "~/.ssh/id_ed25519" ];
      };
      "ssh.dev.azure.com" = {
        hostname = "ssh.dev.azure.com";
        identityFile = [ "~/.ssh/id_rsa_azure" ];
      };
    };
  };
}
