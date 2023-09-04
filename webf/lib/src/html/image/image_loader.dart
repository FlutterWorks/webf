import 'package:webf/dom.dart';

typedef ImageLoadCallback = void Function();

class ImageResourceContent {

}

class ImageResource {}

class ImageLoader {
  String? source;

  final ImageLoadCallback? onLoadCallback;
  final ImageLoadCallback? onRequestUpdate;

  final Element element;

  ImageLoader(this.element, {
    this.onLoadCallback,
    this.onRequestUpdate,
  });

  setSource(String newSource) {
    source = newSource;
  }

  getRenderObject() {

  }
}

class HTMLImageLoader {

}
