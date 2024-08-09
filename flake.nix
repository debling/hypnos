{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      releaseSystems = [
        # only linux support
        "aarch64-linux"
        "x86_64-linux"

      ];
      devSystems = releaseSystems ++ [
        # development on darwin
        "aarch64-darwin"
        "x86_64-dawin"
      ];

      forEachSystem = systems: fn: nixpkgs.lib.genAttrs systems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        fn pkgs
      );
    in
    {
      packages = forEachSystem releaseSystems (pkgs:
        {
          default = self.packages.${pkgs.system}.hypnos;

          hypnos = pkgs.rustPlatform.buildRustPackage {
            pname = "hypnos";
            version = "0.0.1";

            src = ./.;

            nativeBuildInputs = [ pkgs.pkg-config ];
            buildInputs = [ pkgs.xorg.libX11 pkgs.alsaLib ];

            cargoHash = "sha256-DAReWqhB7kOkwo2lExgD7EMh/3pDBVHg9ZWa44WgYm8=";

            meta = {
              license = pkgs.lib.licenses.mit;
              platforms = pkgs.lib.platforms.linux;
            };
          };
        }
      );

      devShell = forEachSystem devSystems (pkgs:
        pkgs.mkShell {
          packages = with pkgs; [ rustc clippy cargo rustfmt rust-analyzer pkg-config ];
          RUST_SRC_PATH = pkgs.rustPlatform.rustLibSrc;
        }
      );

      formatter = forEachSystem devSystems (pkgs: pkgs.nixpkgs-fmt);
    };
}
