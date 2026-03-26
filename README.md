# obsidian_dart

[![pub package](https://img.shields.io/pub/v/obsidian_dart.svg)](https://pub.dev/packages/obsidian_dart)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A Dart toolkit and runtime for building [Obsidian](https://obsidian.md) plugins without writing TypeScript. Write your plugin in Dart, compile to CommonJS, and drop it into `.obsidian/plugins/`.

## Features

- **Full Dart** — write plugins using Dart's type system and ecosystem
- **Build tooling** — `obsidian_build` compiles Dart to a CommonJS bundle, `obsidian_manifest` generates `manifest.json`
- **Obsidian API bindings** — `PluginHandle`, `AppHandle`, `VaultHandle`, `WorkspaceHandle`, and more
- **Friendly abstractions** — Stream-based events, type-safe settings, file watcher with glob filtering, batch operations
- **Three-level API** — pick the abstraction level that fits your needs

## Getting started

Add `obsidian_dart` to your plugin project:

```yaml
dependencies:
  obsidian_dart: ^0.1.0
```

Install CLI tools globally for convenience:

```bash
dart pub global activate obsidian_dart
```

Or run directly from your project:

```bash
dart pub get
dart run obsidian_dart:obsidian_build --plugin-id my_plugin
dart run obsidian_dart:obsidian_manifest --plugin-id my_plugin
```

### Minimal plugin entry point

Create `bin/plugin_entry.dart`:

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
# Then copy build/plugin/my_plugin/ to <vault>/.obsidian/plugins/my_plugin/
```

## Usage

### Settings API

Three levels of abstraction — choose what fits your needs.

#### Level 1: Type-safe storage

```dart
class MySettings {
  const MySettings({required this.enabled, required this.apiKey});
  final bool enabled;
  final String apiKey;

  factory MySettings.fromJson(Map<String, dynamic> json) => MySettings(
    enabled: json['enabled'] as bool? ?? false,
    apiKey: json['apiKey'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {'enabled': enabled, 'apiKey': apiKey};

  MySettings copyWith({bool? enabled, String? apiKey}) => MySettings(
    enabled: enabled ?? this.enabled,
    apiKey: apiKey ?? this.apiKey,
  );
}

final manager = SettingsManager<MySettings>(
  plugin: plugin,
  fromJson: MySettings.fromJson,
  toJson: (s) => s.toJson(),
  defaultSettings: const MySettings(enabled: false, apiKey: ''),
);

final settings = await manager.get();
await manager.save(settings.copyWith(enabled: true));

// React to changes
manager.changes.listen((s) => print('enabled: ${s.enabled}'));
```

#### Level 2: Fluent settings tab

```dart
PluginSettingsTab(plugin)
  ..addSection('General')
  ..addToggle(
    name: 'Enable feature',
    description: 'Turn on this feature',
    initialValue: true,
    onChange: (value) async => manager.save(settings.copyWith(enabled: value)),
  )
  ..addText(
    name: 'API Key',
    description: 'Your API key',
    initialValue: '',
    placeholder: 'Enter key...',
    onChange: (value) async => manager.save(settings.copyWith(apiKey: value)),
  )
  ..show();
```

#### Level 3: Declarative builder (recommended)

```dart
await SettingsBuilder(plugin: plugin, manager: manager).build((ctx) {
  ctx.section('General');

  ctx.toggle(
    name: 'Enable feature',
    description: 'Turn on this feature',
    getValue: (s) => s.enabled,
    setValue: (s, v) => s.copyWith(enabled: v),
  );

  ctx.text(
    name: 'API Key',
    description: 'Your API key',
    placeholder: 'Enter key...',
    getValue: (s) => s.apiKey,
    setValue: (s, v) => s.copyWith(apiKey: v),
  );
});
```

---

### File & Vault API

#### Level 1: Enhanced file handles with metadata

```dart
final files = vault.getMarkdownFiles();
final enhanced = await FileHandle.fromList(files, vault.adapter);

for (final file in enhanced) {
  print('${file.name}: ${file.size} bytes, modified: ${file.modifiedTime}');
  print('  isMarkdown: ${file.isMarkdown}, isImage: ${file.isImage}');
}

// Fully backward-compatible — FileHandle extends TFileHandle
await vault.read(enhanced.first);
```

#### Level 2: File watcher with filtering

```dart
// Watch a folder for markdown changes
plugin.fileWatcher
    .watch()
    .pathPrefix('projects/')
    .markdownOnly()
    .modifyOnly()
    .start()
    .listen((event) {
      print('Modified: ${event.file.path} (${event.file.size} bytes)');
    });

// Watch by glob pattern
plugin.fileWatcher
    .watch()
    .glob('notes/**/DRAFT-*.md')
    .start()
    .listen((event) {
      print('Draft ${event.type}: ${event.file.path}');
    });
```

#### Level 3: Batch operations with transactions

```dart
final result = await vault.batch.transaction()
    .create('notes/new1.md', '# Note 1')
    .create('notes/new2.md', '# Note 2')
    .modify(existingFile, '# Updated content')
    .rename(oldFile, 'notes/renamed.md')
    .delete(tempFile)
    .commit(
      onProgress: (op, current, total) => print('[$current/$total] ${op.description}'),
    );

if (result.allSucceeded) {
  print('All ${result.successCount} operations succeeded');
} else {
  print('${result.failureCount} failed: ${result.errors}');
}

// Bulk operations (no rollback)
await vault.batch.copyFiles(files, 'archive/2025-02');
await vault.batch.renameWithPattern(files, (name) => name.replaceAll('DRAFT-', 'FINAL-'));
await vault.batch.deleteFiles(oldFiles);
```

---

### Stream-based events

```dart
final vaultEvents = VaultEvents(plugin);
vaultEvents.modified.listen((file) => print('Modified: ${file.path}'));
vaultEvents.created.listen((file) => print('Created: ${file.path}'));

final workspaceEvents = WorkspaceEvents(plugin);
workspaceEvents.fileOpen.listen((file) => print('Opened: ${file?.path}'));
```

---

### CLI reference

#### `obsidian_build`

Compiles a Dart entry point to a CommonJS `main.js` bundle.

| Option | Default | Description |
|---|---|---|
| `--plugin-id` | _(required)_ | Obsidian plugin ID |
| `--entry` | `bin/plugin_entry.dart` | Dart entry file |
| `--out` | `build/plugin/<id>` | Output directory |
| `--plugin-class` | `DartPlugin` | JS class name |
| `--release` | `false` | Enable release optimisations |
| `--fvm` | `false` | Use FVM-managed Dart |
| `--dart-bin` | _(auto)_ | Path to `dart` binary |

#### `obsidian_manifest`

Generates `manifest.json` from `pubspec.yaml`.

| Option | Default | Description |
|---|---|---|
| `--plugin-id` | _(required)_ | Obsidian plugin ID |
| `--out` | `build/plugin/<id>` | Output directory |

## Requirements

- Dart SDK `>=3.1.0`
- Obsidian 1.7.0+

## License

MIT — see [LICENSE](LICENSE).
