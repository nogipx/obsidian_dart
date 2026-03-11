import 'dart:async';
import 'dart:js_interop';
// ignore_for_file: deprecated_member_use
import 'dart:js_util' as jsu;

import 'common.dart';
import 'plugin_handle.dart';

/// Low-level modal builder: pass a builder closure, get back a Future<T?>.
Future<T?> showModalWith<T>(
  PluginHandle plugin, {
  required void Function(ModalContext<T> ctx) build,
}) {
  final ctx = ModalContext<T>._(plugin);
  build(ctx);
  return ctx._open();
}

/// Password prompt — same as [showTextPrompt] but input type is 'password'.
///
/// Returns `null` if the user closes or cancels.
Future<String?> showPasswordPrompt(
  PluginHandle plugin, {
  String title = 'Enter passphrase',
  String placeholder = '',
  String okLabel = 'Unlock',
  String cancelLabel = 'Cancel',
}) {
  return showModalWith<String?>(
    plugin,
    build: (ctx) {
      ctx.h3(title);
      final input = ctx.input(type: 'password', placeholder: placeholder)..focus();
      ctx
        ..buttonRow(
          [
            ButtonSpec(okLabel, () => ctx.close(ctx.valueOf(input))),
            ButtonSpec(cancelLabel, () => ctx.close(null)),
          ],
        )
        ..onEnter(input, () => ctx.close(ctx.valueOf(input)))
        ..onEscape(() => ctx.close(null));
    },
  );
}

/// Simplest text prompt using Obsidian Modal (since `prompt()` is unavailable).
///
/// Returns `null` if the user closes or cancels.
Future<String?> showTextPrompt(
  PluginHandle plugin, {
  String title = 'Input',
  String placeholder = '',
  String okLabel = 'OK',
  String cancelLabel = 'Cancel',
}) {
  return showModalWith<String?>(
    plugin,
    build: (ctx) {
      ctx.h3(title);
      final input = ctx.input(placeholder: placeholder)..focus();
      ctx
        ..buttonRow(
          [
            ButtonSpec(okLabel, () => ctx.close(ctx.valueOf(input))),
            ButtonSpec(cancelLabel, () => ctx.close(null)),
          ],
        )
        ..onEnter(input, () => ctx.close(ctx.valueOf(input)))
        ..onEscape(() => ctx.close(null));
    },
  );
}

/// Fluent helpers to build modal content.
class ModalContext<T> {
  ModalContext._(PluginHandle plugin)
    : _modal = jsu.callConstructor<JSObject>(obsidianExport('Modal'), [plugin.app.raw]) {
    contentEl = jsu.getProperty<JSObject>(_modal, 'contentEl');
    jsu.setProperty(
      _modal,
      'onClose',
      jsu.allowInterop(() {
        close(null);
      }),
    );
  }

  late final JSObject _modal;
  late final JSObject contentEl;
  final _completer = Completer<T?>();

  JSObject createEl(String tag, {String? cls, String? text, String? style}) {
    final el = jsu.callMethod<JSObject>(contentEl, 'createEl', [tag]);
    if (cls != null) jsu.setProperty(el, 'className', cls);
    if (text != null) setText(el, text);
    if (style != null) jsu.setProperty(el, 'style', style);
    return el;
  }

  JSObject h3(String text) => createEl('h3', text: text);

  void spaceVertical({int px = 12}) {
    final el = createEl('div');
    jsu.setProperty(el, 'style', 'margin-top: ${px}px');
  }

  void spaceHorizontal({int px = 12}) {
    final el = createEl('span');
    jsu.setProperty(el, 'style', 'display: inline-block; margin-left: ${px}px');
  }

  void row(void Function(LayoutContext ctx) build, {String? cls}) {
    final el = createEl('div', cls: cls);
    jsu.setProperty(el, 'style', 'display: flex; flex-direction: row; align-items: center');
    build(LayoutContext(el));
  }

  void column(void Function(LayoutContext ctx) build, {String? cls}) {
    final el = createEl('div', cls: cls);
    jsu.setProperty(el, 'style', 'display: flex; flex-direction: column');
    build(LayoutContext(el));
  }

  /// Creates a hidden spinner element. Call [SpinnerRef.show] to start and [SpinnerRef.hide] to stop.
  SpinnerRef spinner({String label = '', String? style}) {
    final el = createEl(
      'span',
      style: 'display: none; color: var(--text-muted); font-size: 0.85em${style != null ? '; $style' : ''}',
    );
    return SpinnerRef(el, label: label);
  }

  InputRef input({String type = 'text', String placeholder = ''}) {
    final el = createEl('input');
    jsu.setProperty(el, 'type', type);
    if (placeholder.isNotEmpty) {
      jsu.setProperty(el, 'placeholder', placeholder);
    }
    return InputRef(el);
  }

  /// Checkbox with a label. [onChange] is called with the new value on each change.
  void toggle({
    required String label,
    required bool initialValue,
    required void Function(bool) onChange,
  }) {
    final row = createEl('div');
    final labelEl = jsu.callMethod<JSObject>(row, 'createEl', ['label']);
    final checkbox = jsu.callMethod<JSObject>(labelEl, 'createEl', ['input']);
    jsu.setProperty(checkbox, 'type', 'checkbox');
    jsu.setProperty(checkbox, 'checked', initialValue);
    jsu.callMethod<JSObject>(labelEl, 'createEl', ['span', jsu.jsify({'text': ' $label'})]);
    jsu.callMethod<Object?>(checkbox, 'addEventListener', [
      'change',
      jsu.allowInterop((JSObject e) {
        onChange(jsu.getProperty<bool>(checkbox, 'checked'));
      }),
    ]);
  }

  /// Shows an error message inside the modal (replaces previous error if any).
  void showError(String message) {
    final existing = jsu.callMethod<JSObject?>(
      contentEl, 'querySelector', ['.rhyolite-modal-error'],
    );
    if (existing != null) {
      setText(existing, message);
    } else {
      createEl('p', cls: 'rhyolite-modal-error', text: message);
    }
  }

  ButtonRef button(
    String label,
    void Function() onClick, {
    ButtonVariant variant = ButtonVariant.secondary,
  }) {
    final btn = createEl('button', text: label);
    _applyButtonVariant(btn, variant);
    jsu.callMethod<Object?>(btn, 'addEventListener', [
      'click',
      jsu.allowInterop((JSAny? _) => onClick()),
    ]);
    return ButtonRef(btn);
  }

  List<ButtonRef> buttonRow(List<ButtonSpec> buttons) {
    final row = createEl('div', cls: 'modal-button-container');
    final refs = <ButtonRef>[];
    for (final b in buttons) {
      final btn = jsu.callMethod<JSObject>(row, 'createEl', ['button']);
      setText(btn, b.label);
      _applyButtonVariant(btn, b.variant);
      jsu.callMethod<Object?>(btn, 'addEventListener', [
        'click',
        jsu.allowInterop((JSAny? _) => b.onClick()),
      ]);
      refs.add(ButtonRef(btn));
    }
    return refs;
  }

  void onEnter(InputRef input, void Function() handler) {
    jsu.callMethod<Object?>(input.raw, 'addEventListener', [
      'keydown',
      jsu.allowInterop((JSObject e) {
        if (jsu.getProperty<String>(e, 'key') == 'Enter') {
          handler();
        }
      }),
    ]);
  }

  void onEscape(void Function() handler) {
    jsu.callMethod<Object?>(contentEl, 'addEventListener', [
      'keydown',
      jsu.allowInterop((JSObject e) {
        if (jsu.getProperty<String>(e, 'key') == 'Escape') {
          handler();
        }
      }),
    ]);
  }

  void _applyButtonVariant(JSObject btn, ButtonVariant variant) {
    switch (variant) {
      case ButtonVariant.primary:
        jsu.callMethod<void>(btn, 'addClass', ['mod-cta']);
      case ButtonVariant.destructive:
        jsu.callMethod<void>(btn, 'addClass', ['mod-warning']);
      case ButtonVariant.secondary:
        break;
    }
  }

  String valueOf(InputRef input) => jsu.getProperty<String>(input.raw, 'value');

  void close(T? value) {
    if (_completer.isCompleted) {
      return;
    }
    _completer.complete(value);
    jsu.callMethod<Object?>(_modal, 'close', []);
  }

  Future<T?> _open() {
    jsu.callMethod<Object?>(_modal, 'open', []);
    return _completer.future;
  }
}

enum ButtonVariant { secondary, primary, destructive }

class ButtonSpec {
  const ButtonSpec(this.label, this.onClick, {this.variant = ButtonVariant.secondary});
  final String label;
  final void Function() onClick;
  final ButtonVariant variant;
}

class InputRef {
  InputRef(this.raw);
  final JSObject raw;
  void focus() => jsu.callMethod<Object?>(raw, 'focus', []);
}

class ButtonRef {
  ButtonRef(this.raw);
  final JSObject raw;

  void setDisabled({required bool value}) {
    jsu.setProperty(raw, 'disabled', value);
  }

  void setLabel(String label) {
    setText(raw, label);
  }
}

class SpinnerRef {
  SpinnerRef(this._el, {required this.label});

  final JSObject _el;
  final String label;
  Object? _intervalId;
  var _frame = 0;

  static const _frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];

  void show() {
    jsu.setProperty(_el, 'style', 'display: inline; color: var(--text-muted); font-size: 0.85em');
    _intervalId = jsu.callMethod<Object>(jsu.globalThis, 'setInterval', [
      jsu.allowInterop(() {
        _frame = (_frame + 1) % _frames.length;
        setText(_el, '${_frames[_frame]}${label.isNotEmpty ? '  $label' : ''}');
      }),
      80,
    ]);
  }

  void hide() {
    if (_intervalId != null) {
      jsu.callMethod<void>(jsu.globalThis, 'clearInterval', [_intervalId]);
      _intervalId = null;
    }
    jsu.setProperty(_el, 'style', 'display: none');
  }
}

/// A layout context bound to a specific container element (row/column div).
/// Mirrors the subset of [ModalContext] methods needed for building nested layouts.
class LayoutContext {
  LayoutContext(this._el);

  final JSObject _el;

  JSObject createEl(String tag, {String? cls, String? text, String? style}) {
    final el = jsu.callMethod<JSObject>(_el, 'createEl', [tag]);
    if (cls != null) {
      jsu.setProperty(el, 'className', cls);
    }
    if (text != null) {
      setText(el, text);
    }
    if (style != null) {
      jsu.setProperty(el, 'style', style);
    }
    return el;
  }

  void spaceVertical({int px = 12}) {
    final el = createEl('div');
    jsu.setProperty(el, 'style', 'margin-top: ${px}px');
  }

  void spaceHorizontal({int px = 12}) {
    final el = createEl('span');
    jsu.setProperty(el, 'style', 'display: inline-block; margin-left: ${px}px');
  }

  void row(void Function(LayoutContext ctx) build, {String? cls}) {
    final el = createEl('div', cls: cls);
    jsu.setProperty(el, 'style', 'display: flex; flex-direction: row; align-items: center');
    build(LayoutContext(el));
  }

  void column(void Function(LayoutContext ctx) build, {String? cls}) {
    final el = createEl('div', cls: cls);
    jsu.setProperty(el, 'style', 'display: flex; flex-direction: column');
    build(LayoutContext(el));
  }
}
