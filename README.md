# eden-flake

A nix flake for [Eden](https://git.eden-emu.dev/eden-emu/eden), tracking the official [nightly](https://git.eden-emu.dev/eden-ci/nightly/releases) builds.

The package installs the official nightly **PGO AppImage** (dwarfs-packaged) directly from upstream — there is nothing to compile, so no build cache (e.g. Cachix) is needed. The nightly PGO build is ~10–30% faster than standard builds and is the recommended variant upstream.

> [!NOTE]
> Upstream distributes the Linux nightlies as dwarfs-based AppImages rather than squashfs, so nixpkgs' `appimageTools` can't extract them; this flake extracts the embedded dwarfs payload directly.

## Installation
Add this flake to the inputs of your `flake.nix`.

### Flake
  ```nix
  # flake.nix
  {
    inputs = {
      eden = {
        url = "github:sayidabyan/eden-flake";
        inputs.nixpkgs.follows = "nixpkgs";
      };
    };
  }
  ```

### NixOS
```nix
{
  imports = [
    inputs.eden.nixosModules.default
  ];

  programs.eden = {
    enable = true;
  };
}
```

### home-manager
```nix
{
  imports = [
    inputs.eden.homeModules.default
  ];

  programs.eden = {
    enable = true;
  };
}
```

## Usage
Run `$ eden` or run from the .desktop entry.

### Portal warning
If launching eden from a terminal prints
`qt.qpa.services: Failed to register with host portal ... App info not found`,
that warning is harmless: Qt tries to register with `xdg-desktop-portal`,
which can't resolve the app's desktop file on some setups and then simply
skips registration. To silence it completely, run eden with:

    EDEN_NO_PORTAL=1 eden

## Updating the nightly
To point the flake at a newer nightly ("Eden Nightly - <date>"), edit `package.nix`:

1. Set `tagName` to the release tag (e.g. `v1791243079.10bcd2d849`), `commit` to the eden commit short hash and `date` to the release date.
2. Recompute the two `sha256` hashes for the amd64/aarch64 **PGO** AppImages, e.g.:

   ```sh
   nix hash convert --to sri --hash-algo sha256 "$(nix-prefetch-url --type sha256 <url> | head -1)"
   ```

   or simply build once (`nix build .#eden`) and copy the `got: sha256-...` from the mismatch error.
