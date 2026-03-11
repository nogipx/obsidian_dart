import 'dart:io';

import 'package:args/args.dart';
import 'package:obsidian_dart/src/compose/build_common.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'plugin-id',
      defaultsTo: 'dart_obsidian',
      help: 'Plugin id (folder name for output).',
    )
    ..addOption(
      'entry',
      defaultsTo: 'bin/plugin_entry.dart',
      help: 'Path to Dart entrypoint (relative to package dir or absolute).',
    )
    ..addOption(
      'out',
      defaultsTo: 'build/plugin',
      help: 'Output directory for built plugin files.',
    )
    ..addOption(
      'dart-bin',
      help: 'Optional path to dart executable; defaults to PATH lookup.',
    )
    ..addFlag(
      'fvm',
      defaultsTo: true,
      help: 'Use fvm (runs "fvm dart compile js ..."). Overrides --dart-bin.',
    )
    ..addFlag(
      'release',
      defaultsTo: true,
      help: 'Use dart2js -O4 (default true).',
    )
    ..addOption(
      'plugin-class',
      defaultsTo: 'DartBackedPlugin',
      help: 'JS class name exported from main.js (extends Obsidian Plugin).',
    );

  final parsed = parser.parse(args);
  final pluginId = parsed['plugin-id'] as String;
  final entryOpt = parsed['entry'] as String;
  final outRoot = parsed['out'] as String;
  final dartBinOpt = parsed['dart-bin'] as String?;
  final useFvm = parsed['fvm'] as bool;
  final release = parsed['release'] as bool;
  final pluginClass = parsed['plugin-class'] as String;

  final packageDir = p.normalize(p.join(File(Platform.script.toFilePath()).parent.path, '..'));
  final entry = p.isAbsolute(entryOpt) ? entryOpt : p.normalize(p.join(packageDir, entryOpt));
  if (!File(entry).existsSync()) {
    stderr.writeln('Entry file not found: $entry');
    exitCode = 64;
    return;
  }

  await buildPlugin(
    packageDir: packageDir,
    pluginId: pluginId,
    entry: entry,
    outDir: p.join(packageDir, outRoot),
    pluginClass: pluginClass,
    dartBin: dartBinOpt,
    useFvm: useFvm,
    release: release,
  );

  stdout
    ..writeln('Built plugin to ${p.join(packageDir, outRoot, pluginId)}')
    ..writeln(
      'Manifest is not generated here. Run "dart run obsidian_dart:obsidian_manifest" if needed.',
    )
    ..writeln('Copy this folder to <vault>/.obsidian/plugins/$pluginId/');
}
