import 'package:meta/meta.dart';
import '../obsidian/adapter.dart';

/// Immutable metadata model for files and folders.
///
/// Contains rich information extracted from file paths and stat data:
/// - Path components (name, extension, parent directory)
/// - Size in bytes
/// - Creation and modification timestamps
/// - Type detection (markdown, image, PDF, folder)
@immutable
class FileMetadata {
  const FileMetadata({
    required this.path,
    required this.name,
    required this.extension,
    required this.size,
    required this.createdTime,
    required this.modifiedTime,
    required this.isFolder,
  });

  /// Full path to the file/folder
  final String path;

  /// File name with extension (e.g., "note.md")
  final String name;

  /// File extension without dot (e.g., "md"), null for folders
  final String? extension;

  /// Size in bytes, null if unavailable
  final int? size;

  /// Creation time
  final DateTime createdTime;

  /// Last modification time
  final DateTime modifiedTime;

  /// True if this is a folder
  final bool isFolder;

  // Convenience getters

  /// Short alias for extension
  String? get ext => extension;

  /// File name without extension (e.g., "note" from "note.md")
  String get basename {
    if (extension == null || extension!.isEmpty) {
      return name;
    }
    final extWithDot = '.$extension';
    if (name.endsWith(extWithDot)) {
      return name.substring(0, name.length - extWithDot.length);
    }
    return name;
  }

  /// Parent directory path (empty string for root-level files)
  String get parentPath {
    final lastSlash = path.lastIndexOf('/');
    if (lastSlash <= 0) {
      return '';
    }
    return path.substring(0, lastSlash);
  }

  /// True if file is markdown (.md)
  bool get isMarkdown => extension?.toLowerCase() == 'md';

  /// True if file is an image (.png, .jpg, .jpeg, .gif, .svg, .webp)
  bool get isImage {
    if (extension == null) return false;
    final ext = extension!.toLowerCase();
    return {'png', 'jpg', 'jpeg', 'gif', 'svg', 'webp', 'bmp'}.contains(ext);
  }

  /// True if file is PDF
  bool get isPdf => extension?.toLowerCase() == 'pdf';

  /// True if file is JSON
  bool get isJson => extension?.toLowerCase() == 'json';

  /// True if file is YAML
  bool get isYaml {
    if (extension == null) return false;
    final ext = extension!.toLowerCase();
    return ext == 'yaml' || ext == 'yml';
  }

  /// Create metadata from path, name, and stat handle.
  ///
  /// Falls back to sensible defaults if stat is unavailable:
  /// - size: null
  /// - dates: DateTime.now()
  factory FileMetadata.fromStatAndPath(
    String path,
    String name,
    StatHandle? stat,
  ) {
    // Extract extension
    String? extension;
    final lastDot = name.lastIndexOf('.');
    if (lastDot > 0 && lastDot < name.length - 1) {
      extension = name.substring(lastDot + 1);
    }

    // Determine if folder (no stat type support, check extension presence)
    final isFolder = extension == null && stat?.type == 'folder';

    // Extract timestamps (milliseconds since epoch)
    final now = DateTime.now();
    final createdTime = stat?.ctime != null
        ? DateTime.fromMillisecondsSinceEpoch(stat!.ctime)
        : now;
    final modifiedTime = stat?.mtime != null
        ? DateTime.fromMillisecondsSinceEpoch(stat!.mtime)
        : now;

    return FileMetadata(
      path: path,
      name: name,
      extension: extension,
      size: stat?.size,
      createdTime: createdTime,
      modifiedTime: modifiedTime,
      isFolder: isFolder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileMetadata &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          name == other.name &&
          extension == other.extension &&
          size == other.size &&
          createdTime == other.createdTime &&
          modifiedTime == other.modifiedTime &&
          isFolder == other.isFolder;

  @override
  int get hashCode =>
      path.hashCode ^
      name.hashCode ^
      extension.hashCode ^
      size.hashCode ^
      createdTime.hashCode ^
      modifiedTime.hashCode ^
      isFolder.hashCode;

  @override
  String toString() => 'FileMetadata('
      'path: $path, '
      'name: $name, '
      'ext: $extension, '
      'size: $size, '
      'modified: $modifiedTime, '
      'isFolder: $isFolder'
      ')';
}
