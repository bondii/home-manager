# Pontus Home Manager

Modular Home Manager configurations packaged as a Nix flake. It builds per‑user environments and also exposes NixOS system configurations so you can move the same modules to a full OS setup.

## Why no configuration.nix?
NixOS configs live under `nixos/` and are exported via `nixosConfigurations`, so you can still keep host files organized without a top‑level `configuration.nix`.

## Project structure
- `flake.nix` — Declares inputs and publishes `homeConfigurations` by importing `hosts/` and the factory in `lib/`.
- `lib/mkHome.nix` — Factory that assembles a Home Manager config: wires `nixpkgs` (with `nixGL` overlay), loads base modules, and conditionally includes feature modules; accepts `extraModules`/`extraSpecialArgs`.
- `lib/mkNixos.nix` — Factory that assembles a NixOS system config and wires Home Manager into `home-manager.users`.
- `modules/` — Reusable modules:
  - `core/` options and cross‑cutting base config (enables HM, XDG, formatting tools).
  - `features/` opt‑in slices gated by `pontus.features.*` (e.g. `dev`, `gui`, `stylix`).
  - `programs/` tool integrations (git, zsh, ssh, nvim, vscode).
- `hosts/` — Host presets calling `mkHome` with `system`, `user`, `hostName`, and `features`.
- `nixos/` — NixOS modules and host presets (hardware config, system settings, and OS‑level GUI toggles).

## How pieces relate
- `flake.nix` exposes `homeConfigurations`.
- `flake.nix` also exposes `nixosConfigurations`.
- `hosts/default.nix` defines named profiles using `mkHome`.
- `nixos/hosts/default.nix` defines named systems using `mkNixos`.
- `lib/mkHome.nix` composes `modules/*` and injects `features`/`hostName` as options (`modules/core/options.nix`).
- Feature modules activate with `lib.mkIf config.pontus.features.<flag>`.

## Build, test, apply
- List outputs: `nix flake show`
- Build without switching: `nix build .#homeConfigurations.<profile>.activationPackage`
- Apply (dry run): `home-manager switch --flake .#<profile> --dry-run`
- Apply: `home-manager switch --flake .#<profile>`
- Build NixOS (no switch): `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
- Switch NixOS: `sudo nixos-rebuild switch --flake .#<host>`
- Sanity: `nix flake check` (evaluates hosts)

## Try NixOS in a VM
`nixos-shell` is still largely `NIX_PATH`-based. This flake exports an app that pins `nixpkgs` correctly for it.

- Run: `nix run .#nixos-shell`
- Override the config module: `nix run .#nixos-shell -- -I nixos-config=./nixos/hosts/nixos-shell.nix`

## Available profiles
- `pontus` / `pontus@arch-desktop` — full graphical environment.
- `pontus@ssh-minimal` — headless/SSH‑friendly.
## Available NixOS systems
- `arch-desktop` — full graphical NixOS host.
- `nixos-shell` — minimal host for `nixos-shell` testing.

## Feature flags
Boolean flags set per host in `hosts/` and defaulted in `modules/core/options.nix`:
- `gui`, `dev`, `nixvim`, `fonts`, `stylix`, `vscode`, `laptop`.

## Adding things
- New host/profile: add a `mkHome { … }` entry in `hosts/default.nix` and return it under a friendly name (e.g. `"pontus@ssh-minimal"`).
- New always‑on program: create `modules/programs/foo.nix`, then add it to `baseModules` in `lib/mkHome.nix`.
- New feature flag: declare it in `modules/core/options.nix`, implement `modules/features/foo.nix` guarded by `lib.mkIf config.pontus.features.foo`, and include it conditionally in `lib/mkHome.nix`.
- Per‑host override: pass an inline module via `extraModules` in the host’s `mkHome` call.

See `AGENTS.md` for contributor guidelines and coding/testing conventions.
