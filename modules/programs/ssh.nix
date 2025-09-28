{pkgs, ...}: {
  programs.ssh = {
    enable = true;
    package = pkgs.openssh;

    extraConfig = ''
      Host *
        AddKeysToAgent yes
        IdentitiesOnly yes
    '';

    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        identityFile = ["~/.ssh/id_ed25519"];
        extraOptions = {
          AddKeysToAgent = "yes";
          IdentitiesOnly = "yes";
        };
      };
      "ssh.dev.azure.com" = {
        hostname = "ssh.dev.azure.com";
        identityFile = ["~/.ssh/id_rsa_azure"];
        extraOptions = {
          AddKeysToAgent = "yes";
          IdentitiesOnly = "yes";
        };
      };
    };
  };
}
