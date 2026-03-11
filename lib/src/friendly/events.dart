import 'dart:async';
import 'dart:js_interop';
// ignore_for_file: deprecated_member_use
import 'dart:js_util' as jsu;

import 'package:obsidian_dart/obsidian_dart.dart';
import 'package:rpc_dart/rpc_dart.dart';

class VaultEvents {
  VaultEvents(
    this.plugin, {
    RpcLogger? log,
  }) : _log = log?.child('VaultEvents');

  final RpcLogger? _log;
  final PluginHandle plugin;

  Stream<VaultEvent> get all => _all.stream;
  Stream<VaultEvent> get created => _all.stream.where((e) => e.type == VaultEventTypes.create);
  Stream<VaultEvent> get modified => _all.stream.where((e) => e.type == VaultEventTypes.modify);
  Stream<VaultEvent> get deleted => _all.stream.where((e) => e.type == VaultEventTypes.delete);
  Stream<VaultEvent> get renamed => _all.stream.where((e) => e.type == VaultEventTypes.rename);

  final _all = StreamController<VaultEvent>.broadcast();
  final _refs = <JSObject>[];
  bool _attached = false;

  void attach() {
    if (_attached) {
      _log?.debug('Already attached, skipping');
      return;
    }
    _attached = true;
    _log?.debug('Attaching to vault events...');
    final vault = plugin.app.vault;

    void register(String event, VaultEvent Function(List<Object?> args) mapper) {
      final handler = jsu.allowInterop((JSAny a, [JSAny? b]) {
        if (_all.isClosed) {
          return;
        }
        final args = <Object?>[a, b];
        final vaultEvent = mapper(args);
        _all.add(vaultEvent);
        _log?.debug(
          'Received raw event: $event \n'
          'Mapped to VaultEvent: type=${vaultEvent.type} path=${vaultEvent.file.path}',
        );
      });
      // ignore: invalid_runtime_check_with_js_interop_types
      final ref = vault.on(event, handler as JSFunction);
      plugin.registerEvent(ref);
      _refs.add(ref);
    }

    register(
      'create',
      (args) => VaultEvent.create(_asFile(args[0])),
    );
    register(
      'modify',
      (args) => VaultEvent.modify(_asFile(args[0])),
    );
    register(
      'delete',
      (args) => VaultEvent.delete(_asAbstractFile(args[0])),
    );
    register(
      'rename',
      (args) => VaultEvent.rename(_asAbstractFile(args[0]), args[1] as String?),
    );
    _log?.debug('All event handlers registered successfully');
  }

  Future<void> dispose() {
    final vault = plugin.app.vault;
    for (final ref in _refs) {
      vault.offref(ref);
    }
    _refs.clear();
    _attached = false;
    return _all.close();
  }
}

class WorkspaceEvents {
  WorkspaceEvents(this.plugin);

  final PluginHandle plugin;

  Stream<TFileHandle?> get fileOpen => _fileOpen.stream;

  final _fileOpen = StreamController<TFileHandle?>.broadcast();
  bool _attached = false;

  void attach() {
    if (_attached) {
      return;
    }
    _attached = true;
    final ws = plugin.app.workspace;
    final handler = jsu.allowInterop((JSAny? file) {
      final f = file == null ? null : TFileHandle(file as JSObject);
      _fileOpen.add(f);
    });
    // ignore: invalid_runtime_check_with_js_interop_types
    final ref = ws.on('file-open', handler as JSFunction);
    plugin.registerEvent(ref);
  }

  Future<void> dispose() => _fileOpen.close();
}

class VaultEvent {
  VaultEvent._(this.type, this.file, {this.oldPath});

  factory VaultEvent.create(TFileHandle file) => VaultEvent._(VaultEventTypes.create, file);

  factory VaultEvent.modify(TFileHandle file) => VaultEvent._(VaultEventTypes.modify, file);

  factory VaultEvent.delete(TAbstractFileHandle file) => VaultEvent._(VaultEventTypes.delete, file);

  factory VaultEvent.rename(TAbstractFileHandle file, String? oldPath) =>
      VaultEvent._(VaultEventTypes.rename, file, oldPath: oldPath);

  final VaultEventType type;
  final TAbstractFileHandle file;
  final String? oldPath;
}

typedef VaultEventType = String;

class VaultEventTypes {
  static const create = 'create';
  static const modify = 'modify';
  static const delete = 'delete';
  static const rename = 'rename';
}

TFileHandle _asFile(Object? value) => TFileHandle(value! as JSObject);
TAbstractFileHandle _asAbstractFile(Object? value) => TAbstractFileHandle(value! as JSObject);
