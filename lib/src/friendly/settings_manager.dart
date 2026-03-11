import 'dart:async';

import '../obsidian/plugin_handle.dart';

/// Generic settings manager with type-safe JSON serialization.
///
/// Provides automatic persistence, caching, and reactive updates via Stream.
///
/// Example:
/// ```dart
/// final manager = SettingsManager<MySettings>(
///   plugin: plugin,
///   fromJson: MySettings.fromJson,
///   toJson: (s) => s.toJson(),
///   defaultSettings: MySettings.defaults(),
/// );
///
/// // Load settings
/// final settings = await manager.get();
///
/// // Save settings
/// await manager.save(settings.copyWith(value: newValue));
///
/// // React to changes
/// manager.changes.listen((newSettings) {
///   print('Updated: ${newSettings.value}');
/// });
/// ```
class SettingsManager<T> {
  SettingsManager({
    required this.plugin,
    required this.fromJson,
    required this.toJson,
    required this.defaultSettings,
  });

  final PluginHandle plugin;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T settings) toJson;
  final T defaultSettings;

  final _controller = StreamController<T>.broadcast();
  T? _cachedSettings;

  /// Stream of settings changes (emits on save).
  Stream<T> get changes => _controller.stream;

  /// Get current settings (uses cache or loads from disk).
  Future<T> get() async {
    final cached = _cachedSettings;
    if (cached != null) return cached;
    return load();
  }

  /// Load settings from disk (bypasses cache).
  Future<T> load() async {
    try {
      final data = await plugin.loadData();
      if (data == null) {
        _cachedSettings = defaultSettings;
        return defaultSettings;
      }

      // Convert to Map<String, dynamic>
      final json = (data as Map<Object?, Object?>).map(
        (k, v) => MapEntry(k.toString(), v),
      );

      _cachedSettings = fromJson(json);
      return _cachedSettings!;
    } on Exception catch (e) {
      // ignore: avoid_print
      print('Settings load error: $e. Using defaults.');
      _cachedSettings = defaultSettings;
      return defaultSettings;
    }
  }

  /// Save settings to disk and notify listeners.
  Future<void> save(T settings) async {
    try {
      final json = toJson(settings);
      await plugin.saveData(json);
      _cachedSettings = settings;
      _controller.add(settings); // Notify listeners
    } on Exception catch (e) {
      // ignore: avoid_print
      print('Settings save error: $e');
      rethrow;
    }
  }

  /// Update settings with a modifier function (atomic).
  ///
  /// Example:
  /// ```dart
  /// await manager.update((current) => current.copyWith(enabled: true));
  /// ```
  Future<void> update(T Function(T current) modifier) async {
    final current = await get();
    final updated = modifier(current);
    await save(updated);
  }

  /// Dispose stream controller.
  void dispose() {
    _controller.close();
  }
}
