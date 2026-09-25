{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.pontus.features.dev {
  systemd.user.services =
    let
      mkCloudSqlProxy =
        {
          name,
          instance,
          port,
        }:
        {
          Unit = {
            Description = "Cloud SQL Auth Proxy (${name})";
            After = [ "network-online.target" ];
            Wants = [ "network-online.target" ];
          };
          Service = {
            ExecStart =
              "${pkgs.google-cloud-sql-proxy}/bin/cloud-sql-proxy "
              + "--address 127.0.0.1 "
              + "--port ${toString port} "
              + "--auto-iam-authn "
              #+ "--private-ip "
              + instance;
            Restart = "on-failure";
            RestartSec = 2;
            Environment = [ "CSQL_PROXY_STRUCTURED_LOGS=true" ];
          };
        };
    in
    {
      "cloud-sql-proxy-dev" = mkCloudSqlProxy {
        name = "dev";
        instance = "ship2shore-dev:europe-north1:maritime-instance";
        port = 1234;
      };
      "cloud-sql-proxy-prod" = mkCloudSqlProxy {
        name = "prod";
        instance = "ship2shore-prod:europe-north1:maritime-instance";
        port = 4321;
      };
    };
}
