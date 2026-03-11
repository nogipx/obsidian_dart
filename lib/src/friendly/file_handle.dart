import '../obsidian/adapter.dart';
import '../obsidian/types.dart';
import 'file_metadata.dart';

/// Enhanced file handle with rich metadata.
///
/// Extends [TFileHandle] with additional metadata like size, dates, and type detection.
/// Fully compatible with existing APIs - can be used wherever [TFileHandle] is expected.
///
/// Example:
/// ```dart
/// final files = vault.getMarkdownFiles();
/// final enhanced = await FileHandle.fromList(files, vault.adapter);
/// for (final file in enhanced) {
///   print('${file.name}: ${file.size} bytes, modified: ${file.modifiedTime}');
/// }
/// ```
class FileHandle extends TFileHandle {
  FileHandle(super.raw, this.metadata);

  /// Rich metadata including size, dates, extension, type detection
  final FileMetadata metadata;

  // Convenience getters forwarding to metadata

  /// Size in bytes, null if unavailable
  int? get size => metadata.size;

  /// Parent directory path
  String get parentPath => metadata.parentPath;

  /// Creation time
  DateTime get createdTime => metadata.createdTime;

  /// Last modification time
  DateTime get modifiedTime => metadata.modifiedTime;

  /// True if file is markdown (.md)
  bool get isMarkdown => metadata.isMarkdown;

  /// True if file is an image
  bool get isImage => metadata.isImage;

  /// True if file is PDF
  bool get isPdf => metadata.isPdf;

  /// True if file is JSON
  bool get isJson => metadata.isJson;

  /// True if file is YAML
  bool get isYaml => metadata.isYaml;

  /// Create enhanced handle from existing [TFileHandle].
  ///
  /// Loads metadata using [AdapterHandle.stat()].
  /// Falls back to sensible defaults if stat fails.
  static Future<FileHandle> from(
    TFileHandle file,
    AdapterHandle adapter,
  ) async {
    StatHandle? stat;
    try {
      stat = await adapter.stat(file.path);
    } catch (_) {
      // Graceful degradation if stat fails
      stat = null;
    }

    final metadata = FileMetadata.fromStatAndPath(
      file.path,
      file.name,
      stat,
    );

    return FileHandle(file.raw, metadata);
  }

  /// Bulk conversion from list of [TFileHandle] to [FileHandle].
  ///
  /// Loads metadata for all files in parallel.
  static Future<List<FileHandle>> fromList(
    List<TFileHandle> files,
    AdapterHandle adapter,
  ) async {
    return Future.wait(files.map((f) => from(f, adapter)));
  }

  @override
  String toString() => 'FileHandle(${metadata.path}, ${metadata.size} bytes)';
}

/// Enhanced folder handle with rich metadata.
///
/// Extends [TFolderHandle] with additional metadata.
/// Fully compatible with existing APIs.
class FolderHandle extends TFolderHandle {
  FolderHandle(super.raw, this.metadata);

  /// Rich metadata including dates
  final FileMetadata metadata;

  // Convenience getters forwarding to metadata

  /// Parent directory path
  String get parentPath => metadata.parentPath;

  /// Creation time
  DateTime get createdTime => metadata.createdTime;

  /// Last modification time
  DateTime get modifiedTime => metadata.modifiedTime;

  /// Create enhanced handle from existing [TFolderHandle].
  ///
  /// Loads metadata using [AdapterHandle.stat()].
  /// Falls back to sensible defaults if stat fails.
  static Future<FolderHandle> from(
    TFolderHandle folder,
    AdapterHandle adapter,
  ) async {
    StatHandle? stat;
    try {
      stat = await adapter.stat(folder.path);
    } catch (_) {
      // Graceful degradation if stat fails
      stat = null;
    }

    final metadata = FileMetadata.fromStatAndPath(
      folder.path,
      folder.name,
      stat,
    );

    return FolderHandle(folder.raw, metadata);
  }

  /// Bulk conversion from list of [TFolderHandle] to [FolderHandle].
  ///
  /// Loads metadata for all folders in parallel.
  static Future<List<FolderHandle>> fromList(
    List<TFolderHandle> folders,
    AdapterHandle adapter,
  ) async {
    return Future.wait(folders.map((f) => from(f, adapter)));
  }

  @override
  String toString() => 'FolderHandle(${metadata.path})';
}
