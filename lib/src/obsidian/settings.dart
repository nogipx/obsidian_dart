// ignore_for_file: deprecated_member_use
import 'dart:js_interop';
import 'dart:js_util' as jsu;

import 'common.dart';
import 'plugin_handle.dart';

/// Low-level wrapper for Obsidian's PluginSettingTab.
///
/// Provides direct access to the settings tab container and lifecycle methods.
class PluginSettingTabHandle {
  PluginSettingTabHandle._(this._settingTab, this.plugin);

  final JSObject _settingTab;
  final PluginHandle plugin;

  /// Get the container element for this settings tab.
  JSObject get containerEl => jsu.getProperty<JSObject>(_settingTab, 'containerEl');

  /// Display the settings tab (called by Obsidian when tab is opened).
  void display() => jsu.callMethod<void>(_settingTab, 'display', []);

  /// Hide the settings tab (called by Obsidian when tab is closed).
  void hide() => jsu.callMethod<void>(_settingTab, 'hide', []);

  /// Get the raw JS object (for advanced use cases).
  JSObject get raw => _settingTab;
}

/// Factory function to create a new PluginSettingTab.
///
/// Example:
/// ```dart
/// final settingTab = createSettingTab(plugin);
/// final container = settingTab.containerEl;
/// ```
PluginSettingTabHandle createSettingTab(
  PluginHandle plugin, {
  String? name,
  void Function()? onDisplay,
}) {
  final settingTabCtor = obsidianExport('PluginSettingTab');
  final settingTab = jsu.callConstructor<JSObject>(
    settingTabCtor,
    [plugin.app.raw, plugin.raw],
  );
  if (name != null) {
    jsu.setProperty(settingTab, 'name', name);
  }
  // Obsidian calls display() each time the settings tab is opened.
  jsu.setProperty(
    settingTab,
    'display',
    jsu.allowInterop(() => onDisplay?.call()),
  );
  return PluginSettingTabHandle._(settingTab, plugin);
}

/// Low-level wrapper for Obsidian's Setting component.
///
/// Provides fluent API for configuring setting UI elements.
class SettingHandle {
  SettingHandle(this._setting);

  final JSObject _setting;

  /// Set the name/title of this setting.
  SettingHandle setName(String name) {
    jsu.callMethod<JSObject>(_setting, 'setName', [name]);
    return this;
  }

  /// Set the description of this setting.
  SettingHandle setDesc(String desc) {
    jsu.callMethod<JSObject>(_setting, 'setDesc', [desc]);
    return this;
  }

  /// Add a text input component.
  SettingHandle addText(void Function(TextComponentHandle) cb) {
    jsu.callMethod<JSObject>(_setting, 'addText', [
      jsu.allowInterop((JSObject textComponent) {
        cb(TextComponentHandle(textComponent));
      }),
    ]);
    return this;
  }

  /// Add a toggle component.
  SettingHandle addToggle(void Function(ToggleComponentHandle) cb) {
    jsu.callMethod<JSObject>(_setting, 'addToggle', [
      jsu.allowInterop((JSObject toggleComponent) {
        cb(ToggleComponentHandle(toggleComponent));
      }),
    ]);
    return this;
  }

  /// Add a dropdown component.
  SettingHandle addDropdown(void Function(DropdownComponentHandle) cb) {
    jsu.callMethod<JSObject>(_setting, 'addDropdown', [
      jsu.allowInterop((JSObject dropdownComponent) {
        cb(DropdownComponentHandle(dropdownComponent));
      }),
    ]);
    return this;
  }

  /// Add a button component.
  SettingHandle addButton(void Function(ButtonComponentHandle) cb) {
    jsu.callMethod<JSObject>(_setting, 'addButton', [
      jsu.allowInterop((JSObject buttonComponent) {
        cb(ButtonComponentHandle(buttonComponent));
      }),
    ]);
    return this;
  }

  /// Get the raw JS object (for advanced use cases).
  JSObject get raw => _setting;
}

/// Factory function to create a new Setting.
///
/// Example:
/// ```dart
/// final setting = createSetting(containerEl)
///   ..setName('My Setting')
///   ..setDesc('Description here')
///   ..addToggle((toggle) {
///     toggle.setValue(true).onChange((value) => print(value));
///   });
/// ```
SettingHandle createSetting(JSObject containerEl) {
  final settingCtor = obsidianExport('Setting');
  return SettingHandle(jsu.callConstructor<JSObject>(settingCtor, [containerEl]));
}

/// Wrapper for Obsidian's TextComponent.
class TextComponentHandle {
  TextComponentHandle(this._component);

  final JSObject _component;

  /// Set the placeholder text.
  TextComponentHandle setPlaceholder(String placeholder) {
    jsu.callMethod<JSObject>(_component, 'setPlaceholder', [placeholder]);
    return this;
  }

  /// Set the current value.
  TextComponentHandle setValue(String value) {
    jsu.callMethod<JSObject>(_component, 'setValue', [value]);
    return this;
  }

  /// Register a callback for value changes.
  TextComponentHandle onChange(void Function(String) callback) {
    jsu.callMethod<JSObject>(_component, 'onChange', [
      jsu.allowInterop((String value) => callback(value)),
    ]);
    return this;
  }

  /// Get the raw JS object.
  JSObject get raw => _component;
}

/// Wrapper for Obsidian's ToggleComponent.
class ToggleComponentHandle {
  ToggleComponentHandle(this._component);

  final JSObject _component;

  /// Set the current value (checked/unchecked).
  ToggleComponentHandle setValue(bool value) {
    jsu.callMethod<JSObject>(_component, 'setValue', [value]);
    return this;
  }

  /// Register a callback for value changes.
  ToggleComponentHandle onChange(void Function(bool) callback) {
    jsu.callMethod<JSObject>(_component, 'onChange', [
      jsu.allowInterop((bool value) => callback(value)),
    ]);
    return this;
  }

  /// Get the raw JS object.
  JSObject get raw => _component;
}

/// Wrapper for Obsidian's DropdownComponent.
class DropdownComponentHandle {
  DropdownComponentHandle(this._component);

  final JSObject _component;

  /// Add a single option.
  DropdownComponentHandle addOption(String value, String display) {
    jsu.callMethod<JSObject>(_component, 'addOption', [value, display]);
    return this;
  }

  /// Add multiple options from a map (value -> display text).
  DropdownComponentHandle addOptions(Map<String, String> options) {
    jsu.callMethod<JSObject>(_component, 'addOptions', [jsu.jsify(options)]);
    return this;
  }

  /// Set the currently selected value.
  DropdownComponentHandle setValue(String value) {
    jsu.callMethod<JSObject>(_component, 'setValue', [value]);
    return this;
  }

  /// Register a callback for value changes.
  DropdownComponentHandle onChange(void Function(String) callback) {
    jsu.callMethod<JSObject>(_component, 'onChange', [
      jsu.allowInterop((String value) => callback(value)),
    ]);
    return this;
  }

  /// Get the raw JS object.
  JSObject get raw => _component;
}

/// Wrapper for Obsidian's ButtonComponent.
class ButtonComponentHandle {
  ButtonComponentHandle(this._component);

  final JSObject _component;

  /// Set the button text.
  ButtonComponentHandle setButtonText(String text) {
    jsu.callMethod<JSObject>(_component, 'setButtonText', [text]);
    return this;
  }

  /// Register a click handler.
  ButtonComponentHandle onClick(void Function() callback) {
    jsu.callMethod<JSObject>(_component, 'onClick', [
      jsu.allowInterop((JSAny? _) => callback()),
    ]);
    return this;
  }

  /// Set this button as a primary/CTA button (different styling).
  ButtonComponentHandle setCta() {
    jsu.callMethod<JSObject>(_component, 'setCta', []);
    return this;
  }

  /// Get the raw JS object.
  JSObject get raw => _component;
}
