# Repository Guidelines

## Project Structure & Module Organization
This flake centralizes Home Manager configs. `flake.nix` exposes `homeConfigurations`, while `lib/mkHome.nix` merges base modules with feature flags (`gui`, `dev`, `nixvim`, `fonts`, `stylix`, `vscode`, `laptop`). Host presets live in `hosts/`; keep host-specific overrides there or in a new attrset. Shared logic belongs in `modules/core/`, optional toggles in `modules/features/`, and tool-specific plumbing in `modules/programs/` (git, zsh, nvim, etc.). Place new reusable modules in the matching folder and register them in `lib/mkHome.nix` when they should be part of the default stack.

## Build, Test, and Development Commands
- `nix flake show` — quick inventory of available `homeConfigurations`.
- `nix build .#homeConfigurations.pontus.activationPackage` — ensure the main profile builds without switching.
- `home-manager switch --flake .#pontus@arch-desktop` — apply the graphical profile locally; add `--dry-run` when validating.
- `home-manager switch --flake .#pontus@ssh-minimal --dry-run` — sanity-check the headless profile from any machine.

## Coding Style & Naming Conventions
Use two-space indentation and trailing semicolons for attrsets, mirroring the existing Nix files. Prefer lowercase `camelCase` for option names (`features.gui`) and hyphen-free file names (`programs/git.nix`). Format with `alejandra .` (nixpkgs' `nixfmt` is acceptable but keep output consistent). Run `statix check .` and `deadnix .` to catch smell regressions. Keep modules focused: one concern per file, merging through `lib.mkMerge` only when necessary.

## Testing Guidelines
Run `nix flake check` before pushing; it evaluates every host in `hosts/`. For host-level changes, build the affected activation package (`nix build .#homeConfigurations.<profile>.activationPackage`) and perform a dry-run switch. When adding options, add minimal regression tests via assertions or by extending the example host that exercises the feature to fail fast.

## Commit & Pull Request Guidelines
Write imperative, scope-first summaries (`Add Nix LSP`, `Fix Stylix theme regression`) matching recent history. Each commit should leave `nix flake check` passing. For PRs, explain which hosts/features changed, note any new module flags, and include output snippets from `nix build` or `home-manager switch --dry-run` when behavior changes. Link relevant issues or todo items so the change log stays traceable.

## Feature Flag Tips
Document new booleans under `hosts/default.nix` and default them in `lib/mkHome.nix`. When a flag gates packages, guard side effects with `lib.mkIf features.<flag>` to keep minimal profiles lean.
