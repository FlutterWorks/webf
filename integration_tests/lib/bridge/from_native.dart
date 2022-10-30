/*
 * Copyright (C) 2020-present The WebF authors. All rights reserved.
 */
// ignore_for_file: unused_import, undefined_function

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'dart:ui';

import 'package:ffi/ffi.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:test/test.dart';
import 'package:webf/bridge.dart';
import 'package:webf/dom.dart';
import 'package:webf/launcher.dart';

import 'match_snapshots.dart';
import 'test_input.dart';

// Steps for using dart:ffi to call a Dart function from C:
// 1. Import dart:ffi.
// 2. Create a typedef with the FFI type signature of the Dart function.
// 3. Create a typedef for the variable that you’ll use when calling the Dart function.
// 4. Open the dynamic library that register in the C.
// 5. Get a reference to the C function, and put it into a variable.
// 6. Call from C.

typedef NativeJSError = Void Function(Int32 contextId, Pointer<Utf8>);
typedef JSErrorListener = void Function(String);

List<JSErrorListener> _listenerList = List.filled(10, (String string) {
  throw new Exception('unimplemented JS ErrorListener');
});

void addJSErrorListener(int contextId, JSErrorListener listener) {
  _listenerList[contextId] = listener;
}

void _onJSError(int contextId, Pointer<Utf8> charStr) {
  String msg = (charStr).toDartString();
  _listenerList[contextId](msg);
}

final Pointer<NativeFunction<NativeJSError>> _nativeOnJsError =
    Pointer.fromFunction(_onJSError);

typedef NativeMatchImageSnapshotCallback = Void Function(
    Pointer<Void> callbackContext, Int32 contextId, Int8, Pointer<Utf8>);
typedef DartMatchImageSnapshotCallback = void Function(
    Pointer<Void> callbackContext, int contextId, int, Pointer<Utf8>);
typedef NativeMatchImageSnapshot = Void Function(
    Pointer<Void> callbackContext,
    Int32 contextId,
    Pointer<Uint8>,
    Int32,
    Pointer<NativeString>,
    Pointer<NativeFunction<NativeMatchImageSnapshotCallback>>);

void _matchImageSnapshot(
    Pointer<Void> callbackContext,
    int contextId,
    Pointer<Uint8> bytes,
    int size,
    Pointer<NativeString> snapshotNamePtr,
    Pointer<NativeFunction<NativeMatchImageSnapshotCallback>> pointer) {
  DartMatchImageSnapshotCallback callback = pointer.asFunction();
  String filename = nativeStringToString(snapshotNamePtr);
  matchImageSnapshot(bytes.asTypedList(size), filename).then((value) {
    callback(callbackContext, contextId, value ? 1 : 0, nullptr);
  }).catchError((e, stack) {
    String errmsg = '$e\n$stack';
    callback(callbackContext, contextId, 0, errmsg.toNativeUtf8());
  });
}

final Pointer<NativeFunction<NativeMatchImageSnapshot>>
    _nativeMatchImageSnapshot = Pointer.fromFunction(_matchImageSnapshot);

typedef NativeEnvironment = Pointer<Utf8> Function();
typedef DartEnvironment = Pointer<Utf8> Function();

Pointer<Utf8> _environment() {
  return (jsonEncode(Platform.environment)).toNativeUtf8();
}

final Pointer<NativeFunction<NativeEnvironment>> _nativeEnvironment =
    Pointer.fromFunction(_environment);

typedef NativeSimulatePointer = Void Function(
    Pointer<MousePointer>, Int32 length, Int32 pointer);
typedef NativeSimulateInputText = Void Function(Pointer<NativeString>);

PointerChange _getPointerChange(double change) {
  return PointerChange.values[change.toInt()];
}

class MousePointer extends Struct {
  @Int32()
  external int contextId;

  @Double()
  external double x;

  @Double()
  external double y;

  @Double()
  external double change;
}

void _simulatePointer(
    Pointer<MousePointer> mousePointerList, int length, int pointer) async {
  List<PointerData> data = [];

  for (int i = 0; i < length; i++) {
    double x = mousePointerList.elementAt(i).ref.x;
    double y = mousePointerList.elementAt(i).ref.y;
    double lastX = i > 0 ? mousePointerList.elementAt(i - 1).ref.x : 0;
    double lastY = i > 0 ? mousePointerList.elementAt(i - 1).ref.y : 0;

    double change = mousePointerList.elementAt(i).ref.change;
    print('get pointer data ${i} , ${x} ${y},  ${_getPointerChange(change)}');
    if (i == 0) {
      PointerEvent addPointer = PointerAddedEvent(position: Offset(x, y));
      GestureBinding.instance.handlePointerEvent(addPointer);
    }
    switch (_getPointerChange(change)) {
      case PointerChange.add:
        PointerAddedEvent addEvent = PointerAddedEvent(
            kind: PointerDeviceKind.mouse, position: Offset(x, y));
        GestureBinding.instance.handlePointerEvent(addEvent);
        break;
      case PointerChange.remove:
        PointerRemovedEvent removeEvent = PointerRemovedEvent(
            kind: PointerDeviceKind.mouse, position: Offset(x, y));
        GestureBinding.instance.handlePointerEvent(removeEvent);
        break;
      case PointerChange.down:
        PointerDownEvent downEvent = PointerDownEvent(
            kind: PointerDeviceKind.mouse, position: Offset(x, y));
        GestureBinding.instance.handlePointerEvent(downEvent);
        break;
      case PointerChange.move:
      case PointerChange.cancel:
        await Future.delayed(const Duration(milliseconds: 6));
        print(
            'get move ${x} ${y} , ${lastX} ${lastY},${x - lastX} ${y - lastY}');
        PointerMoveEvent moveEvent = PointerMoveEvent(
            kind: PointerDeviceKind.mouse,
            position: Offset(x, y),
            delta: Offset(lastX - x, lastY - y));
        GestureBinding.instance.handlePointerEvent(moveEvent);
        break;
      case PointerChange.up:
        PointerUpEvent upEvent = PointerUpEvent(
            kind: PointerDeviceKind.mouse, position: Offset(x, y));
        GestureBinding.instance.handlePointerEvent(upEvent);
        break;
      default:
        break;
    }
  }

  malloc.free(mousePointerList);
}

final Pointer<NativeFunction<NativeSimulatePointer>> _nativeSimulatePointer =
    Pointer.fromFunction(_simulatePointer);
late TestTextInput testTextInput;

void _simulateInputText(Pointer<NativeString> nativeChars) {
  String text = nativeStringToString(nativeChars);
  testTextInput.enterText(text);
}

final Pointer<NativeFunction<NativeSimulateInputText>>
    _nativeSimulateInputText = Pointer.fromFunction(_simulateInputText);

final List<int> _dartNativeMethods = [
  _nativeOnJsError.address,
  _nativeMatchImageSnapshot.address,
  _nativeEnvironment.address,
  _nativeSimulatePointer.address,
  _nativeSimulateInputText.address
];

typedef Native_RegisterTestEnvDartMethods = Void Function(
    Int32 contextId, Pointer<Uint64> methodBytes, Int32 length);
typedef Dart_RegisterTestEnvDartMethods = void Function(
    int contextId, Pointer<Uint64> methodBytes, int length);

final Dart_RegisterTestEnvDartMethods _registerTestEnvDartMethods =
    WebFDynamicLibrary.ref
        .lookup<NativeFunction<Native_RegisterTestEnvDartMethods>>(
            'registerTestEnvDartMethods')
        .asFunction();

void registerDartTestMethodsToCpp(int contextId) {
  Pointer<Uint64> bytes =
      malloc.allocate<Uint64>(sizeOf<Uint64>() * _dartNativeMethods.length);
  Uint64List nativeMethodList = bytes.asTypedList(_dartNativeMethods.length);
  nativeMethodList.setAll(0, _dartNativeMethods);
  _registerTestEnvDartMethods(contextId, bytes, _dartNativeMethods.length);
}
