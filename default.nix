{ pkgs ? import <nixpkgs> { } }:

with pkgs;

rustPlatform.buildRustPackage {
  pname = "hypnos";
  version = "0.0.1";

  src = ./.;

  buildInputs = [ xorg.libX11 alsaLib  ];
  nativeBuildInputs = [ pkg-config ];

  cargoSha256 = "05v215i0vrl5l0x9c6mjip0i3caic00rhrxi7jlkm5d3kwxrnfpd";

  meta = with stdenv.lib; {
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
