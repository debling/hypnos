# Hypnos
Hypnos is status monitor for dwm that aims to be event based, no
polling (except for date/time).

Hypnos monitors the status of:
- Datetime
- Audio volume using alsa
- Microphone muted state using alsa
- TODO Wifi state
- TODO Battery state

## Usage
If you are using nix, you can just run `nix-build .` and when it
finishes, run `./result/bin/hypnos` to run the program. On nix, you
can also install Hypnos running `nix-env -if default.nix`.

If you are not using nix, Hypnos depends on the following system packages:
 - alsa-lib
 - libX11
 - libc
 - pkg-config (so cargo can link against)

After installing the dependencies, run `cargo build --release` to build
Hypnos, and after completion, you can run hypos with
`./target/release/hypnos`.
