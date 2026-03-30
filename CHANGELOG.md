# Changelog

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
