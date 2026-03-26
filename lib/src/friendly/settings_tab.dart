// ignore_for_file: deprecated_member_use
import 'dart:js_interop';
import 'dart:js_util' as jsu;

import '../obsidian/plugin_handle.dart';
import '../obsidian/settings.dart';

/// High-level settings tab builder with Flutter-style fluent API.
///
/// Provides a convenient way to build settings UI using method chaining.
///
/// Example:
/// ```dart
/// PluginSettingsTab(plugin)
///   ..addSection('General')
///   ..addToggle(
///     name: 'Enable feature',
///     description: 'Turn on this feature',
///     initialValue: true,
///     onChange: (value) async {
///       await manager.save(settings.copyWith(enabled: value));
///     },
///   )
///   ..show();
/// ```
class PluginSettingsTab {
  /// [onDisplay] is called every time Obsidian opens this settings tab.
  /// The tab's [containerEl] is cleared before calling [onDisplay], so the
  /// builder always starts with an empty container.
  PluginSettingsTab(this.plugin,
      {String? name,
      void Function(PluginSettingsTab)? onDisplay,
      Future<void> Function(PluginSettingsTab)? onDisplayAsync}) {
    _onDisplay = onDisplay;
    _onDisplayAsync = onDisplayAsync;
    _tabHandle =
        createSettingTab(plugin, name: name, onDisplay: _handleDisplay);
  }

  final PluginHandle plugin;
  late final PluginSettingTabHandle _tabHandle;
  void Function(PluginSettingsTab)? _onDisplay;
  Future<void> Function(PluginSettingsTab)? _onDisplayAsync;

  void _handleDisplay() {
    jsu.callMethod<void>(containerEl, 'empty', []);
    _onDisplay?.call(this);
    _onDisplayAsync?.call(this);
  }

  /// Get the container element for adding custom UI.
  JSObject get containerEl => _tabHandle.containerEl;

  /// Add a section header (h2 element).
  PluginSettingsTab addSection(String title) {
    jsu.callMethod<JSObject>(
      containerEl,
      'createEl',
      [
        'h2',
        jsu.jsify({'text': title}),
      ],
    );
    return this;
  }

  /// Add a toggle setting.
  ///
  /// Example:
  /// ```dart
  /// tab.addToggle(
  ///   name: 'Dark mode',
  ///   description: 'Enable dark theme',
  ///   initialValue: false,
  ///   onChange: (enabled) => print('Dark mode: $enabled'),
  /// );
  /// ```
  PluginSettingsTab addToggle({
    required String name,
    required String description,
    required bool initialValue,
    required void Function(bool) onChange,
  }) {
    createSetting(containerEl)
      ..setName(name)
      ..setDesc(description)
      ..addToggle((toggle) {
        toggle
          ..setValue(initialValue)
          ..onChange(onChange);
      });
    return this;
  }

  /// Add a text input setting.
  ///
  /// Example:
  /// ```dart
  /// tab.addText(
  ///   name: 'API Key',
  ///   description: 'Your API key',
  ///   initialValue: '',
  ///   placeholder: 'Enter API key...',
  ///   onChange: (value) => print('API Key: $value'),
  /// );
  /// ```
  PluginSettingsTab addText({
    required String name,
    required String description,
    required String initialValue,
    required void Function(String) onChange,
    String? placeholder,
  }) {
    createSetting(containerEl)
      ..setName(name)
      ..setDesc(description)
      ..addText((text) {
        text
          ..setValue(initialValue)
          ..onChange(onChange);
        if (placeholder != null) {
          text.setPlaceholder(placeholder);
        }
      });
    return this;
  }

  /// Add a dropdown setting.
  ///
  /// Example:
  /// ```dart
  /// tab.addDropdown(
  ///   name: 'Theme',
  ///   description: 'Choose theme',
  ///   options: {'auto': 'Auto', 'light': 'Light', 'dark': 'Dark'},
  ///   initialValue: 'auto',
  ///   onChange: (value) => print('Theme: $value'),
  /// );
  /// ```
  PluginSettingsTab addDropdown({
    required String name,
    required String description,
    required Map<String, String> options,
    required String initialValue,
    required void Function(String) onChange,
  }) {
    createSetting(containerEl)
      ..setName(name)
      ..setDesc(description)
      ..addDropdown((dropdown) {
        dropdown
          ..addOptions(options)
          ..setValue(initialValue)
          ..onChange(onChange);
      });
    return this;
  }

  /// Add a button setting.
  ///
  /// Example:
  /// ```dart
  /// tab.addButton(
  ///   name: 'Reset',
  ///   description: 'Reset to defaults',
  ///   buttonText: 'Reset',
  ///   primary: true,
  ///   onClick: () => print('Reset clicked'),
  /// );
  /// ```
  PluginSettingsTab addButton({
    required String name,
    required String description,
    required String buttonText,
    required void Function() onClick,
    bool primary = false,
  }) {
    createSetting(containerEl)
      ..setName(name)
      ..setDesc(description)
      ..addButton((button) {
        button
          ..setButtonText(buttonText)
          ..onClick(onClick);
        if (primary) {
          button.setCta(); // Primary button style
        }
      });
    return this;
  }

  /// Add custom setting with full control over SettingHandle.
  ///
  /// Use this for advanced scenarios not covered by the other methods.
  ///
  /// Example:
  /// ```dart
  /// tab.addCustom((setting) {
  ///   setting
  ///     ..setName('Advanced')
  ///     ..addText((text) { /* custom logic */ });
  /// });
  /// ```
  PluginSettingsTab addCustom(void Function(SettingHandle) builder) {
    final setting = createSetting(containerEl);
    builder(setting);
    return this;
  }

  /// Display the settings tab.
  void show() {
    _tabHandle.display();
  }

  /// Hide the settings tab.
  void hide() {
    _tabHandle.hide();
  }

  /// Get the raw handle (for advanced use cases).
  PluginSettingTabHandle get handle => _tabHandle;
}
