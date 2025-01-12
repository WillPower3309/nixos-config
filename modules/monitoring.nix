{ config, pkgs, ... }:

let
  baseDomain = "${config.networking.hostName}.willmckinnon.com";
  loopbackAddr = "127.0.0.1";
  lokiDataDir = "/persist/var/lib/loki";

in {
  age.secrets.grafanaAdminPassword = {
    file = ../secrets/grafanaAdminPassword.age;
    owner = "grafana";
    group = "grafana";
  };

  services = {
    grafana = {
      enable = true;
      declarativePlugins = [];
      settings = {
        server = {
          domain = "grafana.${baseDomain}";
          http_port = 2342;
          http_addr = loopbackAddr;
        };

        security = { # TODO: add more
          content_security_policy = true;
          cookie_secure = true;
          disable_gravatar = true;
          disable_initial_admin_creation = true;

          admin_user = "admin";
          admin_password = "$__file{${config.age.secrets.grafanaAdminPassword.path}}";
        };

# TODO
#        provision = {
#          enable = true;
#          datasources.settings = {
#            apiVersion = 1;
#            datasources = [
#              {
#                name = "Prometheus";
#                url = "http://localhost:${toString config.services.prometheus.port}";
#                access = "direct";
#                type = "prometheus";
#                isDefault = true;
#              }
#              {
#                name = "Loki";
#                url = "http://localhost:${toString config.services.loki.configuration.server.http_listen_port}";
#                access = "direct";
#                type = "loki";
#              }
#            ];
#          };
          # TODO: dashboards
          # TODO: alerting
#        };
      };
    };

    prometheus = {
      enable = true;
      port = 9001;

      exporters = {
        node = {
          enable = true;
          enabledCollectors = [ "systemd" ];
          port = 9002;
        };
      };

      scrapeConfigs = [{
        job_name = "${config.networking.hostName}-scrape";
        static_configs = [{
          targets = [ "${loopbackAddr}:${toString config.services.prometheus.exporters.node.port}" ];
        }];
      }];
    };

    loki = {
      enable = true;

      configuration = {
        server.http_listen_port = 3100;
        auth_enabled = false;

        ingester = {
          lifecycler = {
            address = loopbackAddr;
            ring = {
              kvstore = {
                store = "inmemory";
              };
              replication_factor = 1;
            };
          };
          chunk_idle_period = "1h";
          max_chunk_age = "1h";
          chunk_target_size = 999999;
          chunk_retain_period = "30s";
        };

        schema_config = {
          configs = [{
            from = "2024-04-01";
            store = "tsdb";
            object_store = "filesystem";
            schema = "v13";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }];
        };

        storage_config = {
          tsdb_shipper = {
            active_index_directory = "${lokiDataDir}/tsdb-index";
            cache_location = "${lokiDataDir}/tsdb-cache";
            cache_ttl = "24h";
          };

          filesystem = {
            directory = "${lokiDataDir}/chunks";
          };
        };

        limits_config = {
          reject_old_samples = true;
          reject_old_samples_max_age = "168h";
        };

        table_manager = {
          retention_deletes_enabled = false;
          retention_period = "0s";
        };

        compactor = {
          working_directory = lokiDataDir;
          compactor_ring = {
            kvstore = {
              store = "inmemory";
            };
          };
        };
      };
    };

    promtail = {
      enable = true;

      configuration = {
        server.http_listen_port = 28183;

        positions = {
          filename = "/tmp/positions.yaml";
        };

        clients = {
          url = "http://${loopbackAddr}:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push";
        };

        scrape_configs = [{
          job_name = "journal";
          journal = {
            max_age = "12h";
            labels = {
              job = "systemd-journal";
              host = config.networking.hostName;
            };
          };
          relabel_configs = {
            source_labels = ["__journal__systemd_unit"];
            target_label = "unit";
          };
        }];
      };
    };

    nginx.virtualHosts.${config.services.grafana.domain} = {
      useACMEHost = baseDomain;
      forceSSL = true;
      kTLS = true;
      locations."/" = {
        proxyPass = "http://${config.services.grafana.addr}:${toString config.services.grafana.port}";
        proxyWebsockets = true;
      };
    };
  };

  system.activationScripts.loki-dir-init.text = ''
    install -d -o ${config.services.loki.user} -g ${config.services.loki.group} ${lokiDataDir}
  '';
}

