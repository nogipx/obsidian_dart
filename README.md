# obsidian_dart

Single-package Dart starter for building Obsidian plugins without writing TypeScript. It exposes a tiny runtime (`bootstrapPlugin`) and minimal bindings (`PluginHandle`, `App/Vault/Workspace/FileManager` helpers, `showNotice`, `showModal`), then compiles to a CommonJS-friendly bundle you can drop into `.obsidian/plugins/<id>`.

## Quick start

```bash
# From repo root
cd packages/obsidian_dart
dart pub get
# Build JS bundle
dart run obsidian_dart:obsidian_build --plugin-id dart_obsidian
# Generate manifest separately
dart run obsidian_dart:obsidian_manifest --plugin-id dart_obsidian
# use fvm if you prefer:
# fvm dart run obsidian_dart:obsidian_build --plugin-id dart_obsidian
# fvm dart run obsidian_dart:obsidian_manifest --plugin-id dart_obsidian
# custom entrypoint:
# dart run obsidian_dart:obsidian_build --entry path/to/your_entry.dart --plugin-id my_plugin
```

The build command compiles `bin/plugin_entry.dart` to JS and writes a slim wrapper `main.js` into `build/plugin/<plugin-id>/`. Generate the `manifest.json` separately with `tool/build_manifest.dart`. Copy that folder into your vault: `<vault>/.obsidian/plugins/<plugin-id>/`.

After restarting Obsidian, you should see a status-bar pill "Dart plugin ready", a ribbon icon, and a command "Say hello from Dart".

## Customizing

- Edit `lib/plugin.dart` to add commands, ribbon items, status text, или использовать события/стримы.
- `lib/obsidian.dart` — низкоуровневые биндинги (Vault/Workspace/FileManager/Notice/Modal).
- `lib/obsidian_friendly.dart` — более идиоматичные обёртки: `VaultEvents`/`WorkspaceEvents` как `Stream`, мини DSL для команд.
- Re-run the install command to rebuild and copy the updated bundle.

## Settings API

obsidian_dart provides a three-level Settings API for managing plugin settings with type-safety and reactivity.

### Level 1: Type-Safe Storage

Create a generic `SettingsManager<T>` for automatic JSON persistence and reactive updates:

```dart
// Define your settings model
@immutable
class MySettings {
  const MySettings({required this.enabled, required this.apiKey});
  final bool enabled;
  final String apiKey;

  factory MySettings.fromJson(Map<String, dynamic> json) => MySettings(
    enabled: json['enabled'] as bool? ?? false,
    apiKey: json['apiKey'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'apiKey': apiKey,
  };

  MySettings copyWith({bool? enabled, String? apiKey}) => MySettings(
    enabled: enabled ?? this.enabled,
    apiKey: apiKey ?? this.apiKey,
  );
}

// Create manager
final manager = SettingsManager<MySettings>(
  plugin: plugin,
  fromJson: MySettings.fromJson,
  toJson: (s) => s.toJson(),
  defaultSettings: MySettings(enabled: false, apiKey: ''),
);

// Load/save
final settings = await manager.get();
await manager.save(settings.copyWith(enabled: true));

// React to changes
manager.changes.listen((newSettings) {
  print('Settings changed: ${newSettings.enabled}');
});
```

### Level 2: Fluent Settings Tab Builder

Build settings UI using Flutter-style method chaining:

```dart
PluginSettingsTab(plugin)
  ..addSection('General')
  ..addToggle(
    name: 'Enable feature',
    description: 'Turn on this feature',
    initialValue: true,
    onChange: (value) async {
      await manager.save(settings.copyWith(enabled: value));
    },
  )
  ..addText(
    name: 'API Key',
    description: 'Your API key',
    initialValue: '',
    placeholder: 'Enter key...',
    onChange: (value) async {
      await manager.save(settings.copyWith(apiKey: value));
    },
  )
  ..show();
```

### Level 3: Declarative Builder (Recommended)

Automatic persistence with declarative configuration:

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

  ctx.dropdown(
    name: 'Theme',
    description: 'Choose theme',
    options: {'auto': 'Auto', 'light': 'Light', 'dark': 'Dark'},
    getValue: (s) => s.theme,
    setValue: (s, v) => s.copyWith(theme: v),
  );

  ctx.button(
    name: 'Reset',
    description: 'Reset to defaults',
    buttonText: 'Reset to Defaults',
    onClick: (current) async {
      await manager.save(MySettings.defaults());
    },
  );
});
```

### Features

- **Type-safe** - Compile-time checking with generic `SettingsManager<T>`
- **Reactive** - Stream-based updates via `manager.changes`
- **Automatic persistence** - Changes save automatically with `SettingsBuilder`
- **Flutter-style** - Familiar fluent API for Flutter developers
- **Three levels** - Choose the level of abstraction that fits your needs

See [example/settings_example](example/settings_example) for a complete working example.

## File and Vault API

obsidian_dart provides a three-level File API for working with files and folders in your vault with rich metadata, filtering, and batch operations.

### Level 1: Enhanced Handles with Metadata

Get rich file metadata (size, dates, extension, type detection) without breaking existing APIs:

```dart
final files = vault.getMarkdownFiles();
final enhanced = await FileHandle.fromList(files, vault.adapter);

for (final file in enhanced) {
  print('${file.name}:');
  print('  Size: ${file.size} bytes');
  print('  Extension: ${file.extension}');
  print('  Modified: ${file.modifiedTime}');
  print('  Is markdown: ${file.isMarkdown}');
  print('  Is image: ${file.isImage}');
  print('  Basename: ${file.basename}');
  print('  Parent: ${file.parent}');
}

// FileHandle extends TFileHandle - fully compatible
await vault.read(enhanced.first); // Works!
```

**Features:**
- File metadata: size, creation/modification dates, extension
- Type detection: `isMarkdown`, `isImage`, `isPdf`, `isJson`, `isYaml`
- Path utilities: `basename`, `parent`
- Graceful fallback if stat fails
- Backward compatible - extends existing handles

### Level 2: File Watcher (Targeted Streams)

Watch specific files or folders with powerful filtering instead of global vault events:

```dart
// Watch specific file
plugin.fileWatcher
    .watch()
    .path('notes/daily/2025-02-12.md')
    .start()
    .listen((event) {
      print('${event.type}: ${event.file.path}');
    });

// Watch folder (markdown only, modify events)
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

// Custom filters
plugin.fileWatcher
    .watch()
    .where((file) => file.size! > 1024 * 100) // > 100KB
    .imagesOnly()
    .excludeDelete()
    .start()
    .listen((event) {
      print('Large image changed: ${event.file.path}');
    });
```

**Features:**
- Path filters: exact path, prefix, glob patterns (`*`, `**`, `?`)
- File filters: extension, size, custom predicates
- Event type filters: create, modify, delete, rename
- Shortcuts: `markdownOnly()`, `imagesOnly()`, `modifyOnly()`, etc.
- Enhanced events with file metadata

### Level 3: Batch Operations with Transactions

Execute multiple file operations with automatic rollback on failure:

```dart
// Transaction with rollback
final result = await vault.batch.transaction()
    .create('notes/new1.md', '# Note 1')
    .create('notes/new2.md', '# Note 2')
    .modify(existingFile, '# Updated content')
    .rename(oldFile, 'notes/renamed.md')
    .delete(tempFile)
    .commit();

if (result.allSucceeded) {
  print('All ${result.successCount} operations succeeded');
} else {
  print('${result.failureCount} operations failed');
  for (final entry in result.errors.entries) {
    print('Failed: ${entry.key.description}');
    print('Error: ${entry.value}');
  }
}

// Progress tracking
await vault.batch.transaction()
    .create('notes/1.md', '# 1')
    .create('notes/2.md', '# 2')
    .create('notes/3.md', '# 3')
    .commit(
      onProgress: (op, current, total) {
        print('[$current/$total] ${op.description}');
      },
    );

// Bulk operations (no rollback)
final copyResult = await vault.batch.copyFiles(
  filesToCopy,
  'archive/2025-02',
);

final renameResult = await vault.batch.renameWithPattern(
  files,
  (name) => name.replaceAll('DRAFT-', 'FINAL-'),
);

final deleteResult = await vault.batch.deleteFiles(oldFiles);
```

**Features:**
- Transactional operations with automatic rollback on failure
- Bulk operations: copy, move, delete, rename with pattern
- Progress callbacks
- Detailed results with succeeded/failed items and errors
- Continue on error mode (optional)

### Migration Path

No breaking changes - adopt incrementally:

```dart
// OLD (still works)
final files = vault.getMarkdownFiles();
final content = await vault.read(files.first);

// NEW (enhanced)
final enhanced = await FileHandle.fromList(files, vault.adapter);
print('Size: ${enhanced.first.size}'); // Rich metadata
final content = await vault.read(enhanced.first); // Still compatible!
```

## Notes

- Output stays CommonJS-friendly for Obsidian 1.7+.
- Only a small surface of the Obsidian API is wrapped right now. Add more helpers to `obsidian.dart` as you grow.
