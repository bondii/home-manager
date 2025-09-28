# Pontus Home Manager

Modular Home Manager configurations packaged as a Nix flake. It builds per‑user environments (not a NixOS system) and exposes named profiles you can switch to locally or over SSH.

## Why no configuration.nix?
`configuration.nix` is for NixOS system configs. This repo targets user‑level Home Manager via flakes, so profiles are applied with `home-manager switch --flake ...` rather than through NixOS.

## Project structure
- `flake.nix` — Declares inputs and publishes `homeConfigurations` by importing `hosts/` and the factory in `lib/`.
- `lib/mkHome.nix` — Factory that assembles a Home Manager config: wires `nixpkgs` (with `nixGL` overlay), loads base modules, and conditionally includes feature modules; accepts `extraModules`/`extraSpecialArgs`.
- `modules/` — Reusable modules:
  - `core/` options and cross‑cutting base config (enables HM, XDG, formatting tools).
  - `features/` opt‑in slices gated by `pontus.features.*` (e.g. `dev`, `gui`, `stylix`).
  - `programs/` tool integrations (git, zsh, ssh, nvim, vscode).
- `hosts/` — Host presets calling `mkHome` with `system`, `user`, `hostName`, and `features`.

## How pieces relate
- `flake.nix` exposes `homeConfigurations`.
- `hosts/default.nix` defines named profiles using `mkHome`.
- `lib/mkHome.nix` composes `modules/*` and injects `features`/`hostName` as options (`modules/core/options.nix`).
- Feature modules activate with `lib.mkIf config.pontus.features.<flag>`.

## Build, test, apply
- List outputs: `nix flake show`
- Build without switching: `nix build .#homeConfigurations.<profile>.activationPackage`
- Apply (dry run): `home-manager switch --flake .#<profile> --dry-run`
- Apply: `home-manager switch --flake .#<profile>`
- Sanity: `nix flake check` (evaluates hosts)

## Available profiles
- `pontus` / `pontus@arch-desktop` — full graphical environment.
- `pontus@ssh-minimal` — headless/SSH‑friendly.

## Feature flags
Boolean flags set per host in `hosts/` and defaulted in `modules/core/options.nix`:
- `gui`, `dev`, `nixvim`, `fonts`, `stylix`, `vscode`, `laptop`.

## Adding things
- New host/profile: add a `mkHome { … }` entry in `hosts/default.nix` and return it under a friendly name (e.g. `"pontus@ssh-minimal"`).
- New always‑on program: create `modules/programs/foo.nix`, then add it to `baseModules` in `lib/mkHome.nix`.
- New feature flag: declare it in `modules/core/options.nix`, implement `modules/features/foo.nix` guarded by `lib.mkIf config.pontus.features.foo`, and include it conditionally in `lib/mkHome.nix`.
- Per‑host override: pass an inline module via `extraModules` in the host’s `mkHome` call.

See `AGENTS.md` for contributor guidelines and coding/testing conventions.
