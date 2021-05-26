{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.conduit;

  format = pkgs.formats.toml {};
  configFile = format.generate "conduit.toml" cfg.settings;
in
  {
    meta.maintainers = with maintainers; [ pstn piegames ];
    options.services.conduit = {
      enable = mkEnableOption "conduit";
      iHaveReadTheFederationWarning = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = ''
          Conduit upstream documentation contains the following warning:
          You should not join Matrix rooms without asking the admins first.
          We do not know whether Conduit is safe for general use yet, so you
          should assume there is some chance that it breaks rooms permanently
          for all participating users. We are not aware of such a bug today,
          but we would like to do more testing.

          This option will be removed upon removal of this warning from the
          upstream documentation.
        '';
      };


      extraEnvironment = mkOption {
        type = types.attrsOf types.str;
        description = "Extra Environment variables to pass to the conduit server.";
        default = {};
        example = { RUST_BACKTRACE="yes"; };
      };

      nginx.enable = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = ''
          Whether to enable a nginx vhost that will listen on all interfaces on tcp/443
          for https connections and proxy them to conduit. Further nginx configuration
          can be done by adapting <option>services.nginx.virtualHosts.&lt;settings.global.server_name&gt;</option>.
          When this is enabled, ACME will be used to retrieve a TLS certificate by default. To disable
          this, set the <option>services.nginx.virtualHosts.&lt;settings.global.server_name&gt;.enableACME</option> to
          <literal>false</literal> and if appropriate do the same for
          <option>services.nginx.virtualHosts.&lt;settings.global.server_name&gt;.forceSSL</option>.
        '';
      };
      package = mkOption {
        type = types.package;
        default = pkgs.matrix-conduit;
        defaultText = "pkgs.matrix-conduit";
        example = "pkgs.matrix-conduit";
        description = ''
          Package of the conduit matrix server to use.
        '';
      };

      settings = mkOption {
        type = types.submodule {
          freeformType = format.type;
          options = {
            global.server_name = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "example.com";
              description = "The server_name is the name of this server. It is used as a suffix for user # and room ids.";
            };
            global.port = mkOption {
              type = types.port;
              default = 6167;
              description = "The port Conduit will be running on. You need to set up a reverse proxy in your web server (e.g. apache or nginx), so all requests to /_matrix on port 443 and 8448 will be forwarded to the Conduit instance running on this port";
            };
            global.max_request_size = mkOption {
              type = types.ints.positive;
              default = 20000000;
              description = "Max request size in bytes. Don't forget to also change it in the proxy.";
            };
            global.allow_registration = mkOption {
              type = types.bool;
              default = false;
              description = "Whether new users can register on this server.";
            };
            global.allow_encryption = mkOption {
              type = types.bool;
              default = false;
              description = "Whether new encrypted rooms can be created. Note: existing rooms will continue to work.";
            };
            global.allow_federation = mkOption {
              type = types.bool;
              default = false;
              description = ''
                Whether this server federates with other servers.
                Upstream documentation contains the following warning:
                You should not join Matrix rooms without asking the admins first.
                We do not know whether Conduit is safe for general use yet, so you
                should assume there is some chance that it breaks rooms permanently
                for all participating users. We are not aware of such a bug today,
                but we would like to do more testing.
              '';
            };
            global.allow_jaeger = mkOption {
              type = types.bool;
              default = false;
              description = "Whether support monitoring and troubleshooting through jaeger is enabled on this server.";
            };
            global.trusted_servers = mkOption {
              type = types.listOf types.str;
              default = [ "matrix.org" ];
              description = "Servers trusted with signing server keys.";
            };

            global.address = mkOption {
              type = types.str;
              default = "::1";
              description = "Address to listen on for connections by the reverse proxy/tls terminator.";
            };
            global.database_path = mkOption {
              type = types.str;
              default = "/var/lib/matrix-conduit/conduit.db";
              readOnly = true;
              description = ''
                Path to the conduit database, the directory where conduit will save its data.
                Note that due to using the DynamicUser feature of systemd, this value should not be changed
                and is set to be read only.
              '';
            };
          };
        };
        default = {};
        description = ''
            Generates the conduit.toml configuration file. Refer to
            <link xlink:href="https://gitlab.com/famedly/conduit/-/blob/master/conduit-example.toml"/>
            for details on supported values.
            Note that database_path should not be set because the services reliance on systemd StateDir.
        '';
      };
    };


    config = mkIf cfg.enable {
      assertions = [
        {
          assertion = cfg.settings.global.server_name != null;
          message = "services.conduit.settings.global.server_name must be set.";
        }
        {
          assertion = cfg.settings.global.allow_federation -> cfg.iHaveReadTheFederationWarning;
          message = ''
            Conduit upstream documentation contains the following warning:
            You should not join Matrix rooms without asking the admins first.
            We do not know whether Conduit is safe for general use yet, so you
            should assume there is some chance that it breaks rooms permanently
            for all participating users. We are not aware of such a bug today,
            but we would like to do more testing.
            You need to acknowledge this warning by setting
            services.conduit.iHaveReadTheFederationWarning = true
          '';
        }
      ];

      systemd.services.conduit = {
        description = "Conduit Matrix Server";
        documentation = [ "https://gitlab.com/famedly/conduit/" ];
        wantedBy = [ "multi-user.target" ];
        environment = lib.mkMerge ([
          { CONDUIT_CONFIG = configFile; }
          cfg.extraEnvironment
        ]);
        serviceConfig = {
          DynamicUser = true;
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          PrivateDevices = true;
          PrivateMounts = true;
          PrivateUsers = true;
          RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
          RestrictNamespaces = true;
          RestrictRealtime = true;
          SystemCallArchitectures = "native";
          SystemCallFilter = [
            "@system-service"
            "~@privileged"
          ];
          StateDirectory = "matrix-conduit";
          ExecStart = "${cfg.package}/bin/conduit";
          Restart = "on-failure";
          RestartSec = 10;
          StartLimitBurst = 5;
        };
      };
      services.nginx = mkIf cfg.nginx.enable {
        enable = mkDefault true;
        virtualHosts.${cfg.settings.global.server_name} = {
          enableACME = mkDefault true;
          forceSSL = mkDefault true;
          locations."/".extraConfig = "deny all;";
          locations."/_matrix" = let
            rawUpstream = cfg.settings.global.address;
            isIPv6 = ip: builtins.length (lib.splitString ":" ip) > 2;
            upstream = if (isIPv6 rawUpstream) then "[${rawUpstream}]" else rawUpstream;
          in {
            proxyPass = "http://${upstream}:${(toString cfg.settings.global.port)}";
            extraConfig = "client_max_body_size ${(toString cfg.settings.global.max_request_size)};";
          };
        };
      };
    };
  }
