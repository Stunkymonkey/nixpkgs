{ config, lib, pkgs, ... }:
let
  cfg = config.virtualisation.googleComputeImage;
  defaultConfigFile = pkgs.writeText "configuration.nix" ''
    { ... }:
    {
      imports = [
        <nixpkgs/nixos/modules/virtualisation/google-compute-image.nix>
      ];
    }
  '';
in
{

  imports = [ ./google-compute-config.nix ];

  options = {
    virtualisation.googleComputeImage.diskSize = lib.mkOption {
      type = with lib.types; either (enum [ "auto" ]) int;
      default = "auto";
      example = 1536;
      description = ''
        Size of disk image. Unit is MB.
      '';
    };

    virtualisation.googleComputeImage.configFile = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      description = ''
        A path to a configuration file which will be placed at `/etc/nixos/configuration.nix`
        and be used when switching to a new configuration.
        If set to `null`, a default configuration is used, where the only import is
        `<nixpkgs/nixos/modules/virtualisation/google-compute-image.nix>`.
      '';
    };

    virtualisation.googleComputeImage.compressionLevel = lib.mkOption {
      type = lib.types.int;
      default = 6;
      description = ''
        GZIP compression level of the resulting disk image (1-9).
      '';
    };
    virtualisation.googleComputeImage.efi = lib.mkEnableOption "EFI booting";
  };

  #### implementation
  config = {
    boot.initrd.availableKernelModules = [ "nvme" ];
    boot.loader.grub = lib.mkIf cfg.efi {
      device = lib.mkForce "nodev";
      efiSupport = true;
      efiInstallAsRemovable = true;
    };

    fileSystems."/boot" = lib.mkIf cfg.efi {
      device = "/dev/disk/by-label/ESP";
      fsType = "vfat";
    };

    system.build.googleComputeImage = import ../../lib/make-disk-image.nix {
      name = "google-compute-image";
      postVM = ''
        PATH=$PATH:${with pkgs; lib.makeBinPath [ gnutar gzip ]}
        pushd $out
        mv $diskImage disk.raw
        tar -Sc disk.raw | gzip -${toString cfg.compressionLevel} > \
          nixos-image-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.raw.tar.gz
        rm $out/disk.raw
        popd
      '';
      format = "raw";
      configFile = if cfg.configFile == null then defaultConfigFile else cfg.configFile;
      partitionTableType = if cfg.efi then "efi" else "legacy";
      inherit (cfg) diskSize;
      inherit config lib pkgs;
    };

  };

}
