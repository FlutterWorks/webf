/*
 * Copyright (C) 2019-2022 The Kraken authors. All rights reserved.
 * Copyright (C) 2022-present The WebF authors. All rights reserved.
 */

import 'dart:async';
import 'dart:ffi';
import 'dart:ui';
import 'dart:convert' as convert;

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:webf/bridge.dart';
import 'package:webf/css.dart';
import 'package:webf/foundation.dart';
import 'package:webf/rendering.dart';
import 'package:webf/src/svg/rendering/container.dart';
import 'package:webf/src/svg/rendering/empty.dart';
import 'package:webf/src/svg/rendering/path.dart';
import 'package:webf/src/svg/rendering/rect.dart';
import 'package:webf/src/svg/rendering/root.dart';
import 'package:webf/svg.dart';

import '../../dom.dart';
import '../bridge/native_gumbo.dart';

class BoxFitImageKey {
  const BoxFitImageKey({
    required this.url,
    this.configuration,
  });

  final Uri url;
  final ImageConfiguration? configuration;

  @override
  bool operator ==(Object other) {
    return other is BoxFitImageKey && other.url == url && other.configuration == configuration;
  }

  @override
  int get hashCode => Object.hash(configuration, url);

  @override
  String toString() => 'BoxFitImageKey($url, $configuration)';
}

class BotFixImageStreamListener extends ImageStreamListener {
  final OnImageLoad? onLoad;
  BotFixImageStreamListener(super.onImage, {
    super.onChunk,
    super.onError,
    this.onLoad
  });
}

class BoxFitImageStreamExtraListener {

}

class BoxFixImageStream extends ImageStream {
  @override
  void addListener(covariant BotFixImageStreamListener listener) {
    super.addListener(listener);
  }

  @override
  void removeListener(covariant ImageStreamListener listener) {
    super.removeListener(listener);
  }
}

class ImageLoadResponse {
  final Uint8List bytes;
  final String? mime;

  ImageLoadResponse(this.bytes,{ this.mime });
}

typedef LoadImage = Future<ImageLoadResponse> Function(Uri url);
typedef OnImageLoad = void Function(int naturalWidth, int naturalHeight);

class BoxFitImage extends ImageProvider<BoxFitImageKey> {
  BoxFitImage(Element target, {
    required LoadImage loadImage,
    required this.url,
    required this.boxFit,
    this.onImageLoad,
  }): _loadImage = loadImage, _target = target;

  final Element _target;
  final LoadImage _loadImage;
  final Uri url;
  final BoxFit boxFit;
  final OnImageLoad? onImageLoad;

  @override
  ImageStream createStream(ImageConfiguration configuration) {
    return BoxFixImageStream();
  }

  @override
  Future<BoxFitImageKey> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<BoxFitImageKey>(BoxFitImageKey(
      url: url,
      configuration: configuration,
    ));
  }

  Future<ImageStreamCompleter> _loadAsync2(BoxFitImageKey key) async {
    ImageLoadResponse response;
    try {
      response = await _loadImage(url);
    } on FlutterError {
      PaintingBinding.instance.imageCache.evict(key);
      rethrow;
    }

    final bytes = response.bytes;
    final mime = response.mime;

    if (bytes.isEmpty) {
      PaintingBinding.instance.imageCache.evict(key);
      throw StateError('Unable to read data');
    }

    if (mime == 'image/svg+xml' || key.url.path.endsWith('.svg')) {
      return SVGStreamCompleter(_target);
    }

    final codec = Future.value().then((_) async {
      final ImmutableBuffer buffer = await ImmutableBuffer.fromUint8List(bytes);
      final ImageDescriptor descriptor = await ImageDescriptor.encoded(buffer);
      final codec = await _instantiateImageCodec(
        descriptor,
        boxFit: boxFit,
        preferredWidth: key.configuration?.size?.width.toInt(),
        preferredHeight: key.configuration?.size?.height.toInt(),
      );


      // Fire image on load after codec created.
      scheduleMicrotask(() {
        if (onImageLoad != null) {
          onImageLoad!(descriptor.width, descriptor.height);
        }
      });
      return codec;
    });

    return MultiFrameImageStreamCompleter(codec: codec, scale: 1.0, informationCollector: () {
      return <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<BoxFitImageKey>('Image key', key),
      ];
    },);
  }

  @override
  BoxFixImageStream resolve(ImageConfiguration configuration) {
    // TODO: implement resolve
    return super.resolve(configuration) as BoxFixImageStream;
  }

  @override
  ImageStreamCompleter loadImage(BoxFitImageKey key, ImageDecoderCallback decode) {
    return AsyncImageStreamCompleter(
      _loadAsync2(key)
    );
  }

  static Future<Codec> _instantiateImageCodec(
    ImageDescriptor descriptor, {
    BoxFit? boxFit = BoxFit.none,
    int? preferredWidth,
    int? preferredHeight,
  }) async {
    assert(boxFit != null);

    final int naturalWidth = descriptor.width;
    final int naturalHeight = descriptor.height;

    int? targetWidth;
    int? targetHeight;

    // Image will be resized according to its aspect radio if object-fit is not fill.
    // https://www.w3.org/TR/css-images-3/#propdef-object-fit
    if (preferredWidth != null && preferredHeight != null) {
      // When targetWidth or targetHeight is not set at the same time,
      // image will be resized according to its aspect radio.
      // https://github.com/flutter/flutter/blob/master/packages/flutter/lib/src/painting/box_fit.dart#L152
      if (boxFit == BoxFit.contain) {
        if (preferredWidth / preferredHeight > naturalWidth / naturalHeight) {
          targetHeight = preferredHeight;
        } else {
          targetWidth = preferredWidth;
        }

        // Resized image should maintain its intrinsic aspect radio event if object-fit is fill
        // which behaves just like object-fit cover otherwise the cached resized image with
        // distorted aspect ratio will not work when object-fit changes to not fill.
      } else if (boxFit == BoxFit.fill || boxFit == BoxFit.cover) {
        if (preferredWidth / preferredHeight > naturalWidth / naturalHeight) {
          targetWidth = preferredWidth;
        } else {
          targetHeight = preferredHeight;
        }

        // Image should maintain its aspect radio and not resized if object-fit is none.
      } else if (boxFit == BoxFit.none) {
        targetWidth = naturalWidth;
        targetHeight = naturalHeight;

        // If image size is smaller than its natural size when object-fit is contain,
        // scale-down is parsed as none, otherwise parsed as contain.
      } else if (boxFit == BoxFit.scaleDown) {
        if (preferredWidth / preferredHeight > naturalWidth / naturalHeight) {
          if (preferredHeight > naturalHeight) {
            targetWidth = naturalWidth;
            targetHeight = naturalHeight;
          } else {
            targetHeight = preferredHeight;
          }
        } else {
          if (preferredWidth > naturalWidth) {
            targetWidth = naturalWidth;
            targetHeight = naturalHeight;
          } else {
            targetWidth = preferredWidth;
          }
        }
      }
    } else {
      targetWidth = preferredWidth;
      targetHeight = preferredHeight;
    }

    // Resize image size should not be larger than its natural size.
    if (targetWidth != null && targetWidth > naturalWidth) {
      targetWidth = naturalWidth;
    }
    if (targetHeight != null && targetHeight > naturalHeight) {
      targetHeight = naturalHeight;
    }

    return descriptor.instantiateCodec(
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
  }
}

// The [MultiFrameImageStreamCompleter] that saved the natural dimention of image.
class DimensionedMultiFrameImageStreamCompleter extends MultiFrameImageStreamCompleter {
  DimensionedMultiFrameImageStreamCompleter({
    required Future<Codec> codec,
    required double scale,
    String? debugLabel,
    Stream<ImageChunkEvent>? chunkEvents,
    InformationCollector? informationCollector,
  }) : super(
            codec: codec,
            scale: scale,
            debugLabel: debugLabel,
            chunkEvents: chunkEvents,
            informationCollector: informationCollector);

  final List<Completer<Dimension>> _dimensionCompleter = [];
  Dimension? _dimension;

  // Future<Dimension> get dimension async {
  //   if (_dimension != null) {
  //     return _dimension!;
  //   } else {
  //     Completer<Dimension> completer = Completer<Dimension>();
  //     _dimensionCompleter.add(completer);
  //     return completer.future;
  //   }
  // }

  // void setDimension(Dimension dimension) {
  //   _dimension = dimension;
  //   if (_dimensionCompleter.isNotEmpty) {
  //     _dimensionCompleter.forEach((Completer<Dimension> completer) {
  //       completer.complete(dimension);
  //     });
  //     _dimensionCompleter.clear();
  //   }
  // }
}

class AsyncImageStreamCompleter extends ImageStreamCompleter {
  bool _listenProxied = false;
  ImageStreamCompleter? _completer;

  ImageStreamListener? _listenerCache;
  get _listener => _listenerCache ??= ImageStreamListener(_onImage);

  AsyncImageStreamCompleter(
      Future<ImageStreamCompleter> asyncCompleter) {
    asyncCompleter.then((completer) {
      _completer = completer;
      _readyCompleter();
    });
  }

  void _onImage(ImageInfo image, bool syncCall) {
    print("onImage $image");
    setImage(image);
  }

  @override
  void addListener(ImageStreamListener listener) {
    super.addListener(listener);
    _readyCompleter();
  }

  // TODO: use another name
  _readyCompleter() {
    if (_completer == null) {
      return;
    }
    final completer = _completer!;
    if (hasListeners && !_listenProxied) {
      completer.addListener(_listener);
      completer.addOnLastListenerRemovedCallback(() {
        completer.removeListener(_listener);
        _listenProxied = false;
      });
      _listenProxied = true;
    }
  }
}

class SVGStreamCompleter extends ImageStreamCompleter {
  SVGStreamCompleter(Element target) {
    final rootRenderStyle = CSSRenderStyle(target: target);
    final rootRender = RenderSVGRoot(renderStyle: rootRenderStyle);
    rootRender.viewBox = Rect.fromLTWH(0, 0, 100, 100);

    final rectRenderStyle = CSSRenderStyle(target: target);
    rectRenderStyle.x = CSSLengthValue(10, CSSLengthType.PX);
    rectRenderStyle.y = CSSLengthValue(10, CSSLengthType.PX);
    rectRenderStyle.width = CSSLengthValue(50, CSSLengthType.PX);
    rectRenderStyle.height = CSSLengthValue(50, CSSLengthType.PX);
    rectRenderStyle.fill = CSSPaint(CSSPaintType.color, color: CSSColor.parseColor('#ff0000'));
    final rootRect = RenderSVGRect(renderStyle: rectRenderStyle);

    rootRender.adoptChild(rootRect);

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    // final layer = OffsetLayer();
    // final context = PaintingContext(layer, Rect.fromLTWH(0, 0, 100, 100));
    //
    // rootRender.layout(BoxConstraints());
    // context.paintChild(rootRender, Offset.zero);
    // // rootRender.paint(context, Offset.zero);
    // setImage(ImageInfo(
    //   image:layer.toImageSync(Rect.fromLTWH(0, 0, 100, 100)),
    // ));
  }
}

void printGumboTree(Pointer<NativeGumboNode> nodePtr, [int indent = 0]) {
  final p = ' ' * (indent * 2);
  final type = nodePtr.ref.type;
  print('$p node type: $type');
  switch(type) {
    case 1: {
      // element
      final element = nodePtr.ref.v.element;
      final children = element.children;
      final tag = element.tag;
      final tagName = element.original_tag.length != 0 ? element.original_tag.data.toDartString(length: element.original_tag.length) : '(none)';

      print('$p tag: $tag($tagName) in namespace ${element.tag_namespace} with ${children.length} child');

      final attributes = element.attributes;
      for (int i = 0; i < attributes.length; i++) {
        final attr = attributes.data[i] as Pointer<NativeGumboAttribute>;
        final name = attr.ref.name.toDartString();
        final value = attr.ref.value.toDartString();
        print('$p $name=$value');
      }

      for (int i = 0; i < children.length; i++) {
        final childRef = children.data[i] as Pointer<NativeGumboNode>;
        printGumboTree(childRef, indent + 1);
      }
      break;
    }
    case 5: {
      // all whitespace
      break;
    }
  }

}

class SVGRenderBoxBuilder {
  final Element target;
  final Future<ImageLoadResponse> imageLoader;
  SVGRenderBoxBuilder(this.imageLoader, {required this.target});

  Future<RenderBoxModel> decode() async {
    final resp = await imageLoader;

    final code = convert.utf8.decode(resp.bytes);

    final ptr = parseSVGResult(code);

    Pointer<NativeGumboNode> root = nullptr;
    visitSVGTree(ptr.ref.root, (node, _) {
      final type = node.ref.type;
      if (type == 1) {
        final element = node.ref.v.element;
        print('${element.tag} ${element.tag_namespace}');
        if (element.tag_namespace == 1 && element.tag == 92) {
          // svg tag
          root = node;
          return false;
        }
      }
    });

    if (root == nullptr) {
      // TODO: throw error
      throw Error();
    }

    final rootRenderObject = visitSVGTree(root, (node, parent) {
      final type = node.ref.type;
      if (type == 1) {
        final element = node.ref.v.element;
        final tagName = element.original_tag.data.toDartString(length: element.original_tag.length);
        final renderBox = getSVGRenderBox(tagName, target);

        final attributes = element.attributes;
        for (int i = 0; i < attributes.length; i++) {
          final attr = attributes.data[i] as Pointer<NativeGumboAttribute>;
          final name = attr.ref.name.toDartString();
          final value = attr.ref.value.toDartString();
          setAttribute(tagName, renderBox, name, value);
        }

        if (parent != null) {
          assert(parent is RenderSVGContainer);
          (parent as RenderSVGContainer).insert(renderBox);
        }

        return renderBox;
      }
      return false;
    });

    freeSVGResult(ptr);

    return rootRenderObject as RenderBoxModel;
  }

  RenderBoxModel getSVGRenderBox(String tagName, Element target) {
    final renderStyle = CSSRenderStyle(target: target);
    // renderStyle.parent = target.renderStyle;
    switch(tagName) {
      case 'svg': {
        renderStyle.height = CSSLengthValue.auto;
        renderStyle.width = CSSLengthValue.auto;
        return RenderSVGRoot(renderStyle: renderStyle);
      }
      case 'rect': {
        return RenderSVGRect(renderStyle: renderStyle);
      }
      case 'path': {
        return RenderSVGPath(renderStyle: renderStyle);
      }
      default: {
        print('Cannot found $tagName');
        return RenderSVGEmpty(renderStyle: renderStyle);
      }
    }
  }

  void setAttribute(String tagName, RenderBoxModel model, String name, String value) {
    print('setAttribute $name $value');
    switch (tagName) {
      case 'svg': {
        final root = model as RenderSVGRoot;
        switch (name) {
          case 'viewBox': {
            root.viewBox = parseViewBox(value);
            return;
          }
          case 'width':
          case 'height': {
            // width/height is fixed
            return;
          }
        }
      }
    }
    // TODO: support base url
    final parsed = model.renderStyle.resolveValue(name, value);
    if (parsed != null) {
      model.renderStyle.setProperty(name, parsed);
    }
  }
}

dynamic visitSVGTree(Pointer<NativeGumboNode> node, dynamic Function(Pointer<NativeGumboNode>, dynamic) visitor, [parentValue]) {
  final currentValue = visitor(node, parentValue);
  if (currentValue == false) {
    return;
  }
  final type = node.ref.type;
  if (type == 1) {
    final element = node.ref.v.element;
    final children = element.children;
    for (int i = 0; i < children.length; i++) {
      final childRef = children.data[i] as Pointer<NativeGumboNode>;
      visitSVGTree(childRef, visitor, currentValue);
    }
  }

  return currentValue;
}
