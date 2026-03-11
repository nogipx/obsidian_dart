import 'dart:async';
import 'dart:js_interop';
// ignore_for_file: deprecated_member_use
import 'dart:js_util' as jsu;

import 'common.dart';

/// Thin wrapper around Obsidian's SecretStorage (Obsidian 1.11.4+).
///
/// The underlying API surface is still evolving, so this wrapper:
/// - probes for several method names (`getSecret`/`get`, `setSecret`/`set`, etc.);
/// - accepts both synchronous returns and Promises;
/// - gracefully returns defaults when the host doesn't expose secret storage.
class SecretStorageHandle {
  SecretStorageHandle(this.raw);

  final JSObject raw;

  bool get isAvailable => _hasAny(const [
    'getSecret',
    'get',
    'setSecret',
    'set',
  ]);

  /// Reads a secret value by name. Returns `null` when missing or unsupported.
  Future<String?> getSecret(String name) async {
    final value = await _invokeFirst<Object?>(
      const ['getSecret', 'get'],
      [name],
    );
    final dartified = jsu.dartify(value);
    return dartified?.toString();
  }

  /// Writes or overwrites a secret value. No-op if the API isn't present.
  Future<void> setSecret(String name, String secret) async {
    await _invokeFirst<void>(
      const ['setSecret', 'set', 'putSecret', 'saveSecret'],
      [name, secret],
    );
  }

  /// Deletes a secret value if supported.
  Future<void> deleteSecret(String name) async {
    await _invokeFirst<void>(
      const ['deleteSecret', 'removeSecret', 'delete', 'remove'],
      [name],
    );
  }

  /// Returns the list of known secret names (best-effort; empty on failure).
  Future<List<String>> listSecrets() async {
    final value = await _invokeFirst<Object?>(
      const ['listSecrets', 'keys', 'list'],
      const [],
    );
    final dartified = jsu.dartify(value);
    if (dartified is List) {
      return dartified.map((e) => e.toString()).toList();
    }
    if (dartified is Map) {
      return dartified.keys.map((e) => e.toString()).toList();
    }
    return const [];
  }

  /// Access raw SecretComponent constructor if present.
  ///
  /// Example usage:
  /// ```
  /// final secretInput = secretStorage.createComponent(containerEl);
  /// ```
  JSObject? createComponent(JSObject containerEl) {
    if (!jsu.hasProperty(obsidianModule(), 'SecretComponent')) {
      return null;
    }
    final ctor = obsidianExport('SecretComponent');
    return jsu.callConstructor<JSObject>(ctor, [containerEl]);
  }

  bool _hasAny(List<String> names) => names.any((name) => jsu.hasProperty(raw, name));

  Future<T?> _invokeFirst<T>(List<String> names, List<Object?> args) async {
    for (final name in names) {
      if (!jsu.hasProperty(raw, name)) {
        continue;
      }
      final result = jsu.callMethod<Object?>(raw, name, args);
      return (await _awaitMaybe(result)) as T?;
    }
    return null;
  }

  Future<Object?> _awaitMaybe(Object? value) {
    if (value is JSObject && jsu.hasProperty(value, 'then')) {
      return jsu.promiseToFuture<Object?>(value);
    }
    return Future<Object?>.value(value);
  }
}
