import 'dart:js_interop';
// ignore_for_file: deprecated_member_use
import 'dart:js_util' as jsu;
import 'dart:typed_data';

import 'adapter.dart';
import 'types.dart';

/// Vault interface for interacting with files and folders.
///
/// Corresponds to Obsidian API `Vault`.
class VaultHandle {
  VaultHandle(this._vault);

  final JSObject _vault;

  /// Data adapter for low-level file operations
  AdapterHandle get adapter => AdapterHandle(jsu.getProperty<JSObject>(_vault, 'adapter'));

  /// Config directory path (typically `.obsidian`)
  String get configDir => jsu.getProperty<String>(_vault, 'configDir');

  // ===== Name and Root =====

  /// Get the name of the vault
  String getName() => jsu.callMethod<String>(_vault, 'getName', []);

  /// Get the root folder of the vault
  TFolderHandle getRoot() => TFolderHandle(jsu.callMethod<JSObject>(_vault, 'getRoot', []));

  // ===== File/Folder Retrieval =====

  /// Get a file by its path. Returns null if file doesn't exist.
  TFileHandle? getFileByPath(String path) {
    final res = jsu.callMethod<JSObject?>(_vault, 'getFileByPath', [path]);
    return res != null ? TFileHandle(res) : null;
  }

  /// Get a folder by its path. Returns null if folder doesn't exist.
  TFolderHandle? getFolderByPath(String path) {
    final res = jsu.callMethod<JSObject?>(_vault, 'getFolderByPath', [path]);
    return res != null ? TFolderHandle(res) : null;
  }

  /// Get a file or folder by path. Returns null if it doesn't exist.
  TAbstractFileHandle? getAbstractFileByPath(String path) {
    final res = jsu.callMethod<JSObject?>(_vault, 'getAbstractFileByPath', [path]);
    return res == null ? null : TAbstractFileHandle(res);
  }

  /// Get all markdown files in the vault
  List<TFileHandle> getMarkdownFiles() {
    final list = jsu.callMethod<JSArray>(_vault, 'getMarkdownFiles', []);
    return list.toDart.cast<JSObject>().map(TFileHandle.new).toList();
  }

  /// Get all files in the vault
  List<TFileHandle> getFiles() {
    final list = jsu.callMethod<JSArray>(_vault, 'getFiles', []);
    return list.toDart.cast<JSObject>().map(TFileHandle.new).toList();
  }

  /// Get all loaded files (includes folders)
  List<TAbstractFileHandle> getAllLoadedFiles() {
    final list = jsu.callMethod<JSArray>(_vault, 'getAllLoadedFiles', []);
    return list.toDart.cast<JSObject>().map(TAbstractFileHandle.new).toList();
  }

  // ===== Reading =====

  /// Read file content as string.
  ///
  /// Use this if you intend to modify the file content afterwards.
  Future<String> read(TFileHandle file) => jsu.promiseToFuture<String>(
    jsu.callMethod<Object?>(_vault, 'read', [file.raw])!,
  );

  /// Read file content from cache.
  ///
  /// Use this if you just want to display content and don't need the latest version.
  Future<String> cachedRead(TFileHandle file) => jsu.promiseToFuture<String>(
    jsu.callMethod<Object?>(_vault, 'cachedRead', [file.raw])!,
  );

  /// Read file content as binary (ArrayBuffer).
  ///
  /// Note: Obsidian API returns ArrayBuffer, we convert to Uint8List.
  /// Internally delegates to adapter.readBinary for conversion.
  Future<Uint8List> readBinary(TFileHandle file) => adapter.readBinary(file.path);

  /// Get resource path for a file (used for embedding)
  String getResourcePath(TFileHandle file) =>
      jsu.callMethod<String>(_vault, 'getResourcePath', [file.raw]);

  // ===== Creating =====

  /// Create a new file with text content.
  ///
  /// Throws if file already exists.
  Future<TFileHandle> create(
    String path,
    String data, [
    DataWriteOptions? options,
  ]) async {
    final args = options != null ? [path, data, options.toJS()] : [path, data];
    final res = await jsu.promiseToFuture<JSObject>(
      jsu.callMethod<Object?>(_vault, 'create', args)!,
    );
    return TFileHandle(res);
  }

  /// Create a new file with binary content (ArrayBuffer).
  ///
  /// Throws if file already exists.
  Future<TFileHandle> createBinary(
    String path,
    Uint8List data, [
    DataWriteOptions? options,
  ]) async {
    // Convert Uint8List to ArrayBuffer (required by Obsidian API)
    final jsUint8Array = jsu.callConstructor<JSObject>(
      jsu.getProperty<JSObject>(jsu.globalThis, 'Uint8Array'),
      [data.toJS],
    );
    final arrayBuffer = jsu.getProperty<JSObject>(jsUint8Array, 'buffer');

    final args = options != null ? [path, arrayBuffer, options.toJS()] : [path, arrayBuffer];
    final res = await jsu.promiseToFuture<JSObject>(
      jsu.callMethod<Object?>(_vault, 'createBinary', args)!,
    );
    return TFileHandle(res);
  }

  /// Create a new folder.
  ///
  /// Throws if folder already exists.
  Future<TFolderHandle> createFolder(String path) async {
    final res = await jsu.promiseToFuture<JSObject>(
      jsu.callMethod<Object?>(_vault, 'createFolder', [path])!,
    );
    return TFolderHandle(res);
  }

  // ===== Modifying =====

  /// Modify file content (text).
  ///
  /// BREAKING CHANGE: Now returns Future<void> (was Future<TFileHandle>).
  /// The original file handle remains valid after modification.
  Future<void> modify(
    TFileHandle file,
    String data, [
    DataWriteOptions? options,
  ]) async {
    final args = options != null ? [file.raw, data, options.toJS()] : [file.raw, data];
    await jsu.promiseToFuture<void>(
      jsu.callMethod<Object?>(_vault, 'modify', args)!,
    );
  }

  /// Modify file content (binary/ArrayBuffer).
  Future<void> modifyBinary(
    TFileHandle file,
    Uint8List data, [
    DataWriteOptions? options,
  ]) async {
    // Convert Uint8List to ArrayBuffer (required by Obsidian API)
    final jsUint8Array = jsu.callConstructor<JSObject>(
      jsu.getProperty<JSObject>(jsu.globalThis, 'Uint8Array'),
      [data.toJS],
    );
    final arrayBuffer = jsu.getProperty<JSObject>(jsUint8Array, 'buffer');

    final args = options != null
        ? [file.raw, arrayBuffer, options.toJS()]
        : [file.raw, arrayBuffer];
    await jsu.promiseToFuture<void>(
      jsu.callMethod<Object?>(_vault, 'modifyBinary', args)!,
    );
  }

  /// Append text to the end of a file.
  Future<void> append(
    TFileHandle file,
    String data, [
    DataWriteOptions? options,
  ]) async {
    final args = options != null ? [file.raw, data, options.toJS()] : [file.raw, data];
    await jsu.promiseToFuture<void>(
      jsu.callMethod<Object?>(_vault, 'append', args)!,
    );
  }

  /// Atomically read, modify, and save the contents of a file.
  ///
  /// Returns the new content of the file.
  Future<String> process(
    TFileHandle file,
    String Function(String data) fn, [
    DataWriteOptions? options,
  ]) async {
    final jsFn = jsu.allowInterop(fn);
    final args = options != null ? [file.raw, jsFn, options.toJS()] : [file.raw, jsFn];
    return jsu.promiseToFuture<String>(
      jsu.callMethod<Object?>(_vault, 'process', args)!,
    );
  }

  // ===== Deleting =====

  /// Delete a file or folder.
  ///
  /// Set `force` to true to delete folder even if it has hidden children.
  Future<void> delete(TAbstractFileHandle file, [bool force = false]) async {
    await jsu.promiseToFuture<void>(
      jsu.callMethod<Object?>(_vault, 'delete', [file.raw, force])!,
    );
  }

  /// Move file to trash (system trash or local .trash folder).
  ///
  /// Set `system` to false to force using local trash.
  Future<void> trash(TAbstractFileHandle file, {bool system = true}) async {
    await jsu.promiseToFuture<void>(
      jsu.callMethod<Object?>(_vault, 'trash', [file.raw, system])!,
    );
  }

  // ===== Renaming/Moving =====

  /// Rename or move a file/folder.
  ///
  /// BREAKING CHANGE: Now returns Future<void> (was Future<TAbstractFileHandle>).
  /// Use [getAbstractFileByPath] to get the renamed file if needed.
  ///
  /// Note: To ensure links are automatically renamed, use FileManager.renameFile instead.
  Future<void> rename(TAbstractFileHandle file, String newPath) async {
    await jsu.promiseToFuture<void>(
      jsu.callMethod<Object?>(_vault, 'rename', [file.raw, newPath])!,
    );
  }

  /// Copy a file to a new path.
  Future<TFileHandle> copy(TFileHandle file, String newPath) async {
    final res = await jsu.promiseToFuture<JSObject>(
      jsu.callMethod<Object?>(_vault, 'copy', [file.raw, newPath])!,
    );
    return TFileHandle(res);
  }

  // ===== Writing (via adapter) =====

  /// Write binary data to a path (via adapter).
  ///
  /// Convenience method that delegates to adapter.writeBinary.
  Future<void> writeBinary(
    String path,
    Uint8List bytes, [
    DataWriteOptions? options,
  ]) => adapter.writeBinary(path, bytes, options);

  // ===== Events =====

  /// Register an event listener.
  ///
  /// Returns an EventRef that can be unregistered with plugin.registerEvent().
  JSObject on(String event, JSFunction handler) =>
      jsu.callMethod<JSObject>(_vault, 'on', [event, handler]);

  /// Unregister an event listener by its EventRef.
  void offref(JSObject ref) => jsu.callMethod<void>(_vault, 'offref', [ref]);
}
