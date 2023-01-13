import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../camera_data/camera_plugin_type.dart';

import '../storecamera_plugin_camera.dart';

typedef OnCameraPluginWidget = void Function(StoreCameraPluginCamera? plguin);

class CameraPluginWidgetMeasure {
  final CameraRatio? ratio;
  final double fullWidth;
  final double fullHeight;

  final double areaLeft;
  final double areaTop;
  final double areaRight;
  final double areaBottom;

  final double areaWidth;
  final double areaHeight;

  CameraPluginWidgetMeasure(
      this.ratio,
      this.fullWidth,
      this.fullHeight,
      this.areaLeft,
      this.areaTop,
      this.areaRight,
      this.areaBottom,
      this.areaWidth,
      this.areaHeight);

  factory CameraPluginWidgetMeasure.fromContext(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final fullWidth = mediaQuery.size.width;
    final fullHeight = mediaQuery.size.height;
    final areaWidth = mediaQuery.size.width - mediaQuery.padding.horizontal;
    final areaHeight = mediaQuery.size.height - mediaQuery.padding.vertical;

    final fullRatio = fullHeight / fullWidth;

    CameraRatio? ratio;
    if (fullRatio >= CameraRatio.RATIO_9_16.hRatio) {
      ratio = CameraRatio.RATIO_9_16;
    } else if (fullRatio >= CameraRatio.RATIO_3_4.hRatio) {
      ratio = CameraRatio.RATIO_3_4;
    } else if (fullRatio >= CameraRatio.RATIO_4_5.hRatio) {
      ratio = CameraRatio.RATIO_4_5;
    } else if (fullRatio >= CameraRatio.RATIO_1_1.hRatio) {
      ratio = CameraRatio.RATIO_1_1;
    }

    return CameraPluginWidgetMeasure(
        ratio,
        fullWidth,
        fullHeight,
        mediaQuery.padding.left,
        mediaQuery.padding.top,
        mediaQuery.padding.right,
        mediaQuery.padding.bottom,
        areaWidth,
        areaHeight);
  }

  bool get isAvailableArea =>
      ratio != null ? (areaHeight / areaWidth) >= (ratio?.hRatio ?? 1) : false;

  double get availableLeft => isAvailableArea ? areaLeft : 0;

  double get availableTop => isAvailableArea ? areaTop : 0;

  double get availableRight => isAvailableArea ? areaRight : 0;

  double get availableBottom => isAvailableArea ? areaBottom : 0;

  bool availableSizeOutsidePadding(EdgeInsetsGeometry padding) {
    return ratio != null
        ? (fullHeight - padding.vertical) / (fullWidth - padding.horizontal) >=
            (ratio?.hRatio ?? 1)
        : false;
  }

  bool availableAreaOutsidePadding(EdgeInsetsGeometry padding) {
    return ratio != null
        ? (areaHeight - padding.vertical) / (areaWidth - padding.horizontal) >=
            (ratio?.hRatio ?? 1)
        : false;
  }
}

class CameraPluginWidget extends StatefulWidget {
  final CameraPosition? initPosition;
  final OnCameraPluginWidget? onPlugin;

  const CameraPluginWidget(
      {Key? key, required this.onPlugin, this.initPosition})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _CameraPluginState();
}

class _CameraPluginState extends State<CameraPluginWidget> {
  StoreCameraPluginCamera? _plugin;

  CameraPosition? _initPosition;
  @override
  void initState() {
    _initPosition = widget.initPosition ?? CameraPosition.BACK;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        creationParams: creationParams(),
        viewType: StoreCameraPluginCamera.CHANNEL,
        onPlatformViewCreated: onPlatformViewCreated,
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        creationParams: creationParams(),
        viewType: StoreCameraPluginCamera.CHANNEL,
        onPlatformViewCreated: onPlatformViewCreated,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
    return Text(
        '$defaultTargetPlatform is not yet supported by this plugin : CameraPluginWidget');
  }

  Future<void> onPlatformViewCreated(int id) async {
    final plugin = _plugin;
    if (plugin != null && plugin.id != id) {
      widget.onPlugin!(null);
      _plugin = null;
    }

    if (_plugin == null) {
      _plugin = StoreCameraPluginCamera(id);
      widget.onPlugin!(_plugin);
    } else {
      if (kDebugMode) {
        print('CameraPluginWidget:onPlatformViewCreated Already $id');
      }
    }
  }

  @override
  void dispose() {
    _plugin = null;
    widget.onPlugin!(null);
    super.dispose();
  }

  Map creationParams() => {
        'position': _initPosition?.value ?? '',
      };
}

// class _StoreCameraPluginCamera extends SingleChildRenderObjectWidget {
//
//   _StoreCameraPluginCamera(
//       StoreCameraPluginCameraOnPlugin onPlugin,
//       {Key key})
//       : super(
//       key: key,
//       child: StoreCameraPluginCameraWidget(onPlugin: onPlugin)
//   );
//
//   @override
//   RenderObject createRenderObject(BuildContext context) =>
//       _StoreCameraPluginCameraRenderBox();
// }
//
// class _StoreCameraPluginCameraRenderBox extends RenderShiftedBox {
//
//   _StoreCameraPluginCameraRenderBox({RenderBox child}) : super(child);
//
//   @override
//   void performLayout() {
//     if(child != null && constraints != null) {
//       child.layout(BoxConstraints.tightFor(
//         width: constraints.maxWidth,
//         height: constraints.maxWidth * CameraRatio.RATIO_4_3.ratio,
//       ), parentUsesSize: true);
//       size = Size(child.size.width, child.size.height);
//     }
//   }
// }
