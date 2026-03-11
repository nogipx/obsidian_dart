import 'dart:js_interop';
// ignore_for_file: deprecated_member_use
import 'dart:js_util' as jsu;

/// Base class for files and folders in the vault.
///
/// Corresponds to Obsidian API `TAbstractFile`.
/// This can be either a [TFileHandle] or a [TFolderHandle].
class TAbstractFileHandle {
  TAbstractFileHandle(this.raw);

  final JSObject raw;

  /// Vault absolute path to the file or folder
  String get path => jsu.getProperty<String>(raw, 'path');

  /// Name of the file or folder (with extension for files)
  String get name => jsu.getProperty<String>(raw, 'name');

  /// Parent folder, or null if this is the root
  TFolderHandle? get parent {
    final parentObj = jsu.getProperty<JSObject?>(raw, 'parent');
    return parentObj != null ? TFolderHandle(parentObj) : null;
  }

  /// The vault this file belongs to
  /// Note: This creates a circular reference, use with caution
  JSObject get vaultRaw => jsu.getProperty<JSObject>(raw, 'vault');
}

/// Represents a file in the vault.
///
/// Corresponds to Obsidian API `TFile`.
class TFileHandle extends TAbstractFileHandle {
  TFileHandle(super.raw);

  /// File statistics (size, timestamps)
  FileStatsHandle get stat => FileStatsHandle(jsu.getProperty<JSObject>(raw, 'stat'));

  /// File name without extension
  String get basename => jsu.getProperty<String>(raw, 'basename');

  /// File extension (without dot)
  String get extension => jsu.getProperty<String>(raw, 'extension');
}

/// Represents a folder in the vault.
///
/// Corresponds to Obsidian API `TFolder`.
class TFolderHandle extends TAbstractFileHandle {
  TFolderHandle(super.raw);

  /// List of children files and folders
  List<TAbstractFileHandle> get children {
    final childrenArray = jsu.getProperty<JSArray?>(raw, 'children');
    if (childrenArray == null) return [];

    return childrenArray.toDart.cast<JSObject>().map((obj) {
      // Check if it's a file or folder by checking for 'extension' property
      final hasExtension = jsu.hasProperty(obj, 'extension');
      return hasExtension ? TFileHandle(obj) : TFolderHandle(obj);
    }).toList();
  }

  /// Check if this is the root folder
  bool isRoot() => jsu.callMethod<bool>(raw, 'isRoot', []);
}

/// File statistics.
///
/// Corresponds to Obsidian API `FileStats`.
class FileStatsHandle {
  FileStatsHandle(this.raw);

  final JSObject raw;

  /// Time of creation, in milliseconds since Unix epoch
  int get ctime => jsu.getProperty<int>(raw, 'ctime');

  /// Time of last modification, in milliseconds since Unix epoch
  int get mtime => jsu.getProperty<int>(raw, 'mtime');

  /// File size in bytes
  int get size => jsu.getProperty<int>(raw, 'size');
}

/// Options for writing data to files.
///
/// Corresponds to Obsidian API `DataWriteOptions`.
class DataWriteOptions {
  const DataWriteOptions({
    this.ctime,
    this.mtime,
  });

  /// Creation time in milliseconds since Unix epoch
  final int? ctime;

  /// Modification time in milliseconds since Unix epoch
  final int? mtime;

  JSObject toJS() {
    final obj = jsu.newObject<JSObject>();
    if (ctime != null) {
      jsu.setProperty(obj, 'ctime', ctime);
    }
    if (mtime != null) {
      jsu.setProperty(obj, 'mtime', mtime);
    }
    return obj;
  }
}
