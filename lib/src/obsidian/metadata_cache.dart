import 'dart:js_interop';
// ignore_for_file: deprecated_member_use
import 'dart:js_util' as jsu;

import 'types.dart';

class MetadataCacheHandle {
  MetadataCacheHandle(this._cache);
  final JSObject _cache;

  JSObject? getFileCache(TFileHandle file) =>
      jsu.callMethod<JSObject?>(_cache, 'getFileCache', [file.raw]);

  JSObject? getCache(String path) =>
      jsu.callMethod<JSObject?>(_cache, 'getCache', [path]);

  JSObject on(String event, JSFunction handler) =>
      jsu.callMethod<JSObject>(_cache, 'on', [event, handler]);
}
