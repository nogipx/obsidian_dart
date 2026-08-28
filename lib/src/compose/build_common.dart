import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Compile a Dart entrypoint to JS and wrap it into `main.js` that Obsidian can load.
///
/// The output folder structure becomes:
/// `<outDir>/<pluginId>/main.js`
/// (intermediate `dart_app.js` and its side files are removed).
Future<void> buildPlugin({
  required String packageDir,
  required String pluginId,
  required String entry,
  required String outDir,
  required String pluginClass,
  String outFilename = 'main.js',
  String? dartBin,
  bool useFvm = true,
  bool release = true,
  Map<String, String> defines = const {},
}) async {
  final absPackageDir = p.normalize(packageDir);
  final pluginOut = Directory(p.join(outDir, pluginId))
    ..createSync(recursive: true);

  final dartJsPath = p.join(pluginOut.path, 'dart_app.js');

  await _runProcess(
    useFvm ? 'fvm' : (dartBin ?? 'dart'),
    [
      if (useFvm) 'dart',
      'compile',
      'js',
      entry,
      '-o',
      dartJsPath,
      if (release) '-O4' else '-O1',
      for (final e in defines.entries) '-D${e.key}=${e.value}',
    ],
    workingDirectory: absPackageDir,
    name: 'dart2js',
  );

  final dartJs = File(dartJsPath);
  if (!dartJs.existsSync()) {
    throw FileSystemException('dart2js output missing', dartJsPath);
  }

  final dartJsBody = dartJs.readAsStringSync().replaceAll(
        RegExp(r'\n?//# sourceMappingURL=.*'),
        '',
      );

  final main = StringBuffer()
    ..writeln("const { Plugin } = require('obsidian');")
    ..writeln('globalThis.require = require;')
    ..writeln()
    ..writeln(dartJsBody.trim())
    ..writeln()
    // `globalThis._dartObsidianPlugin` is a rendezvous slot: evaluating this
    // bundle runs Dart `main()`, which publishes THAT evaluation's hooks there.
    // The slot is therefore captured once, here at module scope — the same
    // synchronous turn that published it, so nothing can re-point it in
    // between. Never read it per call.
    //
    // Reading it inside onunload was a real defect. A reload re-evaluates the
    // bundle, so the slot already pointed at the incoming instance by the time
    // the outgoing one was told to unload: the outgoing instance ran the
    // INCOMING instance's teardown — gutting the plugin that had just started —
    // while its own settings tab, status-bar items and listeners were never
    // released. Every reload leaked one instance's UI and broke the live one, a
    // cascade rather than a one-off, since each attempt to fix it by toggling
    // the plugin added another orphan.
    //
    // Capturing in the constructor would also have worked for Obsidian, which
    // constructs right after evaluating. Module scope additionally survives a
    // host that evaluates several bundles before constructing any of them.
    ..writeln('const __dartImpl = globalThis._dartObsidianPlugin;')
    ..writeln('module.exports = class $pluginClass extends Plugin {')
    ..writeln('  async onload() {')
    ..writeln('    if (__dartImpl?.onload) return await __dartImpl.onload(this);')
    ..writeln('  }')
    ..writeln('  onunload() {')
    ..writeln('    if (__dartImpl?.onunload) return __dartImpl.onunload(this);')
    ..writeln('  }')
    ..writeln('};')
    ..writeln();

  File(p.join(pluginOut.path, outFilename)).writeAsStringSync(main.toString());

  // Clean up intermediate artifacts.
  for (final suffix in const ['js', 'js.map', 'js.deps']) {
    final f = File(p.join(pluginOut.path, 'dart_app.$suffix'));
    if (f.existsSync()) {
      f.deleteSync();
    }
  }
}

/// Generate `manifest.json` for the plugin based on `pubspec.yaml`.
Future<void> buildManifest({
  required String packageDir,
  required String pluginId,
  required String outDir,
  Map<String, Object?> Function({required Map<String, Object?> base})?
      transform,
}) async {
  final absPackageDir = p.normalize(packageDir);
  final pluginOut = Directory(p.join(outDir, pluginId))
    ..createSync(recursive: true);

  final manifest = await _defaultManifest(
    pluginId: pluginId,
    packageDir: absPackageDir,
  );
  final result = transform != null ? transform(base: manifest) : manifest;

  File(p.join(pluginOut.path, 'manifest.json'))
      .writeAsStringSync(_prettyJson(result));
}

Future<Map<String, Object?>> _defaultManifest({
  required String pluginId,
  required String packageDir,
}) async {
  final pubspec = File(p.join(packageDir, 'pubspec.yaml')).readAsStringSync();
  final version = _field(pubspec, 'version');
  final description = _field(pubspec, 'description');
  final name = _field(pubspec, 'name');

  return <String, Object?>{
    'id': pluginId,
    'name': _titleCase(name.replaceAll('_', ' ')),
    'version': version,
    'minAppVersion': '1.7.0',
    'description': description,
    'author': Platform.environment['USER'] ?? 'unknown',
    'authorUrl': '',
    'fundingUrl': '',
    'isDesktopOnly': false,
    'main': 'main.js',
  };
}

String _field(String text, String key) {
  final regex = RegExp('^$key:\\s*(.+)\$', multiLine: true);
  final match = regex.firstMatch(text);
  return match?.group(1)?.trim().replaceAll('"', '') ?? '';
}

String _titleCase(String value) => value
    .split(RegExp(r'[_\\s-]+'))
    .where((p) => p.isNotEmpty)
    .map((p) => p[0].toUpperCase() + p.substring(1))
    .join(' ');

String _prettyJson(Map<String, Object?> json) =>
    const JsonEncoder.withIndent('  ').convert(json);

Future<void> _runProcess(
  String bin,
  List<String> args, {
  required String workingDirectory,
  required String name,
}) async {
  stdout.writeln('> $name (${[bin, ...args].join(' ')})');
  final result = await Process.run(
    bin,
    args,
    workingDirectory: workingDirectory,
  );
  if (result.stdout is String && (result.stdout as String).isNotEmpty) {
    stdout.write(result.stdout);
  }
  if (result.stderr is String && (result.stderr as String).isNotEmpty) {
    stderr.write(result.stderr);
  }
  if (result.exitCode != 0) {
    throw ProcessException(
      bin,
      args,
      'Failed with exit code ${result.exitCode}',
    );
  }
}
