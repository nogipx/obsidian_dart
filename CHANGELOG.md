# Changelog

## 0.1.1

- Updated README: added Rhyolite Sync mention.

## 0.1.0

- Initial release.
- `bootstrapPlugin()` runtime for registering Dart plugin lifecycle hooks.
- Low-level Obsidian API bindings: `PluginHandle`, `AppHandle`, `VaultHandle`, `WorkspaceHandle`, `MetadataCacheHandle`, `SecretStorageHandle`, settings and UI helpers.
- Friendly abstractions: `VaultEvents`, `WorkspaceEvents`, `FileHandle`, `FileWatcher`, `SettingsManager`, `SettingsBuilder`, `PluginSettingsTab`, `BatchFileOperations`.
- CLI tools: `obsidian_build` (Dart → CommonJS) and `obsidian_manifest` (generate `manifest.json`).
