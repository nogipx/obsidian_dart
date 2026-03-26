# obsidian_dart

A Dart toolkit and runtime for building [Obsidian](https://obsidian.md) plugins without writing TypeScript. Write your plugin in Dart, compile to CommonJS, and drop it into `.obsidian/plugins/`.

---

Built as part of **[Rhyolite Sync](https://rhyolite.nogipx.dev)** — an end-to-end encrypted sync service for Obsidian. Your notes stay yours: encryption keys never leave your devices, and the server only ever sees ciphertext.

---

## Getting started

```bash
dart pub global activate obsidian_dart
```

Create your entry point at `bin/plugin_entry.dart`:

```dart
import 'package:obsidian_dart/obsidian_dart.dart';

void main() {
  bootstrapPlugin(
    onLoad: (plugin) async {
      plugin.addCommand(
        id: 'hello',
        name: 'Say hello from Dart',
        callback: () => showNotice('Hello from Dart!'),
      );
    },
    onUnload: (plugin) async {},
  );
}
```

Build and copy to your vault:

```bash
dart run obsidian_dart:obsidian_build --plugin-id my_plugin
dart run obsidian_dart:obsidian_manifest --plugin-id my_plugin
# copy build/plugin/my_plugin/ → <vault>/.obsidian/plugins/my_plugin/
```

## CLI reference

### `obsidian_build`

| Option | Default | Description |
|---|---|---|
| `--plugin-id` | _(required)_ | Obsidian plugin ID |
| `--entry` | `bin/plugin_entry.dart` | Dart entry file |
| `--out` | `build/plugin/<id>` | Output directory |
| `--plugin-class` | `DartPlugin` | JS class name |
| `--release` | `false` | Release optimisations |
| `--fvm` | `false` | Use FVM-managed Dart |

### `obsidian_manifest`

| Option | Default | Description |
|---|---|---|
| `--plugin-id` | _(required)_ | Obsidian plugin ID |
| `--out` | `build/plugin/<id>` | Output directory |

## Supported Obsidian API

### Plugin & App

| Class | What's covered |
|---|---|
| `PluginHandle` | `addCommand`, `addRibbonIcon`, `addStatusBarItem`, `addSettingTab`, `registerEvent`, `saveData`, `loadData` |
| `AppHandle` | `vault`, `workspace`, `metadataCache`, `secretStorage`, `keymap` |

### Vault & File System

| Class | What's covered |
|---|---|
| `VaultHandle` | `getRoot`, `getFileByPath`, `getFolderByPath`, `getMarkdownFiles`, `getFiles`, `getAllLoadedFiles`, `read`, `cachedRead`, `readBinary`, `create`, `createBinary`, `createFolder`, `modify`, `modifyBinary`, `append`, `process`, `delete`, `trash`, `rename`, `copy`, `on`, `offref` |
| `AdapterHandle` | `read`, `readBinary`, `write`, `writeBinary`, `append`, `process`, `exists`, `stat`, `list`, `mkdir`, `rmdir`, `remove`, `rename`, `copy`, `trashSystem`, `trashLocal`, `getResourcePath` |
| `TFileHandle` / `TFolderHandle` | `path`, `name`, `parent`, `stat`, `basename`, `extension`, `children`, `isRoot` |

### Workspace

| Class | What's covered |
|---|---|
| `WorkspaceHandle` | `getActiveFile`, `openFile`, `on` |
| `MetadataCacheHandle` | `getFileCache`, `getCache`, `on` |

### Settings UI

| Class | What's covered |
|---|---|
| `SettingHandle` | `setName`, `setDesc`, `addText`, `addToggle`, `addDropdown`, `addButton` |
| `TextComponentHandle` | `setValue`, `setPlaceholder`, `onChange` |
| `ToggleComponentHandle` | `setValue`, `onChange` |
| `DropdownComponentHandle` | `addOption`, `addOptions`, `setValue`, `onChange` |
| `ButtonComponentHandle` | `setButtonText`, `setCta`, `onClick` |

### Modals & UI

| Class | What's covered |
|---|---|
| `ModalContext` | `createEl`, `h3`, `row`, `column`, `input`, `toggle`, `button`, `buttonRow`, `spinner`, `showError`, `onEnter`, `onEscape`, `close` |
| Utilities | `showNotice`, `showModal`, `showTextPrompt`, `showPasswordPrompt`, `log` |

### Secret Storage (Obsidian 1.11.4+)

| Class | What's covered |
|---|---|
| `SecretStorageHandle` | `getSecret`, `setSecret`, `deleteSecret`, `listSecrets` |

### Dart-friendly abstractions (on top of bindings)

| Class | Description |
|---|---|
| `VaultEvents` / `WorkspaceEvents` | Stream-based vault and workspace events |
| `FileHandle` | `TFileHandle` extended with size, dates, type detection (`isMarkdown`, `isImage`, …) |
| `FileWatcher` | Watch files/folders with path, glob, size, and event-type filters |
| `SettingsManager<T>` | Type-safe generic settings with `Stream`-based change notifications |
| `SettingsBuilder<T>` | Declarative settings UI with automatic persistence |
| `PluginSettingsTab` | Fluent settings tab builder |
| `BatchFileOperations` | Transactional bulk file ops with rollback and progress callbacks |

## Requirements

- Dart SDK `>=3.1.0`
- Obsidian 1.7.0+

## License

MIT — see [LICENSE](LICENSE).
