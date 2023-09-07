{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-snapshotter = {
      url = "github:pdtpartners/nix-snapshotter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, nix-snapshotter, ... }: {
    homeConfigurations.myuser = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      modules = [
        {
          home = {
            username = "runner";
            homeDirectory = "/home/runner";
            stateVersion = "23.11";
          };

          programs.home-manager.enable = true;

          # Let home-manager automatically start systemd user services.
          # Will eventually become the new default.
          systemd.user.startServices = "sd-switch";
        }
        ({ pkgs, ... }: {
          # (1) Import home-manager module.
          imports = [ nix-snapshotter.rootless ];

          # (2) Add overlay.
          nixpkgs.overlays = [ nix-snapshotter.overlays.default ];

          # (3) Enable service.
          services.nix-snapshotter.rootless = {
            enable = true;
            setContainerdSnapshotter = true;
          };

          # (4) Add a containerd CLI like nerdctl.
          home.packages = [ pkgs.nerdctl ];
        })
      ];
    };
  };
}