import 'dart:async';
import 'dart:js_interop';
// ignore: deprecated_member_use
import 'dart:js_util' as jsu;

import 'obsidian/_index.dart';

typedef OnLoad = FutureOr<void> Function(PluginHandle plugin);
typedef OnUnload = FutureOr<void> Function(PluginHandle plugin);

const _kStyleId = 'obsidian-dart-styles';

const _kCss = '''
.obsidian-dart-spinner { color: var(--text-muted); font-size: 0.85em; }
.obsidian-dart-spinner--hidden { display: none; }
.obsidian-dart-spinner--visible { display: inline; }
.obsidian-dart-row { display: flex; flex-direction: row; align-items: center; }
.obsidian-dart-column { display: flex; flex-direction: column; }
.obsidian-dart-space-v--4  { margin-top: 4px; }
.obsidian-dart-space-v--8  { margin-top: 8px; }
.obsidian-dart-space-v--12 { margin-top: 12px; }
.obsidian-dart-space-v--16 { margin-top: 16px; }
.obsidian-dart-space-v--24 { margin-top: 24px; }
.obsidian-dart-space-h--4  { display: inline-block; margin-left: 4px; }
.obsidian-dart-space-h--8  { display: inline-block; margin-left: 8px; }
.obsidian-dart-space-h--12 { display: inline-block; margin-left: 12px; }
.obsidian-dart-space-h--16 { display: inline-block; margin-left: 16px; }
.obsidian-dart-space-h--24 { display: inline-block; margin-left: 24px; }

.obsidian-dart-group { border-radius: var(--radius-m); border: 1px solid var(--background-modifier-border); overflow: hidden; }
.obsidian-dart-group .setting-item:last-child { border-bottom: none; }
''';

void _injectStyles() {
  final document = jsu.getProperty<JSObject>(jsu.globalThis, 'document');
  final existing = jsu.callMethod<JSObject?>(document, 'getElementById', [_kStyleId]);
  if (existing != null) return;
  final style = jsu.callMethod<JSObject>(document, 'createElement', ['style']);
  jsu.setProperty(style, 'id', _kStyleId);
  jsu.setProperty(style, 'textContent', _kCss);
  final head = jsu.getProperty<JSObject>(document, 'head');
  jsu.callMethod<void>(head, 'appendChild', [style]);
}

void _removeStyles() {
  final document = jsu.getProperty<JSObject>(jsu.globalThis, 'document');
  final existing = jsu.callMethod<JSObject?>(document, 'getElementById', [_kStyleId]);
  if (existing != null) {
    jsu.callMethod<void>(existing, 'remove', []);
  }
}

/// Registers Dart lifecycle hooks so a small JS wrapper can delegate to them.
void bootstrapPlugin({required OnLoad onLoad, OnUnload? onUnload}) {
  final container = jsu.newObject<JSObject>();

  jsu.setProperty(
    container,
    'onload',
    jsu.allowInterop(
      (JSAny plugin) async {
        _injectStyles();
        await onLoad(PluginHandle(plugin as JSObject));
      },
    ),
  );

  jsu.setProperty(
    container,
    'onunload',
    jsu.allowInterop(
      (JSAny plugin) async {
        _removeStyles();
        if (onUnload != null) await onUnload(PluginHandle(plugin as JSObject));
      },
    ),
  );

  jsu.setProperty(jsu.globalThis, '_dartObsidianPlugin', container);
}
