# Changelog

## 0.2.1

### Fixes

- A plugin instance now binds to the Dart hooks published by its OWN evaluation
  of the bundle. The generated JS wrapper read `globalThis._dartObsidianPlugin`
  on every call, and reloading a plugin re-evaluates the bundle — so by the time
  the outgoing instance was told to unload, the slot already pointed at the
  incoming one. The outgoing instance ran the INCOMING instance's `onUnload`,
  gutting the plugin that had just started, while its own settings tab, status
  bar items and listeners were never released. Each reload leaked one instance's
  UI and left the live one broken, so every attempt to fix it by toggling the
  plugin added another orphan. The wrapper now captures the hooks once at
  module scope, in the same synchronous turn that published them.
- The injected stylesheet is scoped per plugin id instead of one shared
  `obsidian-dart-styles` element. Two obsidian_dart plugins in one vault used to
  collide: the second one's `extraCss` was never injected because the element
  already existed, and whichever unloaded first took the stylesheet away from
  the other. A reload had the same problem against itself — the outgoing
  instance's removal ran after the incoming instance's injection, leaving the
  running plugin unstyled.

## 0.2.0

### Breaking changes

- Removed `showPasswordPrompt()` and `showTextPrompt()` — project-specific helpers, not general-purpose.
- Removed `style:` parameter from `ModalContext.createEl()` and `LayoutContext.createEl()` — use `cls:` with CSS classes instead.

### New

- `PluginSettingsTab.addGroup()` — groups multiple settings into one visual card using Obsidian's native `.card` class.
- `SettingHandle.setHeading()` — marks a setting as a section heading (replaces raw `h2` elements).
- `bootstrapPlugin()` now accepts `extraCss` — inject plugin-specific CSS alongside the library's base styles.
- `ModalContext.showError()` now renders an Obsidian native `danger` callout block instead of a plain paragraph.

### Fixes

- Removed `innerHTML` usage in `StatusItem.setIcon()` — XSS risk with user input.
- Replaced inline JS styles with CSS classes (`obsidian-dart-*`) injected via `bootstrapPlugin`.
- Settings section headers now use `Setting.setHeading()` instead of raw `h2` elements.
- Renamed internal CSS class `rhyolite-modal-error` → `obsidian-dart-modal-error`.
- Library base styles are now injected into `document.head` on plugin load and removed on unload — no `styles.css` file needed.

## 0.1.2

- Update readme

## 0.1.1

- Updated README: added Rhyolite Sync mention.

## 0.1.0

- Initial release.
- `bootstrapPlugin()` runtime for registering Dart plugin lifecycle hooks.
- Low-level Obsidian API bindings: `PluginHandle`, `AppHandle`, `VaultHandle`, `WorkspaceHandle`, `MetadataCacheHandle`, `SecretStorageHandle`, settings and UI helpers.
- Friendly abstractions: `VaultEvents`, `WorkspaceEvents`, `FileHandle`, `FileWatcher`, `SettingsManager`, `SettingsBuilder`, `PluginSettingsTab`, `BatchFileOperations`.
- CLI tools: `obsidian_build` (Dart → CommonJS) and `obsidian_manifest` (generate `manifest.json`).
