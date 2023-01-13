import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../camera_data/camera_plugin_type.dart';
import 'camera_plugin_widget.dart';

typedef OnCameraAvailableRatio = void Function(Set<CameraRatio>? available,
    BuildContext context, double width, double height);
typedef OnCameraTap = void Function(
    Offset cameraPosition, Offset cameraLocalPosition);
typedef OnCameraOverlayBuilder = List<Widget> Function(
    BuildContext context,
    CameraRatio ratio,
    double width,
    double height,
    double currentHeight,
    double dy);

class CameraWidget extends StatefulWidget {
  final CameraRatio? ratio;
  final Color backgroundColor;

  final double? marginTop;
  final double? margin3d4Top;
  final double? margin4d5Top;
  final double? margin1d1Top;

  final OnCameraPluginWidget? onPlugin;
  final OnCameraAvailableRatio? onAvailableRatio;

  final void Function()? onScaleStart;
  final void Function(double scale)? onScaleUpdate;
  final void Function()? onScaleEnd;
  final OnCameraTap? onTap;
  final OnCameraOverlayBuilder? cameraOverlayBuilder;

  final Curve animationCurve;
  const CameraWidget(
      {Key? key,
      this.ratio,
      this.backgroundColor = Colors.black,
      this.marginTop,
      this.margin3d4Top,
      this.margin4d5Top,
      this.margin1d1Top,
      this.onPlugin,
      this.onAvailableRatio,
      this.onScaleStart,
      this.onScaleUpdate,
      this.onScaleEnd,
      this.onTap,
      this.cameraOverlayBuilder,
      this.animationCurve = Curves.linear})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _CameraState();

  static bool isRatioIncludeSize(CameraRatio ratio, Size size) {
    return (size.height / size.width) >= ratio.hRatio;
  }
}

class _CameraState extends State<CameraWidget> with TickerProviderStateMixin {
  final GlobalKey _cameraGlobalKey = GlobalKey();

  Set<CameraRatio>? availableRatioSet;
  CameraRatio? _ratio;
  double? _width;
  double? _height;

  double _dx = 0;
  double? _dy = 0;
  double _scale = 1.0;
  double? _blindTop = 0;
  double _blindBottom = 0;

  Animation<double>? _animation;
  late AnimationController _controller;
  _AnimationValue? _beginAnimation;
  _AnimationValue? _endAnimation;

  @override
  void initState() {
    _controller = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return _build(context, constraints.maxWidth, constraints.maxHeight);
    });
  }

  Widget _build(BuildContext context, double width, double height) {
    if (availableRatioSet == null) {
      _width = width;
      _height = height;
      _measureRatio(context, width, height);
      return Container(
        color: widget.backgroundColor,
      );
    }

    if (_width != width || _height != height) {
      _width = width;
      _height = height;
      _measureRatio(context, _width!, _height!);
    }
    CameraRatio? ratio = widget.ratio;
    if (ratio == null || availableRatioSet!.isEmpty) {
      _ratio = null;
      return Container(
        color: widget.backgroundColor,
      );
    }

    if (_ratio == null) {
      _animation?.removeListener(_onAnimate);
      _controller.reset();

      _AnimationValue value = _getAnimationValue(ratio, width, height);
      _dx = value.dx;
      _dy = value.dy;
      _scale = value.scale;
      _blindTop = value.blindTop;
      _blindBottom = value.blindBottom;
    } else if (_ratio != widget.ratio) {
      _animation?.removeListener(_onAnimate);
      _controller.reset();

      _beginAnimation =
          _AnimationValue(_dx, _dy, _scale, _blindTop, _blindBottom);
      _endAnimation = _getAnimationValue(ratio, width, height);
      _animation =
          CurvedAnimation(parent: _controller, curve: widget.animationCurve);
      _animation!.addListener(_onAnimate);
      _controller.fling();
      // _controller.forward();
    }
    _ratio = ratio;

    List<Widget> children = [];
    children.addAll([
      Transform(
        transform: _getMatrix4(),
        child: AspectRatio(
            aspectRatio: CameraRatio.RATIO_3_4.vRatio,
            child: CameraPluginWidget(
                key: _cameraGlobalKey, onPlugin: widget.onPlugin)),
      ),
      GestureDetector(
        onTapUp: (TapUpDetails details) {
          final onTap = widget.onTap;
          final RenderBox? renderObject =
              _cameraGlobalKey.currentContext?.findRenderObject() as RenderBox?;
          if (onTap != null && renderObject != null) {
            onTap(details.localPosition,
                renderObject.globalToLocal(details.globalPosition));
          }
        },
        onScaleStart: (details) {
          final onScaleStart = widget.onScaleStart;
          if (onScaleStart != null) {
            onScaleStart();
          }
        },
        onScaleUpdate: (details) {
          final onScaleUpdate = widget.onScaleUpdate;
          if (onScaleUpdate != null) {
            widget.onScaleUpdate!(details.scale);
          }
        },
        onScaleEnd: (details) {
          final onScaleEnd = widget.onScaleEnd;
          if (onScaleEnd != null) {
            onScaleEnd();
          }
        },
      ),
      Column(
        children: [
          Container(
            color: widget.backgroundColor,
            height: _blindTop,
          ),
          Expanded(
            flex: 1,
            child: Container(),
          ),
          Container(
            color: widget.backgroundColor,
            height: _blindBottom,
          ),
        ],
      ),
    ]);
    if (widget.cameraOverlayBuilder != null) {
      children.addAll(widget.cameraOverlayBuilder!(
        context,
        ratio,
        width,
        height,
        height - _blindTop! - _blindBottom,
        _blindTop!,
      ));
    }

    return Stack(
      children: children,
    );
  }

  Matrix4 _getMatrix4() => Matrix4.identity()
    ..translate(_dx, _dy!)
    ..scale(_scale);

  /// camera min ratio more than 3 :4
  void _measureRatio(BuildContext context, double width, double height) {
    final ratio = height / width;
    availableRatioSet = {};
    if (ratio >= CameraRatio.RATIO_9_16.hRatio - 0.00000001) {
      availableRatioSet!.add(CameraRatio.RATIO_9_16);
    }

    if (ratio >= CameraRatio.RATIO_3_4.hRatio) {
      availableRatioSet!.add(CameraRatio.RATIO_3_4);
      availableRatioSet!.add(CameraRatio.RATIO_4_5);
      availableRatioSet!.add(CameraRatio.RATIO_1_1);
    }

    _onAvailableRatio(availableRatioSet, context, width, height);
  }

  void _onAvailableRatio(Set<CameraRatio>? available, BuildContext context,
      double width, double height) async {
    if (widget.onAvailableRatio != null) {
      widget.onAvailableRatio!(available, context, width, height);
    }
  }

  _AnimationValue _getAnimationValue(
      CameraRatio cameraRatio, double width, double height) {
    double ratio = height / width;
    if (ratio >= CameraRatio.RATIO_9_16.hRatio - 0.00000001) {
      return _getAnimationValue9d16(cameraRatio, width, height);
    } else if (ratio >= CameraRatio.RATIO_3_4.hRatio) {
      return _getAnimationValue3d4(cameraRatio, width, height);
    }

    return _AnimationValue(0, 0, 1.0, 0, 0);
  }

  _AnimationValue _getAnimationValue9d16(
      CameraRatio ratio, double width, double height) {
    double marginTop = widget.marginTop ??
        (height - width * CameraRatio.RATIO_9_16.hRatio) / 2;
    double margin3d4Top = widget.margin3d4Top != null
        ? marginTop + widget.margin3d4Top!
        : marginTop +
            (width * CameraRatio.RATIO_9_16.hRatio -
                    width * CameraRatio.RATIO_3_4.hRatio) /
                2;
    double margin4d5Top = widget.margin4d5Top != null
        ? margin3d4Top + widget.margin4d5Top!
        : margin3d4Top +
            (width * CameraRatio.RATIO_3_4.hRatio -
                    width * CameraRatio.RATIO_4_5.hRatio) /
                2;
    double margin1d1Top = widget.margin1d1Top != null
        ? margin3d4Top + widget.margin1d1Top!
        : margin3d4Top +
            (width * CameraRatio.RATIO_3_4.hRatio -
                    width * CameraRatio.RATIO_1_1.hRatio) /
                2;

    switch (ratio) {
      case CameraRatio.RATIO_1_1:
        return _AnimationValue(
            0,
            margin1d1Top -
                (width * CameraRatio.RATIO_3_4.hRatio -
                        width * CameraRatio.RATIO_1_1.hRatio) /
                    2,
            1.0,
            margin1d1Top,
            height - width * CameraRatio.RATIO_1_1.hRatio - margin1d1Top);
      case CameraRatio.RATIO_4_5:
        return _AnimationValue(
            0,
            margin4d5Top -
                (width * CameraRatio.RATIO_3_4.hRatio -
                        width * CameraRatio.RATIO_4_5.hRatio) /
                    2,
            1.0,
            margin4d5Top,
            height - width * CameraRatio.RATIO_4_5.hRatio - margin4d5Top);
      case CameraRatio.RATIO_3_4:
        return _AnimationValue(0, margin3d4Top, 1.0, margin3d4Top,
            height - width * CameraRatio.RATIO_3_4.hRatio - margin3d4Top);
      case CameraRatio.RATIO_9_16:
        final scale =
            CameraRatio.RATIO_9_16.hRatio / CameraRatio.RATIO_3_4.hRatio;
        return _AnimationValue(
            (width - width * scale) / 2,
            marginTop,
            scale,
            marginTop,
            height - width * CameraRatio.RATIO_9_16.hRatio - marginTop);
    }
  }

  _AnimationValue _getAnimationValue3d4(
      CameraRatio ratio, double width, double height) {
    double marginTop = widget.marginTop ?? 0;
    double margin3d4Top = widget.margin3d4Top != null
        ? marginTop + widget.margin3d4Top!
        : marginTop + (height - width * CameraRatio.RATIO_3_4.hRatio) / 2;
    double margin1d1Top = widget.margin1d1Top != null
        ? margin3d4Top + widget.margin1d1Top!
        : margin3d4Top +
            (width * CameraRatio.RATIO_3_4.hRatio -
                    width * CameraRatio.RATIO_1_1.hRatio) /
                2;

    switch (ratio) {
      case CameraRatio.RATIO_1_1:
        return _AnimationValue(
            0,
            margin1d1Top -
                (width * CameraRatio.RATIO_3_4.hRatio -
                        width * CameraRatio.RATIO_1_1.hRatio) /
                    2,
            1.0,
            margin1d1Top,
            height - width * CameraRatio.RATIO_1_1.hRatio - margin1d1Top);
      case CameraRatio.RATIO_4_5:
        return _AnimationValue(
            0,
            margin1d1Top -
                (width * CameraRatio.RATIO_4_5.hRatio -
                        width * CameraRatio.RATIO_4_5.hRatio) /
                    2,
            1.0,
            margin1d1Top,
            height - width * CameraRatio.RATIO_4_5.hRatio - margin1d1Top);
      case CameraRatio.RATIO_3_4:
        return _AnimationValue(0, margin3d4Top, 1.0, margin3d4Top,
            height - width * CameraRatio.RATIO_3_4.hRatio - margin3d4Top);
      case CameraRatio.RATIO_9_16:
        break;
    }

    return _AnimationValue(0, 0, 1.0, 0, 0);
  }

  void _onAnimate() {
    final beginAnimation = _beginAnimation;
    final endAnimation = _endAnimation;
    final animation = _animation;
    if (animation != null && beginAnimation != null && endAnimation != null) {
      setState(() {
        _dx = beginAnimation.dx +
            (endAnimation.dx - beginAnimation.dx) * animation.value;
        _dy = beginAnimation.dy! +
            (endAnimation.dy! - beginAnimation.dy!) * animation.value;
        _scale = beginAnimation.scale +
            (endAnimation.scale - beginAnimation.scale) * animation.value;
        _blindTop = beginAnimation.blindTop! +
            (endAnimation.blindTop! - beginAnimation.blindTop!) *
                animation.value;
        _blindBottom = beginAnimation.blindBottom +
            (endAnimation.blindBottom - beginAnimation.blindBottom) *
                animation.value;

        if (!_controller.isAnimating) {
          _animation?.removeListener(_onAnimate);
          _animation = null;
          _controller.reset();
          _beginAnimation = null;
          _endAnimation = null;
        }
      });
    }
  }
}

class _AnimationValue {
  final double dx;
  final double? dy;
  final double scale;
  final double? blindTop;
  final double blindBottom;

  _AnimationValue(
      this.dx, this.dy, this.scale, this.blindTop, this.blindBottom);

  Matrix4 matrix4() => Matrix4.identity()
    ..translate(dx, dy!)
    ..scale(scale);
}
