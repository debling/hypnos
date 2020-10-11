{ pkgs ? import <nixpkgs> { } }:

with pkgs;

rustPlatform.buildRustPackage {
  pname = "async-dwm-status";
  version = "0.0.1";

  src = ./.;
  nativeBuildInputs = [ xorg.libX11 alsaLib pkg-config ];

  cargoSha256 = "05v215i0vrl5l0x9c6mjip0i3caic00rhrxi7jlkm5d3kwxrnfpd";

  meta = with stdenv.lib; {
    description = "Suckless dwm status application that is event driven";
    license = licenses.mit;
  };
}
