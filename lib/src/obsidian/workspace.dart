import 'dart:js_interop';
// ignore_for_file: deprecated_member_use
import 'dart:js_util' as jsu;

import 'types.dart';

/// Workspace interface for managing editor state and UI.
///
/// Corresponds to Obsidian API `Workspace`.
class WorkspaceHandle {
  WorkspaceHandle(this._ws);

  final JSObject _ws;

  /// Get the currently active file.
  ///
  /// FIXED: Now uses correct `getActiveFile()` method instead of non-existent `lastActiveFile` property.
  TFileHandle? getActiveFile() {
    final file = jsu.callMethod<JSObject?>(_ws, 'getActiveFile', []);
    return file != null ? TFileHandle(file) : null;
  }

  /// Deprecated: Use getActiveFile() instead.
  ///
  /// This getter is kept for backward compatibility but internally uses getActiveFile().
  @Deprecated('Use getActiveFile() instead')
  TFileHandle? get activeFile => getActiveFile();

  /// Open a file in the workspace.
  ///
  /// Opens the file using openLinkText with the file's path.
  Future<void> openFile(
    TFileHandle file, {
    bool newLeaf = false,
  }) => jsu.promiseToFuture<void>(
    jsu.callMethod<Object?>(_ws, 'openLinkText', [
      file.path,
      '',
      newLeaf,
    ])!,
  );

  /// Register an event listener.
  ///
  /// Returns an EventRef that can be unregistered with plugin.registerEvent().
  ///
  /// Common events:
  /// - 'active-leaf-change': (leaf: WorkspaceLeaf) => void
  /// - 'file-open': (file: TFile | null) => void
  /// - 'layout-change': () => void
  /// - 'window-open': (win: WorkspaceWindow) => void
  /// - 'window-close': (win: WorkspaceWindow) => void
  /// - 'resize': () => void
  /// - 'click': (evt: MouseEvent) => void
  JSObject on(String event, JSFunction handler) =>
      jsu.callMethod<JSObject>(_ws, 'on', [event, handler]);
}
