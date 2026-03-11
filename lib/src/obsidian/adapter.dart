import 'dart:js_interop';
// ignore_for_file: deprecated_member_use
import 'dart:js_util' as jsu;
import 'dart:typed_data';

import 'types.dart';

/// Low-level adapter for file system operations.
///
/// Corresponds to Obsidian API `DataAdapter`.
class AdapterHandle {
  AdapterHandle(this.raw);

  final JSObject raw;

  /// Get the name of the adapter
  String getName() => jsu.callMethod<String>(raw, 'getName', []);

  // ===== Reading =====

  /// Read file as text
  Future<String> read(String path) => jsu.promiseToFuture<String>(
    jsu.callMethod<Object?>(raw, 'read', [path])!,
  );

  /// Read file as binary (ArrayBuffer -> Uint8List)
  Future<Uint8List> readBinary(String path) async {
    // Obsidian returns ArrayBuffer, we need to convert to Uint8List
    final arrayBuffer = await jsu.promiseToFuture<JSObject>(
      jsu.callMethod<Object?>(raw, 'readBinary', [path])!,
    );

    // Create Uint8Array view over ArrayBuffer (TypedArray, not JSArray)
    final uint8Array = jsu.callConstructor<JSObject>(
      jsu.getProperty<JSObject>(jsu.globalThis, 'Uint8Array'),
      [arrayBuffer],
    );

    // dartify converts JS TypedArray → Dart Uint8List
    final result = jsu.dartify(uint8Array);
    if (result is Uint8List) return result;

    // Fallback: manual byte-by-byte copy
    final length = jsu.getProperty<int>(uint8Array, 'length');
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = jsu.getProperty<int>(uint8Array, '$i');
    }
    return bytes;
  }

  // ===== Writing =====

  /// Write text to file
  Future<void> write(
    String path,
    String data, [
    DataWriteOptions? options,
  ]) async {
    final args = options != null ? [path, data, options.toJS()] : [path, data];
    await jsu.promiseToFuture<void>(
      jsu.callMethod<Object?>(raw, 'write', args)!,
    );
  }

  /// Write binary data to file
  Future<void> writeBinary(
    String path,
    Uint8List bytes, [
    DataWriteOptions? options,
  ]) async {
    // Convert Uint8List to ArrayBuffer (required by Obsidian API)
    // Create Uint8Array from JSArray, then extract its buffer
    final jsUint8Array = jsu.callConstructor<JSObject>(
      jsu.getProperty<JSObject>(jsu.globalThis, 'Uint8Array'),
      [bytes.toJS], // Pass as JSArray
    );
    final arrayBuffer = jsu.getProperty<JSObject>(jsUint8Array, 'buffer');

    final args = options != null ? [path, arrayBuffer, options.toJS()] : [path, arrayBuffer];
    await jsu.promiseToFuture<void>(
      jsu.callMethod<Object?>(raw, 'writeBinary', args)!,
    );
  }

  /// Append text to file
  Future<void> append(
    String path,
    String data, [
    DataWriteOptions? options,
  ]) async {
    final args = options != null ? [path, data, options.toJS()] : [path, data];
    await jsu.promiseToFuture<void>(
      jsu.callMethod<Object?>(raw, 'append', args)!,
    );
  }

  /// Atomically read, modify, and write file content
  ///
  /// Returns the new file content.
  Future<String> process(
    String path,
    String Function(String data) fn, [
    DataWriteOptions? options,
  ]) async {
    final jsFn = jsu.allowInterop(fn);
    final args = options != null ? [path, jsFn, options.toJS()] : [path, jsFn];
    return jsu.promiseToFuture<String>(
      jsu.callMethod<Object?>(raw, 'process', args)!,
    );
  }

  // ===== File System Operations =====

  /// Check if file/folder exists
  ///
  /// Set `sensitive` to true for case-sensitive check.
  Future<bool> exists(String path, [bool sensitive = false]) async {
    return jsu.promiseToFuture<bool>(
      jsu.callMethod<Object?>(raw, 'exists', [path, sensitive])!,
    );
  }

  /// Get file/folder statistics
  Future<StatHandle?> stat(String path) async {
    final res = await jsu.promiseToFuture<JSObject?>(
      jsu.callMethod<Object?>(raw, 'stat', [path])!,
    );
    return res == null ? null : StatHandle(res);
  }

  /// List files and folders in a directory
  Future<ListedFilesHandle> list(String path) async {
    final res = await jsu.promiseToFuture<JSObject>(
      jsu.callMethod<Object?>(raw, 'list', [path])!,
    );
    final files = jsu.getProperty<JSArray>(res, 'files').toDart.cast<String>();
    final folders = jsu.getProperty<JSArray>(res, 'folders').toDart.cast<String>();
    return ListedFilesHandle(files: List.of(files), folders: List.of(folders));
  }

  /// Get resource path for a file
  String getResourcePath(String path) => jsu.callMethod<String>(raw, 'getResourcePath', [path]);

  // ===== Directory Operations =====

  /// Create a directory
  Future<void> mkdir(String path) => jsu.promiseToFuture<void>(
    jsu.callMethod<Object?>(raw, 'mkdir', [path])!,
  );

  /// Remove a directory
  ///
  /// Set `recursive` to true to remove non-empty directories.
  Future<void> rmdir(String path, {bool recursive = false}) async {
    await jsu.promiseToFuture<void>(
      jsu.callMethod<Object?>(raw, 'rmdir', [path, recursive])!,
    );
  }

  /// Remove a file
  Future<void> remove(String path) => jsu.promiseToFuture<void>(
    jsu.callMethod<Object?>(raw, 'remove', [path])!,
  );

  // ===== Trash Operations =====

  /// Move to system trash
  ///
  /// Returns true if successful.
  Future<bool> trashSystem(String path) => jsu.promiseToFuture<bool>(
    jsu.callMethod<Object?>(raw, 'trashSystem', [path])!,
  );

  /// Move to local .trash folder
  Future<void> trashLocal(String path) => jsu.promiseToFuture<void>(
    jsu.callMethod<Object?>(raw, 'trashLocal', [path])!,
  );

  // ===== File Operations =====

  /// Rename/move a file or folder
  Future<void> rename(String from, String to) => jsu.promiseToFuture<void>(
    jsu.callMethod<Object?>(raw, 'rename', [from, to])!,
  );

  /// Copy a file or folder
  Future<void> copy(String from, String to) => jsu.promiseToFuture<void>(
    jsu.callMethod<Object?>(raw, 'copy', [from, to])!,
  );
}

/// Result of listing directory contents.
///
/// Corresponds to Obsidian API `ListedFiles`.
class ListedFilesHandle {
  ListedFilesHandle({required this.files, required this.folders});

  final List<String> files;
  final List<String> folders;
}

/// File/folder statistics.
///
/// Corresponds to Obsidian API `Stat`.
class StatHandle {
  StatHandle(this.raw);

  final JSObject raw;

  /// Type: 'file' or 'folder'
  String get type => jsu.getProperty<String>(raw, 'type');

  /// Creation time (Unix timestamp)
  ///
  /// NOTE: According to Obsidian API docs, Stat uses unix timestamp (likely seconds),
  /// while FileStats uses milliseconds. Verify in practice!
  int get ctime => jsu.getProperty<int>(raw, 'ctime');

  /// Modification time (Unix timestamp)
  ///
  /// NOTE: According to Obsidian API docs, Stat uses unix timestamp (likely seconds),
  /// while FileStats uses milliseconds. Verify in practice!
  int get mtime => jsu.getProperty<int>(raw, 'mtime');

  /// File size in bytes (null for folders)
  int? get size => jsu.getProperty<int?>(raw, 'size');

  /// Convenience getter: check if this is a file
  bool get isFile => type == 'file';

  /// Convenience getter: check if this is a folder
  bool get isFolder => type == 'folder';
}
