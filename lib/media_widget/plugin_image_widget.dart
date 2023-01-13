import 'package:flutter/material.dart';
import '../media_plugin_data.dart';

import 'plugin_image_provider.dart';

typedef PluginImageBuilder = Widget Function(
  BuildContext context,
  ImageProvider? imageProvider,
);

class PluginImageWidget extends StatefulWidget {
  final String pluginImageId;
  final PluginImageBuilder builder;

  const PluginImageWidget({
    Key? key,
    required this.pluginImageId,
    required this.builder,
  }) : super(key: key);

  factory PluginImageWidget.pluginImage(
          {required PluginImage pluginImage,
          required PluginImageBuilder builder}) =>
      PluginImageWidget(pluginImageId: pluginImage.id, builder: builder);

  @override
  State<StatefulWidget> createState() => _PluginImageState();
}

class _PluginImageState extends State<PluginImageWidget> {
  late PluginImageProvider _pluginImageProvider;

  @override
  void initState() {
    super.initState();
    _pluginImageProvider = PluginImageProvider(widget.pluginImageId);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _pluginImageProvider);
  }

  @override
  void didUpdateWidget(covariant PluginImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pluginImageId != widget.pluginImageId) {
      setState(() {
        _pluginImageProvider.evict();
        _pluginImageProvider = PluginImageProvider(widget.pluginImageId);
      });
    }
  }
}
