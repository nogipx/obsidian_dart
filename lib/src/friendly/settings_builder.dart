import '../obsidian/plugin_handle.dart';
import '../obsidian/settings.dart';
import 'settings_manager.dart';
import 'settings_tab.dart';

/// Declarative settings tab builder with type-safe storage integration.
///
/// Automatically persists changes to settings using [SettingsManager].
///
/// Example:
/// ```dart
/// final builder = SettingsBuilder(plugin: plugin, manager: settingsManager);
/// await builder.build((ctx) {
///   ctx.section('General');
///   ctx.toggle(
///     name: 'Enable sync',
///     description: 'Auto sync on startup',
///     getValue: (s) => s.enableSync,
///     setValue: (s, v) => s.copyWith(enableSync: v),
///   );
/// });
/// ```
class SettingsBuilder<T> {
  SettingsBuilder({
    required this.plugin,
    required this.manager,
  });

  final PluginHandle plugin;
  final SettingsManager<T> manager;

  /// Build settings UI from declarative configuration.
  Future<void> build(
      void Function(SettingsBuilderContext<T> ctx) builder) async {
    final settings = await manager.get();
    final tab = PluginSettingsTab(plugin);
    final ctx = SettingsBuilderContext._(tab, manager, settings);
    builder(ctx);
    tab.show();
  }
}

/// Context for building settings UI with automatic persistence.
///
/// Use the methods on this context to add settings controls. All changes
/// are automatically persisted via the [SettingsManager].
class SettingsBuilderContext<T> {
  SettingsBuilderContext._(this._tab, this._manager, this._currentSettings);

  final PluginSettingsTab _tab;
  final SettingsManager<T> _manager;
  final T _currentSettings;

  /// Add section header.
  ///
  /// Example:
  /// ```dart
  /// ctx.section('General Settings');
  /// ```
  void section(String title) {
    _tab.addSection(title);
  }

  /// Add toggle with automatic persistence.
  ///
  /// Example:
  /// ```dart
  /// ctx.toggle(
  ///   name: 'Dark mode',
  ///   description: 'Enable dark theme',
  ///   getValue: (s) => s.darkMode,
  ///   setValue: (s, v) => s.copyWith(darkMode: v),
  /// );
  /// ```
  void toggle({
    required String name,
    required String description,
    required bool Function(T) getValue,
    required T Function(T settings, bool value) setValue,
  }) {
    final initialValue = getValue(_currentSettings);
    _tab.addToggle(
      name: name,
      description: description,
      initialValue: initialValue,
      onChange: (value) async {
        await _manager.update((current) => setValue(current, value));
      },
    );
  }

  /// Add text input with automatic persistence.
  ///
  /// Example:
  /// ```dart
  /// ctx.text(
  ///   name: 'API Key',
  ///   description: 'Your API key',
  ///   placeholder: 'Enter key...',
  ///   getValue: (s) => s.apiKey,
  ///   setValue: (s, v) => s.copyWith(apiKey: v),
  /// );
  /// ```
  void text({
    required String name,
    required String description,
    required String Function(T) getValue,
    required T Function(T settings, String value) setValue,
    String? placeholder,
  }) {
    final initialValue = getValue(_currentSettings);
    _tab.addText(
      name: name,
      description: description,
      initialValue: initialValue,
      placeholder: placeholder,
      onChange: (value) async {
        await _manager.update((current) => setValue(current, value));
      },
    );
  }

  /// Add dropdown with automatic persistence.
  ///
  /// Example:
  /// ```dart
  /// ctx.dropdown(
  ///   name: 'Theme',
  ///   description: 'Choose theme',
  ///   options: {'auto': 'Auto', 'light': 'Light', 'dark': 'Dark'},
  ///   getValue: (s) => s.theme,
  ///   setValue: (s, v) => s.copyWith(theme: v),
  /// );
  /// ```
  void dropdown({
    required String name,
    required String description,
    required Map<String, String> options,
    required String Function(T) getValue,
    required T Function(T settings, String value) setValue,
  }) {
    final initialValue = getValue(_currentSettings);
    _tab.addDropdown(
      name: name,
      description: description,
      options: options,
      initialValue: initialValue,
      onChange: (value) async {
        await _manager.update((current) => setValue(current, value));
      },
    );
  }

  /// Add button with access to current settings.
  ///
  /// Example:
  /// ```dart
  /// ctx.button(
  ///   name: 'Reset',
  ///   description: 'Reset to defaults',
  ///   buttonText: 'Reset',
  ///   primary: true,
  ///   onClick: (current) async {
  ///     await manager.save(MySettings.defaults());
  ///   },
  /// );
  /// ```
  void button({
    required String name,
    required String description,
    required String buttonText,
    required Future<void> Function(T current) onClick,
    bool primary = false,
  }) {
    _tab.addButton(
      name: name,
      description: description,
      buttonText: buttonText,
      primary: primary,
      onClick: () async {
        final current = await _manager.get();
        await onClick(current);
      },
    );
  }

  /// Add custom setting with raw access.
  ///
  /// Use this for advanced scenarios not covered by the other methods.
  ///
  /// Example:
  /// ```dart
  /// ctx.custom((setting, current) {
  ///   setting
  ///     ..setName('Advanced')
  ///     ..addText((text) {
  ///       text.setValue(current.advancedField);
  ///     });
  /// });
  /// ```
  void custom(void Function(SettingHandle, T current) builder) {
    _tab.addCustom((setting) {
      builder(setting, _currentSettings);
    });
  }
}
