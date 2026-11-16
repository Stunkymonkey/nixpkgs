# Shared `autoPrune` options and service for the docker and docker-rootless modules.
{ lib, utils }:

{
  # `optionPath` is the path of the parent option set, e.g. "virtualisation.docker",
  # used to build links between the generated options in the manual.
  mkOptions = optionPath: {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to periodically prune Docker resources. If enabled, a
        systemd timer will run `docker system prune -f`
        as specified by the `dates` option.

        NOTE: by default this does not prune volumes. Anonymous volumes
        can be pruned by passing "--volumes" to [autoPrune.flags](#opt-${optionPath}.autoPrune.flags).

        To prune all volumes (not just anonymous ones) [`autoPrune.allVolumes.enable`](#opt-${optionPath}.autoPrune.allVolumes.enable)
        must be used.

        See [upstream documentation](https://docs.docker.com/reference/cli/docker/system/prune/#description) for further information.
      '';
    };

    flags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "--all" ];
      description = ''
        Any additional flags passed to {command}`docker system prune`.
      '';
    };

    dates = lib.mkOption {
      default = "weekly";
      type = lib.types.str;
      description = ''
        Specification (in the format described by
        {manpage}`systemd.time(7)`) of the time at
        which the prune will occur.
      '';
    };

    randomizedDelaySec = lib.mkOption {
      default = "0";
      type = lib.types.singleLineStr;
      example = "45min";
      description = ''
        Add a randomized delay before each auto prune.
        The delay will be chosen between zero and this value.
        This value must be a time span in the format specified by
        {manpage}`systemd.time(7)`
      '';
    };

    persistent = lib.mkOption {
      default = true;
      type = lib.types.bool;
      example = false;
      description = ''
        Takes a boolean argument. If true, the time when the service
        unit was last triggered is stored on disk. When the timer is
        activated, the service unit is triggered immediately if it
        would have been triggered at least once during the time when
        the timer was inactive. Such triggering is nonetheless
        subject to the delay imposed by RandomizedDelaySec=. This is
        useful to catch up on missed runs of the service when the
        system was powered down.
      '';
    };

    allVolumes = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to periodically prune all Docker volumes when auto pruning other docker resources
          by running {command}`docker volume prune --force --all`

          To prune only anonymous volumes, instead pass `--volumes` to `autoPrune.flags`
        '';
      };

      flags = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "--filter=label=<label>" ];
        description = ''
          Any additional flags passed to {command}`docker volume prune --force --all`.
        '';
      };
    };
  };

  # Arguments for `systemd.services.docker-prune` or `systemd.user.services.docker-prune`.
  mkService =
    { package, autoPrune }:
    {
      description = "Prune docker resources";

      restartIfChanged = false;
      unitConfig.X-StopOnRemoval = false;

      serviceConfig = {
        Type = "oneshot";
        ExecStart = [
          (utils.escapeSystemdExecArgs (
            [
              (lib.getExe package)
              "system"
              "prune"
              "-f"
            ]
            ++ autoPrune.flags
          ))
        ]
        ++ lib.optionals autoPrune.allVolumes.enable [
          (utils.escapeSystemdExecArgs (
            [
              (lib.getExe package)
              "volume"
              "prune"
              "--force"
              "--all"
            ]
            ++ autoPrune.allVolumes.flags
          ))
        ];
      };

      startAt = lib.optional autoPrune.enable autoPrune.dates;
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
    };

  # Arguments for `systemd.timers.docker-prune` or `systemd.user.timers.docker-prune`.
  mkTimer = autoPrune: {
    timerConfig = {
      RandomizedDelaySec = autoPrune.randomizedDelaySec;
      Persistent = autoPrune.persistent;
    };
  };

  mkAssertions = optionPath: autoPrune: [
    {
      assertion = autoPrune.allVolumes.enable -> autoPrune.enable;
      message = "Option ${optionPath}.autoPrune.allVolumes.enable requires ${optionPath}.autoPrune.enable";
    }
  ];
}
