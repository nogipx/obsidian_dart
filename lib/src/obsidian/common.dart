// Common JS interop helpers and UI utilities.
import 'dart:js_interop';
// ignore_for_file: deprecated_member_use
import 'dart:js_util' as jsu;

import 'plugin_handle.dart';

JSObject obsidianModule() =>
    jsu.callMethod<JSObject>(jsu.globalThis, 'require', ['obsidian']);

JSObject obsidianExport(String name) =>
    jsu.getProperty<JSObject>(obsidianModule(), name);

void setText(JSObject element, String text) =>
    jsu.setProperty<Object?>(element, 'textContent', text);

void showNotice(String message, {int? timeoutMs}) {
  jsu.callConstructor<JSObject>(
    obsidianExport('Notice'),
    timeoutMs == null ? <Object?>[message] : <Object?>[message, timeoutMs],
  );
}

void log(Object? message) {
  final console = jsu.getProperty<JSObject>(jsu.globalThis, 'console');
  jsu.callMethod<Object?>(console, 'log', [message]);
}

void showModal(
  PluginHandle plugin, {
  required String title,
  required String body,
}) {
  final modalCtor = obsidianExport('Modal');
  final modal = jsu.callConstructor<JSObject>(modalCtor, [plugin.app.raw]);
  final contentEl = jsu.getProperty<JSObject>(modal, 'contentEl');
  final titleEl = jsu.callMethod<JSObject>(contentEl, 'createEl', ['h3']);
  setText(titleEl, title);
  final bodyEl = jsu.callMethod<JSObject>(contentEl, 'createEl', ['p']);
  setText(bodyEl, body);
  jsu.callMethod<Object?>(modal, 'open', []);
}
