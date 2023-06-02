// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:flutter_tex/src/utils/core_utils.dart';
import 'package:flutter_tex/src/utils/fake_ui.dart'
    if (dart.library.html) 'dart:ui' as ui;

class TeXViewState extends State<TeXView> {
  String? _lastData;
  final ValueNotifier<double> _height = ValueNotifier<double>(minHeight);
  final String _viewId = UniqueKey().toString();

  @override
  Widget build(BuildContext context) {
    _initTeXView();
    return ValueListenableBuilder<double>(
        valueListenable: _height,
        builder: (context, value, _) {
          return Stack(
            children: [
              SizedBox(
                height: _height.value,
                child: HtmlElementView(
                  key: widget.key ?? ValueKey(_viewId),
                  viewType: _viewId,
                ),
              ),
              Visibility(
                  visible: widget.loadingWidgetBuilder?.call(context) != null
                      ? _height.value == minHeight
                          ? true
                          : false
                      : false,
                  child: widget.loadingWidgetBuilder?.call(context) ??
                      const SizedBox.shrink())
            ],
          );
        });
  }

  @override
  void initState() {
    _initWebview();
    super.initState();
  }

  void _initWebview() {
    ui.platformViewRegistry.registerViewFactory(
        _viewId,
        (int id) => html.IFrameElement()
          ..src =
              "assets/packages/flutter_tex/js/${widget.renderingEngine?.name ?? "katex"}/index.html"
          ..id = _viewId
          ..style.height = '100%'
          ..style.width = '100%'
          ..style.border = '0');

    js.context['TeXViewRenderedCallback'] = (message) {
      double height = double.parse(message.toString());
      if (_height.value != height) {
        _height.value = height;
      }

      widget.onRenderFinished?.call(height);
    };

    js.context['OnTapCallback'] = (id) {
      widget.child.onTapCallback(id);
    };
  }

  void _initTeXView() {
    if (getRawData(widget) != _lastData) {
      js.context.callMethod('initWebTeXView', [
        _viewId,
        getRawData(widget),
        widget.renderingEngine?.name ?? "katex"
      ]);
      _lastData = getRawData(widget);
    }
  }
}
