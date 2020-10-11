{ pkgs ? import <nixpkgs> { } }:

with pkgs;

pkgs.mkShell {
  buildInputs = [ rustc cargo rls xorg.libX11 alsaLib pkg-config ];
}
