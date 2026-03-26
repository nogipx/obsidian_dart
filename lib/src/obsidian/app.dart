import 'dart:js_interop';
// ignore_for_file: deprecated_member_use
import 'dart:js_util' as jsu;

import 'package:obsidian_dart/obsidian_dart.dart';

class AppHandle {
  AppHandle(this._app);
  final JSObject _app;

  JSObject get raw => _app;
  VaultHandle get vault =>
      VaultHandle(jsu.getProperty<JSObject>(_app, 'vault'));
  WorkspaceHandle get workspace =>
      WorkspaceHandle(jsu.getProperty<JSObject>(_app, 'workspace'));
  MetadataCacheHandle get metadataCache =>
      MetadataCacheHandle(jsu.getProperty<JSObject>(_app, 'metadataCache'));
  SecretStorageHandle get secretStorage => SecretStorageHandle(
        jsu.getProperty<JSObject?>(_app, 'secretStorage') ??
            jsu.newObject<JSObject>(),
      );

  JSObject get keymap => jsu.getProperty<JSObject>(_app, 'keymap');
}
