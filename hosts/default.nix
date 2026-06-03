{ lib, system, home-manager, user, homeDirectory, neovim, nixpkgs-unstable, skillrunner, sapo-hub, ...
}: {
  nixos = lib.nixosSystem {
    inherit system;
    modules = [
      ./desktop/configuration.nix
      sapo-hub.nixosModules.default
      ({ pkgs, ... }:
      let
        tailscaleHost = "nixos.tailee43b7.ts.net";
        certDir = "/var/lib/tailscale-certs";
        certFile = "${certDir}/${tailscaleHost}.crt";
        keyFile = "${certDir}/${tailscaleHost}.key";
      in {
        services.sapo-hub = {
          enable = true;
          host = tailscaleHost;
          scheme = "https";
          secretsFile = "/etc/sapo_hub/secrets";
          sshKeyFile = "/etc/sapo_hub/id_ed25519";
        };

        services.nginx = {
          enable = true;
          recommendedProxySettings = true;
          recommendedGzipSettings = true;
          recommendedOptimisation = true;

          virtualHosts.${tailscaleHost} = {
            forceSSL = true;
            sslCertificate = certFile;
            sslCertificateKey = keyFile;
            locations."/" = {
              proxyPass = "http://127.0.0.1:4000";
              proxyWebsockets = true;
            };
          };
        };

        # nginx must wait for the cert files to exist before starting
        systemd.services.nginx = {
          wants = [ "tailscale-cert.service" ];
          after = [ "tailscale-cert.service" ];
        };

        # Fetch/renew the Tailscale TLS certificate
        systemd.services.tailscale-cert = {
          description = "Obtain/renew Tailscale TLS certificate";
          after = [ "tailscale.service" "network-online.target" ];
          wants = [ "network-online.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = pkgs.writeShellScript "tailscale-cert-renew" ''
              set -euo pipefail
              mkdir -p ${certDir}
              ${pkgs.tailscale}/bin/tailscale cert \
                --cert-file ${certFile} \
                --key-file ${keyFile} \
                ${tailscaleHost}
              chmod 644 ${certFile}
              chmod 640 ${keyFile}
              chgrp nginx ${keyFile}
            '';
          };
        };

        # Run once on boot (30s delay so tailscale is authenticated) and weekly
        systemd.timers.tailscale-cert = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "30s";
            OnCalendar = "weekly";
            Persistent = true;
          };
        };

        services.tailscale.enable = true;

        networking.firewall = {
          allowedTCPPorts = [ 80 443 ];
          trustedInterfaces = [ "tailscale0" ];
        };
      })
      { _module.args = { inherit user homeDirectory; }; }
      home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.${user} = {
            imports = [
              skillrunner.homeManagerModules.default
              ../home
              {
                _module.args = {
                  inherit user system homeDirectory neovim nixpkgs-unstable skillrunner;
                };
              }
            ];
          };
        };
      }
    ];
  };
}
