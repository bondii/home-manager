# Repository Guidelines

## Project Structure & Module Organization
This flake centralizes Home Manager configs. `flake.nix` exposes `homeConfigurations`, while `lib/mkHome.nix` merges base modules with feature flags (`gui`, `dev`, `nixvim`, `fonts`, `stylix`, `vscode`, `laptop`). Host presets live in `hosts/`; keep host-specific overrides there or in a new attrset. Shared logic belongs in `modules/core/`, optional toggles in `modules/features/`, and tool-specific plumbing in `modules/programs/` (git, zsh, nvim, etc.). Place new reusable modules in the matching folder and register them in `lib/mkHome.nix` when they should be part of the default stack.

## Build, Test, and Development Commands
- `nix flake show` — inventory of standard outputs; use `nix eval .#homeConfigurations --apply builtins.attrNames` for profile names.
- `nix build .#homeConfigurations.pontus.activationPackage` — ensure the main profile builds without switching.
- `home-manager switch --flake .#pontus@arch-desktop` — apply the graphical profile locally; add `--dry-run` when validating.
- `home-manager switch --flake .#pontus@ssh-minimal --dry-run` — sanity-check the headless profile from any machine.

## Coding Style & Naming Conventions
Use two-space indentation and trailing semicolons for attrsets, mirroring the existing Nix files. Prefer lowercase `camelCase` for option names (`features.gui`) and hyphen-free Nix module names (`programs/git.nix`). Format with `nix fmt` (pinned `nixfmt`). Use `nix develop` for `statix check .`, `deadnix --fail .`, ShellCheck, and Python. Keep modules focused: one concern per file, merging through `lib.mkMerge` only when necessary.

## Testing Guidelines
Run `nix flake check --no-update-lock-file` before pushing; explicit checks build both distinct activation packages and the focused regression checks. `--no-build` evaluates them without building. CI evaluates all checks and builds only lightweight checks. Add meaningful option-boundary assertions to `tests/features.nix`. Do not run a full activation as a test: custom hook dry runs use an isolated harness. Switching, real locking/suspend tests, and administrator installation are explicit rollout actions; build success is not proof of those interactive behaviors. Suspend attempts a pixelated screenshot within a two-second preparation deadline, then uses solid black on failure; manual and idle locking retain pixelated screenshots with solid fallback.

## Commit & Pull Request Guidelines
Write imperative, scope-first summaries (`Add Nix LSP`, `Fix Stylix theme regression`) matching recent history. Each commit should leave `nix flake check` passing. For PRs, explain which hosts/features changed, note any new module flags, and include output snippets from `nix build` or `home-manager switch --dry-run` when behavior changes. Link relevant issues or todo items so the change log stays traceable.

## Feature Flag Tips
Default optional booleans to false in `modules/core/options.nix` and set existing host choices explicitly. `mkHome.features` supplies `mkDefault` values; module overrides take precedence. Import definitions statically and guard behavior with `lib.mkIf config.pontus.features.<flag>`. Never use the legacy raw `features` special argument for behavior or make imports depend on evaluated config. Keep graphical development apps behind both `gui` and `dev`; keep system administration outside Home Manager activation.
