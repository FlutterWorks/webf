/*
 * Copyright (C) 2022-present The WebF authors. All rights reserved.
 */

import 'dart:ui';
import 'package:webf/css.dart';
import 'package:webf/svg.dart';

import 'shape.dart';

class RenderSVGCircle extends RenderSVGShape {
  RenderSVGCircle({required CSSRenderStyle renderStyle, SVGGeometryElement? element})
      : super(renderStyle: renderStyle, element: element);

  @override
  Path asPath() {
    final cx = renderStyle.cx.computedValue;
    final cy = renderStyle.cy.computedValue;
    final r = renderStyle.r.computedValue;

    if (r <= 0) {
      return Path();
    }

    return Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
  }
}
