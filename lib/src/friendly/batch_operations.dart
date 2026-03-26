import 'package:meta/meta.dart';

import '../obsidian/types.dart';
import '../obsidian/vault.dart';

/// Result of a batch operation.
///
/// Contains succeeded/failed items, results, and errors.
@immutable
class BatchResult<T> {
  const BatchResult({
    required this.succeeded,
    required this.failed,
    required this.results,
    required this.errors,
  });

  /// Items that succeeded
  final List<T> succeeded;

  /// Items that failed
  final List<T> failed;

  /// Results for each item (key = item, value = result)
  final Map<T, dynamic> results;

  /// Errors for failed items (key = item, value = error)
  final Map<T, Object> errors;

  // Convenience getters

  bool get hasErrors => failed.isNotEmpty;
  bool get allSucceeded => failed.isEmpty;
  int get successCount => succeeded.length;
  int get failureCount => failed.length;

  @override
  String toString() => 'BatchResult('
      'succeeded: $successCount, '
      'failed: $failureCount'
      ')';
}

/// Abstract file operation that can be executed and rolled back.
abstract class FileOperation {
  const FileOperation();

  /// Execute the operation
  Future<void> execute(VaultHandle vault);

  /// Rollback the operation (undo)
  Future<void> rollback(VaultHandle vault);

  /// Human-readable description
  String get description;
}

/// Create file operation
class CreateFileOp extends FileOperation {
  const CreateFileOp(this.path, this.content);

  final String path;
  final String content;

  @override
  Future<void> execute(VaultHandle vault) async {
    await vault.create(path, content);
  }

  @override
  Future<void> rollback(VaultHandle vault) async {
    final file = vault.getAbstractFileByPath(path);
    if (file != null) {
      await vault.delete(file);
    }
  }

  @override
  String get description => 'Create $path';
}

/// Modify file operation
class ModifyFileOp extends FileOperation {
  ModifyFileOp(this.file, this.newContent);

  final TFileHandle file;
  final String newContent;
  String? _oldContent;

  @override
  Future<void> execute(VaultHandle vault) async {
    // Backup old content for rollback
    _oldContent = await vault.read(file);
    await vault.modify(file, newContent);
  }

  @override
  Future<void> rollback(VaultHandle vault) async {
    if (_oldContent != null) {
      await vault.modify(file, _oldContent!);
    }
  }

  @override
  String get description => 'Modify ${file.path}';
}

/// Delete file operation
class DeleteFileOp extends FileOperation {
  DeleteFileOp(this.file);

  final TAbstractFileHandle file;
  String? _backupContent;
  bool _wasFile = false;

  @override
  Future<void> execute(VaultHandle vault) async {
    // Backup content if it's a file (for rollback)
    if (file is TFileHandle) {
      _wasFile = true;
      try {
        _backupContent = await vault.read(file as TFileHandle);
      } catch (_) {
        // Ignore if read fails
      }
    }
    await vault.delete(file);
  }

  @override
  Future<void> rollback(VaultHandle vault) async {
    // Recreate file with backup content
    if (_wasFile && _backupContent != null) {
      await vault.create(file.path, _backupContent!);
    } else {
      // Recreate folder
      await vault.createFolder(file.path);
    }
  }

  @override
  String get description => 'Delete ${file.path}';
}

/// Rename file operation
class RenameFileOp extends FileOperation {
  RenameFileOp(this.file, this.newPath);

  final TAbstractFileHandle file;
  final String newPath;
  String? _oldPath;

  @override
  Future<void> execute(VaultHandle vault) async {
    _oldPath = file.path;
    await vault.rename(file, newPath);
  }

  @override
  Future<void> rollback(VaultHandle vault) async {
    if (_oldPath != null) {
      final currentFile = vault.getAbstractFileByPath(newPath);
      if (currentFile != null) {
        await vault.rename(currentFile, _oldPath!);
      }
    }
  }

  @override
  String get description => 'Rename ${file.path} to $newPath';
}

/// Builder for creating transactions with multiple operations.
///
/// Operations are executed sequentially. On failure, all succeeded operations
/// are rolled back in reverse order.
///
/// Example:
/// ```dart
/// final result = await vault.batch.transaction()
///     .create('notes/new.md', '# New Note')
///     .modify(existingFile, '# Updated')
///     .delete(oldFile)
///     .commit();
///
/// if (result.allSucceeded) {
///   print('All operations succeeded');
/// } else {
///   print('${result.failureCount} operations failed');
/// }
/// ```
class TransactionBuilder {
  TransactionBuilder(this._vault);

  final VaultHandle _vault;
  final List<FileOperation> _operations = [];

  /// Add create file operation
  TransactionBuilder create(String path, String content) {
    _operations.add(CreateFileOp(path, content));
    return this;
  }

  /// Add modify file operation
  TransactionBuilder modify(TFileHandle file, String content) {
    _operations.add(ModifyFileOp(file, content));
    return this;
  }

  /// Add delete file operation
  TransactionBuilder delete(TAbstractFileHandle file) {
    _operations.add(DeleteFileOp(file));
    return this;
  }

  /// Add rename file operation
  TransactionBuilder rename(TAbstractFileHandle file, String newPath) {
    _operations.add(RenameFileOp(file, newPath));
    return this;
  }

  /// Add custom operation
  TransactionBuilder addOperation(FileOperation op) {
    _operations.add(op);
    return this;
  }

  /// Execute transaction with rollback on failure.
  ///
  /// [continueOnError] - if true, continue executing remaining operations
  /// even if some fail (default: false - abort on first error).
  ///
  /// [onProgress] - callback invoked after each operation completes.
  Future<BatchResult<FileOperation>> commit({
    bool continueOnError = false,
    void Function(FileOperation op, int current, int total)? onProgress,
  }) async {
    final succeeded = <FileOperation>[];
    final failed = <FileOperation>[];
    final results = <FileOperation, dynamic>{};
    final errors = <FileOperation, Object>{};

    final total = _operations.length;

    // Execute operations
    for (var i = 0; i < _operations.length; i++) {
      final op = _operations[i];
      final current = i + 1;

      try {
        await op.execute(_vault);
        succeeded.add(op);
        results[op] = true;
        onProgress?.call(op, current, total);
      } catch (e) {
        failed.add(op);
        errors[op] = e;
        onProgress?.call(op, current, total);

        if (!continueOnError) {
          // Rollback all succeeded operations in reverse order
          await _rollback(succeeded);
          break;
        }
      }
    }

    return BatchResult(
      succeeded: succeeded,
      failed: failed,
      results: results,
      errors: errors,
    );
  }

  /// Rollback operations in reverse order
  Future<void> _rollback(List<FileOperation> operations) async {
    for (final op in operations.reversed) {
      try {
        await op.rollback(_vault);
      } catch (_) {
        // Ignore rollback errors
      }
    }
  }

  int get operationCount => _operations.length;

  void clear() => _operations.clear();
}

/// Batch file operations without transactions.
///
/// Provides bulk operations on multiple files (copy, move, delete, rename).
/// Operations are independent - failure of one doesn't affect others.
class BatchFileOperations {
  BatchFileOperations(this._vault);

  final VaultHandle _vault;

  /// Start building a transaction
  TransactionBuilder transaction() => TransactionBuilder(_vault);

  /// Copy multiple files to target folder
  Future<BatchResult<TFileHandle>> copyFiles(
    List<TFileHandle> files,
    String targetFolder,
  ) async {
    final succeeded = <TFileHandle>[];
    final failed = <TFileHandle>[];
    final results = <TFileHandle, dynamic>{};
    final errors = <TFileHandle, Object>{};

    for (final file in files) {
      try {
        final targetPath = '$targetFolder/${file.name}';
        await _vault.adapter.copy(file.path, targetPath);
        succeeded.add(file);
        results[file] = targetPath;
      } catch (e) {
        failed.add(file);
        errors[file] = e;
      }
    }

    return BatchResult(
      succeeded: succeeded,
      failed: failed,
      results: results,
      errors: errors,
    );
  }

  /// Move multiple files to target folder
  Future<BatchResult<TFileHandle>> moveFiles(
    List<TFileHandle> files,
    String targetFolder,
  ) async {
    final succeeded = <TFileHandle>[];
    final failed = <TFileHandle>[];
    final results = <TFileHandle, dynamic>{};
    final errors = <TFileHandle, Object>{};

    for (final file in files) {
      try {
        final targetPath = '$targetFolder/${file.name}';
        await _vault.rename(file, targetPath);
        succeeded.add(file);
        results[file] = targetPath;
      } catch (e) {
        failed.add(file);
        errors[file] = e;
      }
    }

    return BatchResult(
      succeeded: succeeded,
      failed: failed,
      results: results,
      errors: errors,
    );
  }

  /// Delete multiple files
  Future<BatchResult<TAbstractFileHandle>> deleteFiles(
    List<TAbstractFileHandle> files,
  ) async {
    final succeeded = <TAbstractFileHandle>[];
    final failed = <TAbstractFileHandle>[];
    final results = <TAbstractFileHandle, dynamic>{};
    final errors = <TAbstractFileHandle, Object>{};

    for (final file in files) {
      try {
        await _vault.delete(file);
        succeeded.add(file);
        results[file] = true;
      } catch (e) {
        failed.add(file);
        errors[file] = e;
      }
    }

    return BatchResult(
      succeeded: succeeded,
      failed: failed,
      results: results,
      errors: errors,
    );
  }

  /// Rename multiple files using a pattern function
  Future<BatchResult<TFileHandle>> renameWithPattern(
    List<TFileHandle> files,
    String Function(String currentName) pattern,
  ) async {
    final succeeded = <TFileHandle>[];
    final failed = <TFileHandle>[];
    final results = <TFileHandle, dynamic>{};
    final errors = <TFileHandle, Object>{};

    for (final file in files) {
      try {
        final newName = pattern(file.name);
        // Preserve directory structure
        final parentPath =
            file.path.substring(0, file.path.lastIndexOf('/') + 1);
        final newPath = '$parentPath$newName';

        await _vault.rename(file, newPath);
        succeeded.add(file);
        results[file] = newPath;
      } catch (e) {
        failed.add(file);
        errors[file] = e;
      }
    }

    return BatchResult(
      succeeded: succeeded,
      failed: failed,
      results: results,
      errors: errors,
    );
  }
}

/// Extension to add batch operations to VaultHandle
extension VaultBatchExtension on VaultHandle {
  /// Batch file operations
  BatchFileOperations get batch => BatchFileOperations(this);
}
