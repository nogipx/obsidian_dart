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
      'out',
      defaultsTo: 'build/plugin',
      help: 'Output directory for built plugin files.',
    );

  final parsed = parser.parse(args);
  final pluginId = parsed['plugin-id'] as String;
  final outRoot = parsed['out'] as String;

  final packageDir = p.normalize(p.join(File(Platform.script.toFilePath()).parent.path, '..'));

  await buildManifest(
    packageDir: packageDir,
    pluginId: pluginId,
    outDir: p.join(packageDir, outRoot),
  );

  stdout.writeln('Generated manifest at ${p.join(packageDir, outRoot, pluginId, 'manifest.json')}');
}
