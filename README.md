# Pontus Home Manager

This repository contains modular Home Manager configurations that can be reused across multiple machines.

## Structure

- `flake.nix` – entrypoint that exposes the Home Manager configurations exported from `hosts/default.nix`.
- `lib/mkHome.nix` – helper that assembles a Home Manager configuration from common modules and feature flags.
- `modules/` – reusable modules grouped into `core`, `features`, and `programs`.
- `hosts/` – host presets that call `mkHome` with machine-specific overrides.

## Available profiles

- `pontus` / `pontus@arch-desktop` – full graphical environment with all tooling enabled.
- `pontus@ssh-minimal` – text-first profile suitable for SSH sessions (GUI packages disabled).

Switch using, for example:

```sh
home-manager switch --flake .#pontus@ssh-minimal
```

## Feature flags

Every host can override the following boolean flags when invoking `mkHome`:

- `gui` – graphical stack (i3, Kitty, dunst, etc.).
- `dev` – language servers and CLI tooling.
- `nixvim` – Neovim configuration via nixvim.
- `vscode` – VS Code / Cursor configuration.
- `fonts` – extra font packages.
- `stylix` – base16-driven theming (GTK/Qt, fonts, CLI targets) via Stylix.

By combining these flags you can tailor lightweight setups (e.g. disable `gui` and `fonts` but keep `nixvim` + `dev` for SSH).

To create a new host, add an entry to `hosts/default.nix` with the desired overrides or create an additional file that returns an attrset of configurations.
