import ./make-test-python.nix ({ pkgs, ... } : let


  name = "conduit";

in {


  nodes = {
    conduit = args: {
      services.conduit = {
        enable = true;
        settings.global.server_name = "conduit1.localhost";
        nginx.enable = true;
        extraEnvironment.RUST_BACKTRACE = "yes";
      };
      services.nginx.virtualHosts."conduit1.localhost" = {
        enableACME = false;
        forceSSL = false;
        enableSSL = false;
      };
    };
  };

  testScript = ''
    start_all()
    conduit.wait_for_unit("conduit.service")
    conduit.wait_until_succeeds(
        "curl --fail http://[::1]:80/_matrix/client/r0/login"
    )
    conduit.wait_for_file("/var/lib/matrix-conduit/conduit.db")
  '';

})
