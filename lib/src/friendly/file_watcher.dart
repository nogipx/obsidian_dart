import 'dart:async';

import '../obsidian/plugin_handle.dart';
import '../obsidian/types.dart';
import 'events.dart';
import 'file_handle.dart';
import 'file_metadata.dart';

/// Type of file change event
enum FileChangeType {
  /// File was created
  created,

  /// File was modified
  modified,

  /// File was deleted
  deleted,

  /// File was renamed/moved
  renamed,
}

/// File change event with rich metadata.
///
/// Contains the change type, enhanced file handle, and old path for renames.
class FileChangeEvent {
  const FileChangeEvent({
    required this.type,
    required this.file,
    this.oldPath,
  });

  /// Type of change (created, modified, deleted, renamed)
  final FileChangeType type;

  /// Enhanced file handle with metadata
  final FileHandle file;

  /// Old path (only for rename events)
  final String? oldPath;

  // Convenience getters
  bool get isCreated => type == FileChangeType.created;
  bool get isModified => type == FileChangeType.modified;
  bool get isDeleted => type == FileChangeType.deleted;
  bool get isRenamed => type == FileChangeType.renamed;

  @override
  String toString() => 'FileChangeEvent('
      'type: $type, '
      'path: ${file.path}'
      '${oldPath != null ? ', oldPath: $oldPath' : ''}'
      ')';
}

/// Builder for configuring file watching with filters.
///
/// Provides fluent API for filtering file events by:
/// - Path (exact, prefix, glob pattern)
/// - File properties (extension, size, type)
/// - Event types (create, modify, delete, rename)
///
/// Example:
/// ```dart
/// plugin.fileWatcher
///     .watch()
///     .pathPrefix('notes/daily/')
///     .markdownOnly()
///     .modifyOnly()
///     .start()
///     .listen((event) => print('Modified: ${event.file.path}'));
/// ```
class WatchBuilder {
  WatchBuilder._(this._watcher);

  final FileWatcher _watcher;
  final List<bool Function(String path)> _pathFilters = [];
  final List<bool Function(FileHandle file)> _fileFilters = [];
  bool _includeCreate = true;
  bool _includeModify = true;
  bool _includeDelete = true;
  bool _includeRename = true;

  // Path filters

  /// Match exact path
  void path(String exactPath) {
    _pathFilters.add((path) => path == exactPath);
  }

  /// Match paths starting with prefix
  void pathPrefix(String prefix) {
    _pathFilters.add((path) => path.startsWith(prefix));
  }

  /// Match paths using glob pattern.
  ///
  /// Supports basic wildcards:
  /// - `*` matches any characters within a path segment
  /// - `**` matches any characters across path segments
  /// - `?` matches a single character
  ///
  /// Examples:
  /// - `notes/*.md` - markdown files in notes folder
  /// - `notes/**/*.md` - markdown files in notes and subfolders
  /// - `DRAFT-*.md` - files starting with DRAFT-
  void glob(String pattern) {
    final regex = _globToRegex(pattern);
    _pathFilters.add(regex.hasMatch);
  }

  // File property filters

  /// Match files with specific extension (without dot)
  void extension(String ext) {
    _fileFilters
        .add((file) => file.extension.toLowerCase() == ext.toLowerCase());
  }

  /// Match only markdown files
  void markdownOnly() => extension('md');

  /// Match only image files
  void imagesOnly() {
    _fileFilters.add((file) => file.isImage);
  }

  /// Match files larger than specified size in bytes
  void minSize(int bytes) {
    _fileFilters.add((file) => (file.size ?? 0) >= bytes);
  }

  /// Match files smaller than specified size in bytes
  void maxSize(int bytes) {
    _fileFilters.add((file) => (file.size ?? 0) <= bytes);
  }

  /// Custom file filter predicate
  void where(bool Function(FileHandle file) predicate) {
    _fileFilters.add(predicate);
  }

  // Event type filters

  /// Exclude create events
  void excludeCreate() {
    _includeCreate = false;
  }

  /// Exclude modify events
  void excludeModify() {
    _includeModify = false;
  }

  /// Exclude delete events
  void excludeDelete() {
    _includeDelete = false;
  }

  /// Exclude rename events
  void excludeRename() {
    _includeRename = false;
  }

  /// Watch only modify events (exclude create, delete, rename)
  void modifyOnly() => this
    ..excludeCreate()
    ..excludeDelete()
    ..excludeRename();

  /// Watch only create events
  void createOnly() => this
    ..excludeModify()
    ..excludeDelete()
    ..excludeRename();

  /// Watch only delete events
  void deleteOnly() => this
    ..excludeCreate()
    ..excludeModify()
    ..excludeRename();

  /// Start watching and return event stream.
  ///
  /// The stream is a broadcast stream - multiple listeners are supported.
  Stream<FileChangeEvent> start() {
    return _watcher._createStream(
      pathFilters: _pathFilters,
      fileFilters: _fileFilters,
      includeCreate: _includeCreate,
      includeModify: _includeModify,
      includeDelete: _includeDelete,
      includeRename: _includeRename,
    );
  }

  Future<void> dispose() async {
    await _watcher._dispose();
  }

  /// Convert glob pattern to regex
  static RegExp _globToRegex(String pattern) {
    final regex = pattern
        .replaceAll('.', r'\.')
        .replaceAll('?', '.')
        .replaceAll('**/', '.*')
        .replaceAll('*', '[^/]*');

    return RegExp('^$regex\$');
  }
}

/// File watcher with path-specific filtering.
///
/// Extends [VaultEvents] with rich file metadata and powerful filtering.
///
/// Example:
/// ```dart
/// final watcher = FileWatcher(plugin);
///
/// // Watch specific file
/// watcher.watch()
///     .path('notes/daily/2025-02-12.md')
///     .start()
///     .listen((event) => print(event.type));
///
/// // Watch folder (markdown only, modify events)
/// watcher.watch()
///     .pathPrefix('projects/')
///     .markdownOnly()
///     .modifyOnly()
///     .start()
///     .listen((event) => print('Modified: ${event.file.path}'));
/// ```
class FileWatcher {
  FileWatcher(this._plugin);

  final PluginHandle _plugin;
  StreamController<FileChangeEvent>? _controller;

  /// Start building a watch configuration
  WatchBuilder asWatchBuilder() => WatchBuilder._(this);

  Future<void> _dispose() async {
    await _controller?.close();
  }

  /// Create filtered event stream
  Stream<FileChangeEvent> _createStream({
    required List<bool Function(String path)> pathFilters,
    required List<bool Function(FileHandle file)> fileFilters,
    required bool includeCreate,
    required bool includeModify,
    required bool includeDelete,
    required bool includeRename,
  }) {
    _controller ??= StreamController<FileChangeEvent>.broadcast();
    final controller = _controller;
    if (controller == null) {
      throw StateError('controller must be not null');
    }

    final events = VaultEvents(_plugin)..attach();

    // Helper to check if path passes all filters
    bool passesPathFilters(String path) {
      if (pathFilters.isEmpty) {
        return true;
      }
      return pathFilters.every((filter) => filter(path));
    }

    // Helper to check if file passes all filters
    bool passesFileFilters(FileHandle file) {
      if (fileFilters.isEmpty) {
        return true;
      }
      return fileFilters.every((filter) => filter(file));
    }

    // Helper to process event and emit if it passes filters
    Future<void> processEvent(
      VaultEvent event,
      FileChangeType type,
    ) async {
      // Quick path filter (before loading metadata)
      if (!passesPathFilters(event.file.path)) {
        return;
      }

      // Load enhanced file handle
      FileHandle fileHandle;
      try {
        if (event.file is TFileHandle) {
          fileHandle = await FileHandle.from(
            event.file as TFileHandle,
            _plugin.app.vault.adapter,
          );
        } else {
          // For deleted/renamed abstract files, create minimal metadata
          fileHandle = FileHandle(
            event.file.raw,
            FileMetadata.fromStatAndPath(
              event.file.path,
              event.file.name,
              null,
            ),
          );
        }
      } on Object catch (_) {
        // Skip if metadata loading fails
        return;
      }

      // File property filters
      if (!passesFileFilters(fileHandle)) {
        return;
      }

      // Emit event
      controller.add(
        FileChangeEvent(
          type: type,
          file: fileHandle,
          oldPath: event.oldPath,
        ),
      );
    }

    // Subscribe to vault events
    if (includeCreate) {
      events.created.listen((e) => processEvent(e, FileChangeType.created));
    }
    if (includeModify) {
      events.modified.listen((e) => processEvent(e, FileChangeType.modified));
    }
    if (includeDelete) {
      events.deleted.listen((e) => processEvent(e, FileChangeType.deleted));
    }
    if (includeRename) {
      events.renamed.listen((e) => processEvent(e, FileChangeType.renamed));
    }

    // Cleanup on stream cancel
    controller.onCancel = () async {
      await events.dispose();
    };

    return controller.stream;
  }
}

/// Extension to add fileWatcher to PluginHandle
extension PluginFileWatcherExtension on PluginHandle {
  /// File watcher with path-specific filtering
  FileWatcher get fileWatcher => FileWatcher(this);
}
