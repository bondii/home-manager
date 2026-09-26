# Pontus Home Manager

Modular Home Manager configurations packaged as a Nix flake. It builds per‑user environments (not a NixOS system) and exposes named profiles you can switch to locally or over SSH.

## Why no configuration.nix?
`configuration.nix` is for NixOS system configs. This repo targets user‑level Home Manager via flakes, so profiles are applied with `home-manager switch --flake ...` rather than through NixOS.

## Project structure
- `flake.nix` — Declares inputs and publishes `homeConfigurations` by importing `hosts/` and the factory in `lib/`.
- `lib/mkHome.nix` — Factory that wires `nixpkgs` (with the nixGL overlay), imports module definitions, and supplies host defaults; accepts `extraModules`/`extraSpecialArgs`.
- `modules/` — Reusable modules:
  - `core/` options and cross‑cutting base config (enables HM, XDG, formatting tools).
  - `features/` opt‑in slices gated by `pontus.features.*` (e.g. `dev`, `gui`, `stylix`).
  - `programs/` tool integrations (git, zsh, ssh, nvim, vscode).
- `hosts/` — Explicit presets, Arch monitor profiles, and a shared work profile containing manually started Cloud SQL proxy services.
- `modules/programs/nvim/` — Neovim settings, keymaps, plugin, LSP, formatting, and runtime fragments, composed without reordering lists or Lua.
- `tests/` — Feature-boundary assertions and isolated activation, locking, and helper checks.
- `admin/acpi-wake/` — System administrator assets; never installed by Home Manager.

## How pieces relate
- `flake.nix` exposes `homeConfigurations`.
- `hosts/default.nix` defines named profiles using `mkHome`.
- `lib/mkHome.nix` composes `modules/*` and supplies `features` as `mkDefault` values for the options in `modules/core/options.nix`.
- Feature modules activate with `lib.mkIf config.pontus.features.<flag>`.

## Build, test, apply
- List standard outputs: `nix flake show`; list profile names: `nix eval .#homeConfigurations --apply builtins.attrNames`.
- Enter the pinned verification environment: `nix develop`.
- Format: `nix fmt`; lint: `nix develop -c statix check .` and `nix develop -c deadnix --fail .`.
- Evaluate both profiles and all assertions: `nix flake check --no-build --no-update-lock-file`.
- Build both profiles and all checks: `nix flake check --no-update-lock-file`.
- Build one profile without switching: `nix build --no-link '.#homeConfigurations.pontus@arch-desktop.activationPackage'` (or `pontus@ssh-minimal`).
- Preview a switch explicitly: `home-manager switch --flake '.#pontus@arch-desktop' --dry-run`.
- Apply explicitly: `home-manager switch --flake '.#pontus@arch-desktop'`.

CI evaluates both activation derivations and builds lightweight formatting, lint,
feature, activation, locking, helper, and editor checks. Full activation builds run
locally through `nix flake check`; CI does not download/build the entire desktop.
The custom activation tests execute only the selected hook bodies in a dry-run
harness, never the complete activation script against a live home.

## Available profiles
- `pontus` / `pontus@arch-desktop` — full graphical environment.
- `pontus@ssh-minimal` — headless/SSH‑friendly.

## Feature flags
All flags default to **false** in `modules/core/options.nix`:
- `gui`, `dev`, `nixvim`, `fonts`, `stylix`, `vscode`, `laptop`.

Both existing presets set every flag explicitly. The desktop enables all seven;
SSH enables `dev`, `nixvim`, and `stylix`. GUI development applications require
both `gui` and `dev`. Laptop display services require `gui` and `laptop`, while
its CLI security-key tools require only `laptop`. Disabling `nixvim` also disables
dependent editor aliases, picker helpers, and VS Code/Cursor integration.

Module overrides read and set `config.pontus.features`. For example:

```nix
extraModules = [ { pontus.features.fonts = false; } ];
```

That ordinary definition overrides the factory's `mkDefault`. The legacy
`features` special argument remains available as deprecated factory input data;
it does not reflect module overrides and must not control module behavior.

## Adding things
- New host/profile: add a `mkHome { … }` entry in `hosts/default.nix` and return it under a friendly name (e.g. `"pontus@ssh-minimal"`).
- New always‑on program: create `modules/programs/foo.nix`, then add it to `baseModules` in `lib/mkHome.nix`.
- New feature flag: declare it in `modules/core/options.nix`, implement `modules/features/foo.nix` guarded by `lib.mkIf config.pontus.features.foo`, and import its definition unconditionally in `lib/mkHome.nix`.
- Per‑host override: pass an inline module via `extraModules` in the host’s `mkHome` call.

See `AGENTS.md` for contributor guidelines and coding/testing conventions.

## Arch integration and rollout

The graphical host uses Mesa through Home Manager's
`targets.genericLinux.nixGL` integration. Kitty, Picom, and imv packages are
wrapped directly; `kitty-gl`, `picom-gl`, and `imv-gl` remain compatibility
forwarders. The pinned nixGL overlay's `system` compatibility attribute remains
until the upstream dependency stops requiring it.

Arch supplies `/usr/bin/systemctl`, `/usr/bin/i3lock`, its PAM configuration, and
the graphical session. Preserve those host dependencies. Manual and idle locks
use a pixelated screenshot, falling back to a solid-black background if
preparation fails or the image locker reports an error. Suspend attempts the
same image with a two-second preparation deadline, then uses solid black if
preparation fails or times out. The wrapper holds the sleep inhibitor during
preparation and passes it to i3lock; i3lock releases it when its window is
ready. If an image locker fails after launch, its inherited inhibitor may be
released before the solid fallback is ready. If `/usr/bin/i3lock` is unavailable
or fails, this configuration cannot guarantee that the screen is locked.
Automated tests use a fake locker; they do not validate PAM or actual suspend
behavior.

After choosing to switch the desktop profile, manually verify:

1. Kitty and imv launch through their normal commands and desktop launchers;
   compatibility commands still work and Picom renders normally.
2. The lock keybinding, idle locking, and suspend show the pixelated image,
   accept the correct password, and reject an incorrect password. Check that
   suspend locks before sleep and resumes to the locker. Also check that an
   unavailable screenshot tool falls back to solid black before suspend.
3. Monitor hotplug selects the expected autorandr profile, and Neovim keymaps,
   completion, formatting, and project tools retain their behavior.

The ACPI workaround is a separate administrator responsibility. Existing
installed files remain untouched by Home Manager. See
[administrator instructions](admin/acpi-wake/README.md) for comparison, backup,
installation, and removal. General npm prefix support remains available, but
activation does not install npm software or access the network.

Keep `home.stateVersion` at its original compatibility value when updating
inputs. Nixvim intentionally retains its independently pinned Nixpkgs input.
