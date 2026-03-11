import 'dart:async';
import 'dart:js_interop';
// ignore: deprecated_member_use
import 'dart:js_util' as jsu;

import 'obsidian/_index.dart';

typedef OnLoad = FutureOr<void> Function(PluginHandle plugin);
typedef OnUnload = FutureOr<void> Function(PluginHandle plugin);

/// Registers Dart lifecycle hooks so a small JS wrapper can delegate to them.
void bootstrapPlugin({required OnLoad onLoad, OnUnload? onUnload}) {
  final container = jsu.newObject<JSObject>();

  jsu.setProperty(
    container,
    'onload',
    jsu.allowInterop(
      (JSAny plugin) async => onLoad(PluginHandle(plugin as JSObject)),
    ),
  );

  if (onUnload != null) {
    jsu.setProperty(
      container,
      'onunload',
      jsu.allowInterop(
        (JSAny plugin) async => onUnload(PluginHandle(plugin as JSObject)),
      ),
    );
  }

  jsu.setProperty(jsu.globalThis, '_dartObsidianPlugin', container);
}
