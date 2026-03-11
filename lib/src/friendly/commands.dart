import 'dart:async';

import 'package:obsidian_dart/obsidian_dart.dart';

/// Tiny DSL for commands.
class Commands {
  Commands(this.plugin);
  final PluginHandle plugin;

  void add(String id, String name, {FutureOr<void> Function()? run}) {
    plugin.addCommand(id: id, name: name, callback: run);
  }
}
