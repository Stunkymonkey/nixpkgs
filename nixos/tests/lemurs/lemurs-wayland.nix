{ lib, ... }:
{
  name = "lemurs-wayland";
  meta = with lib.maintainers; {
    maintainers = [
      nullcube
      stunkymonkey
    ];
  };

  nodes.machine =
    { ... }:
    {
      imports = [ ../common/user-account.nix ];

      # Required for wayland to work with Lemurs
      services.seatd.enable = true;
      users.users.alice.extraGroups = [ "seat" ];

      services.displayManager.lemurs.enable = true;

      programs.river-classic.enable = true;
    };

  testScript = ''
    machine.start()

    machine.wait_for_unit("multi-user.target")
    machine.wait_until_succeeds("pgrep -f 'lemurs.*tty1'")
    machine.screenshot("postboot")

    with subtest("Log in as alice to river"):
      machine.send_chars("\n")
      machine.send_chars("alice\n")
      machine.sleep(1)
      machine.send_chars("foobar\n")
      machine.sleep(1)
      machine.wait_until_succeeds("pgrep -u alice river")
      machine.sleep(10)
      machine.succeed("pgrep -u alice river")
      machine.screenshot("postlogin")

    with subtest("Session is registered on seat0"):
      session = machine.succeed("loginctl list-sessions --no-legend | awk '$3 == \"alice\" && $6 == \"user\" {print $1}'").strip()
      machine.succeed(f"loginctl show-session {session} -p Seat --value | grep -x seat0")
      machine.succeed(f"loginctl show-session {session} -p Active --value | grep -x yes")
      machine.succeed(f"loginctl show-seat seat0 -p ActiveSession --value | grep -x {session}")
  '';
}
