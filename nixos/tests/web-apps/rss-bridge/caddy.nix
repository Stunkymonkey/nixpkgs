import ../../make-test-python.nix (
  { lib, pkgs, ... }:
  {
    name = "rss-bridge-caddy";
    meta.maintainers = with lib.maintainers; [ mynacol ];

    nodes.machine =
      { ... }:
      {
        services.rss-bridge = {
          enable = true;
          webserver = "caddy";
          virtualHost = "rss-bridge:80";
          config.system.enabled_bridges = [ "DemoBridge" ];
        };
      };

    testScript = ''
      machine.wait_for_unit("caddy.service")
      machine.wait_for_unit("phpfpm-rss-bridge.service")

      # check for successful feed download
      response = machine.succeed("curl -f 'http://localhost:80/?action=display&bridge=DemoBridge&context=testCheckbox&format=Atom'")
      assert 'xml version="1.0"' in response, "Feed didn't load successfully"
    '';
  }
)
