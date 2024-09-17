{
  config,
  pkgs,
  lib,
  utils,
  ...
}:

with lib;

let
  cfg = config.services.sonarr;

  settingsFormat = pkgs.formats.xml { };
  settingsDefault = {
    Port = 8989;
    BindAddress = "*";
    AuthenticationMethod = "None";
    UpdateMechanism = "external";
  };
  settingsCombined = settingsDefault // cfg.settings;
in
{
  options = {
    services.sonarr = {
      enable = mkEnableOption "Sonarr";

      dataDir = mkOption {
        type = types.str;
        default = "/var/lib/sonarr/.config/NzbDrone";
        description = "The directory where Sonarr stores its data files.";
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Open ports in the firewall for the Sonarr web interface
        '';
      };

      settings = mkOption {
        inherit (settingsFormat) type;
        description = "An attribute set containing Sonarr configuration settings.";
        default = { };
        example = lib.literalExpression ''
          LogLevel = "info";
          EnableSsl = "False";
          Port = 8989;
          SslPort = 9898;
          UrlBase = "";
          BindAddress = "*";
          AuthenticationMethod = "None";
          UpdateMechanism = "external";
          Branch = "main";
          InstanceName = "Sonarr";
        '';
      };

      apiKeyFile = mkOption {
        type = types.path;
        description = "Path to the file containing the API key for Sonarr (32 chars).";
        example = "/run/secrets/sonarr-apikey";
        default = "";
      };

      user = mkOption {
        type = types.str;
        default = "sonarr";
        description = "User account under which Sonaar runs.";
      };

      group = mkOption {
        type = types.str;
        default = "sonarr";
        description = "Group under which Sonaar runs.";
      };

      package = mkPackageOption pkgs "sonarr" { };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [ "d '${cfg.dataDir}' 0700 ${cfg.user} ${cfg.group} - -" ];

    systemd.services.sonarr =
      let
        # add empty ApiKey so it can be replaced afterwards
        configContent = settingsCombined // (lib.optionalAttrs (cfg.apiKeyFile != "") { ApiKey = "#APIKEY#"; });
        configFile = settingsFormat.generate "sonarr-config.xml" { Config = configContent; };
      in {
      description = "Sonarr";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      reloadTriggers = [ configFile ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        # set config file in pre
        ExecStartPre = [
          "${pkgs.coreutils}/bin/install -o ${cfg.user} -g ${cfg.group} ${configFile} ${cfg.dataDir}/config.xml"
        ] ++ lib.optional (cfg.apiKeyFile != "") "${pkgs.replace-secret}/bin/replace-secret '#APIKEY#' '${cfg.apiKeyFile}' ${cfg.dataDir}/config.xml";
        ExecStart = utils.escapeSystemdExecArgs [
          (lib.getExe cfg.package)
          "-nobrowser"
          "-data=${cfg.dataDir}"
        ];
        Restart = "on-failure";
      };
    };

    networking.firewall = mkIf cfg.openFirewall { allowedTCPPorts = [ settingsCombined.Port ]; };

    users.users = mkIf (cfg.user == "sonarr") {
      sonarr = {
        group = cfg.group;
        home = cfg.dataDir;
        uid = config.ids.uids.sonarr;
      };
    };

    users.groups = mkIf (cfg.group == "sonarr") { sonarr.gid = config.ids.gids.sonarr; };
  };
}
