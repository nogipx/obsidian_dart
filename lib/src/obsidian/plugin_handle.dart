import 'dart:async';
import 'dart:js_interop';
// ignore_for_file: deprecated_member_use
import 'dart:js_util' as jsu;

import 'app.dart';

class PluginHandle {
  PluginHandle(this._plugin);

  final JSObject _plugin;

  JSObject get appRaw => jsu.getProperty<JSObject>(_plugin, 'app');
  JSObject get raw => _plugin;

  AppHandle get app => AppHandle(appRaw);

  /// Path to the plugin directory relative to vault root, e.g. `.obsidian/plugins/my-plugin`.
  String? get manifestDir {
    final manifest = jsu.getProperty<JSObject?>(_plugin, 'manifest');
    if (manifest == null) return null;
    return jsu.getProperty<String?>(manifest, 'dir');
  }

  JSObject addCommand({
    required String id,
    required String name,
    FutureOr<void> Function()? callback,
  }) {
    final cmd = jsu.newObject<JSObject>();
    jsu.setProperty(cmd, 'id', id);
    jsu.setProperty(cmd, 'name', name);
    if (callback != null) {
      jsu.setProperty(
        cmd,
        'callback',
        jsu.allowInterop(() async => callback()),
      );
    }
    return jsu.callMethod<JSObject>(_plugin, 'addCommand', [cmd]);
  }

  JSObject addRibbonIcon(
    String icon,
    String tooltip,
    FutureOr<void> Function()? onClick,
  ) {
    final handler = onClick != null
        ? jsu.allowInterop((JSAny? _) async => onClick())
        : null;
    return jsu.callMethod<JSObject>(
        _plugin, 'addRibbonIcon', [icon, tooltip, handler]);
  }

  JSObject addStatusBarItem() =>
      jsu.callMethod<JSObject>(_plugin, 'addStatusBarItem', []);

  void registerEvent(JSObject eventRef) =>
      jsu.callMethod<Object?>(_plugin, 'registerEvent', [eventRef]);

  Future<void> saveData(Object data) {
    var payload = data;
    // Obsidian expects plain JS objects; convert Dart Map/List to JS structure
    // to avoid silent serialization failures.
    try {
      payload = jsu.jsify(data);
    } on Object catch (_) {
      // Fallback: pass through original data; saveData may still handle it.
      payload = data;
    }
    return jsu.promiseToFuture<void>(
      jsu.callMethod<Object?>(_plugin, 'saveData', [payload])!,
    );
  }

  void addSettingTab(JSObject tab) =>
      jsu.callMethod<void>(_plugin, 'addSettingTab', [tab]);

  Future<Object?> loadData() async {
    final raw = await jsu.promiseToFuture<Object?>(
      jsu.callMethod<Object?>(_plugin, 'loadData', [])!,
    );
    return jsu.dartify(raw);
  }

  /// Higher-level helper: creates a status bar container and returns a wrapper.
  StatusItem addStatusItem({
    String? text,
    String? icon,
    String? tooltip,
    FutureOr<void> Function()? onClick,
  }) {
    final el = addStatusBarItem();
    final item = StatusItem(el);
    if (icon != null) {
      item.setIcon(icon);
    }
    if (text != null) {
      item.setText(text);
    }
    if (tooltip != null) {
      item.setTooltip(tooltip);
    }
    if (onClick != null) {
      item.onClick(onClick);
    }
    return item;
  }
}

class StatusItem {
  StatusItem(this.el);
  final JSObject el;
  JSObject get raw => el;

  void setText(String text) =>
      jsu.setProperty<dynamic>(el, 'textContent', text);

  void setIcon(String text) {
    setText(text);
  }

  void setTooltip(String tooltip) {
    jsu.setProperty(el, 'aria-label', tooltip);
    jsu.setProperty(el, 'className', 'mod-clickable');
  }

  void onClick(FutureOr<void> Function() handler) {
    jsu.callMethod<Object?>(el, 'addEventListener', [
      'click',
      jsu.allowInterop((JSAny? _) => handler()),
    ]);
  }

  void setClass(String className) =>
      jsu.setProperty<dynamic>(el, 'className', className);
}
