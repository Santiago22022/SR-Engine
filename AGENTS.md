# Repository Guidelines

## Project Structure & Module Organization
- Source code: `source/` (states, editors, backend, utils).
- Assets: `assets/preload/` (game data, images, sounds). Example mods in `example_mods/` are mapped to `mods/` at runtime via `Project.xml`.
- Configuration: `Project.xml`, `hmm.json`, `hxformat.json`.
- Setup scripts: `setup/windows.bat`, `setup/windows-msvc.bat`, `setup/unix.sh`.

## Build, Test, and Development Commands
- First-time setup: `haxelib setup` then run the appropriate script in `setup/`.
- Build and run locally: `lime test windows -debug` (or `linux`, `mac`, `html5`).
- Clean rebuild: `lime test cpp -clean` (or delete `export/obj`).
- Haxe version: use 4.2.5+ (see `UPDATE HAXE TO 4.3.7.txt` for recommended version).

## Coding Style & Naming Conventions
- Haxe style with 4-space indentation; keep files UTF-8, no trailing whitespace.
- Classes: PascalCase (file name matches class, e.g., `source/PlayState.hx`).
- Methods/fields: lowerCamelCase; constants: UPPER_SNAKE_CASE.
- Formatter: `haxelib run formatter -s source` (uses `hxformat.json`).

## Testing Guidelines
- No formal unit tests. Perform manual QA by running a debug build and exercising:
  - Boot flow (Title → Menus → Play), editors (press `7` for Chart Editor), and mod loading from `mods/`.
  - Verify assets load without errors; watch console output for traces and exceptions.
- Include test songs/assets under `mods/` rather than altering `assets/preload/` when possible.

## Commit & Pull Request Guidelines
- Write small, descriptive commits. Recommended prefixes: `feat:`, `fix:`, `refactor:`, `perf:`, `chore:`.
- Branch naming: `feat/<topic>`, `fix/<issue-id>`, `docs/<area>`.
- PRs must include: summary, rationale, affected areas, platform(s) tested, screenshots for UI changes, and links to related issues.
- Ensure `lime test <platform>` succeeds and code is formatted before requesting review.

## Security & Configuration Tips
- Prefer toggling features in `Project.xml` (e.g., remove or comment `VIDEOS_ALLOWED`, `LUA_ALLOWED`) over ad-hoc flags.
- Avoid committing large, unused binaries; keep build outputs like `export/` out of VCS.
- Place user content in `mods/`; do not write to `source/` at runtime.

