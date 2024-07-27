{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [
        # only linux support
        "aarch64-linux"
        "x86_64-linux"
      ];

      forEachSystem = fn: nixpkgs.lib.genAttrs systems (system: fn
        nixpkgs.legacyPackages.${system});

      forEachSystemPkgs = fn: nixpkgs.lib.genAttrs systems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        fn pkgs
      );
    in
    {
      packages = forEachSystemPkgs (pkgs:
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

      devShell = forEachSystem (pkgs:
        pkgs.mkShell {
          packages = with pkgs; [ rustc cargo rustfmt rust-analyzer xorg.libX11 alsaLib pkg-config ];
          RUST_SRC_PATH = pkgs.rustPlatform.rustLibSrc;
        }
      );

      formatter = forEachSystemPkgs (pkgs: pkgs.nixpkgs-fmt);
    };
}
