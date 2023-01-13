import 'dart:async';

import 'package:flutter/material.dart';

import '../media_plugin_data.dart';
import '../storecamera_plugin_media.dart';
import 'plugin_image_provider.dart';
import 'plugin_thumbnail_cache_loader.dart';

typedef PluginThumbnailLoadingWidgetBuilder = Widget Function(
  BuildContext context,
  PluginImage image,
);

typedef PluginFolderThumbnailLoadingWidgetBuilder = Widget Function(
  BuildContext context,
  PluginFolder? folder,
);

typedef PluginFolderThumbnailEmptyWidgetBuilder = Widget Function(
  BuildContext context,
  PluginFolder? folder,
);

typedef PluginThumbnailLoadedWidgetBuilder = Widget Function(
  BuildContext context,
  PluginBitmapProvider? imageProvider,
);

typedef PluginThumbnailErrorWidgetBuilder = Widget Function(
  BuildContext context,
  Object error,
);

enum _LoadState { LOADING, LOADED, ERROR }

class PluginThumbnailWidget extends StatefulWidget {
  final PluginImage image;
  final int? thumbnailWidthPx;
  final int? thumbnailHeightPx;

  final double? width;
  final double? height;
  final BoxFit? boxFit;
  final PluginThumbnailLoader loader;
  final PluginThumbnailLoadingWidgetBuilder? loadingBuilder;
  final PluginThumbnailLoadedWidgetBuilder? loadedBuilder;
  final PluginThumbnailErrorWidgetBuilder? errorBuilder;

  PluginThumbnailWidget(
      {Key? key,
      required this.image,
      this.thumbnailWidthPx,
      this.thumbnailHeightPx,
      this.width,
      this.height,
      this.boxFit,
      PluginThumbnailLoader? loader,
      this.loadingBuilder,
      this.loadedBuilder,
      this.errorBuilder})
      : loader = loader ?? PluginThumbnailCacheLoader(),
        super(key: key);

  @override
  State<StatefulWidget> createState() => _PluginThumbnailState();
}

class _PluginThumbnailState extends State<PluginThumbnailWidget> {
  _LoadState? _loadState;
  PluginImage? _image;
  PluginBitmapProvider? _provider;
  Object? _exception;

  @override
  Widget build(BuildContext context) {
    if (_loadState == null ||
        (_image != null && _image!.id != widget.image.id)) {
      _loadState = _LoadState.LOADING;
      _image = widget.image;
      _provider?.evict();
      _provider = null;
      _exception = null;

      final bitmap = widget.loader
          .loadAsync(_image!.id, null, null, _pluginThumbnailLoaderCallback);
      if (bitmap != null) {
        _provider = PluginBitmapProvider(_image!.id, bitmap);
        _loadState = _LoadState.LOADED;
      }
    }

    final loadState = _loadState;
    if (loadState != null) {
      switch (loadState) {
        case _LoadState.LOADING:
          return _buildLoading(context, widget.image);
        case _LoadState.LOADED:
          return _buildLoaded(context, _provider);
        case _LoadState.ERROR:
          final exception = _exception;
          if (exception != null) {
            return _buildError(context, exception);
          }
      }
    }

    return Container(
      width: widget.width,
      height: widget.height,
    );
  }

  void _pluginThumbnailLoaderCallback(PluginBitmap? bitmap, Object? e) {
    if (mounted) {
      if (bitmap != null) {
        setState(() {
          _loadState = _LoadState.LOADED;
          _provider = PluginBitmapProvider(_image!.id, bitmap);
          _exception = null;
        });
      } else {
        setState(() {
          _loadState = _LoadState.ERROR;
          _provider = null;
          _exception = e;
        });
      }
    }
  }

  @override
  void dispose() {
    if (_provider == null && _exception == null) {
      widget.loader.cancelAsync(_pluginThumbnailLoaderCallback);
    }
    _provider = null;
    _image = null;
    _exception = null;
    _loadState = null;
    super.dispose();
  }

  Widget _buildLoading(
    BuildContext context,
    PluginImage image,
  ) {
    return Container(
      width: widget.width,
      height: widget.height,
      child: widget.loadingBuilder != null
          ? widget.loadingBuilder!(context, image)
          : null,
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    PluginBitmapProvider? provider,
  ) {
    return Container(
      width: widget.width,
      height: widget.height,
      child: widget.loadedBuilder != null
          ? widget.loadedBuilder!(context, provider)
          : Image(
              width: widget.width,
              height: widget.height,
              fit: widget.boxFit,
              image: provider!,
            ),
    );
  }

  Widget _buildError(
    BuildContext context,
    Object e,
  ) {
    return Container(
      width: widget.width,
      height: widget.height,
      child:
          widget.errorBuilder != null ? widget.errorBuilder!(context, e) : null,
    );
  }
}

class PluginFolderThumbnailWidget extends StatefulWidget {
  final PluginFolder? folder;
  final int? thumbnailWidthPx;
  final int? thumbnailHeightPx;
  final double? width;
  final double? height;
  final BoxFit? boxFit;
  final PluginFolderThumbnailLoadingWidgetBuilder? loadingBuilder;
  final PluginThumbnailLoadedWidgetBuilder? loadedBuilder;
  final PluginFolderThumbnailEmptyWidgetBuilder? emptyBuilder;
  final PluginThumbnailErrorWidgetBuilder? errorBuilder;

  const PluginFolderThumbnailWidget(
      {Key? key,
      this.folder,
      this.thumbnailWidthPx,
      this.thumbnailHeightPx,
      this.width,
      this.height,
      this.boxFit,
      this.loadingBuilder,
      this.loadedBuilder,
      this.emptyBuilder,
      this.errorBuilder})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _PluginFolderThumbnailState();
}

class _PluginFolderThumbnailState extends State<PluginFolderThumbnailWidget> {
  _LoadState? _loadState;
  PluginFolder? _folder;
  PluginImage? _file;
  Object? _exception;

  @override
  Widget build(BuildContext context) {
    if (_loadState == null ||
        (_getFolderId(_folder) != _getFolderId(widget.folder))) {
      _loadState = _LoadState.LOADING;
      _folder = widget.folder;
      _file = null;
      _loadAsync(_folder);
    }

    final loadState = _loadState;
    if (loadState != null) {
      switch (loadState) {
        case _LoadState.LOADING:
          return _buildLoading(context, widget.folder);
        case _LoadState.LOADED:
          if (_file == null) {
            return _buildEmpty(context, _folder);
          }
          return _buildLoaded(context, _folder, _file);
        case _LoadState.ERROR:
          final exception = _exception;
          if (exception != null) {
            return _buildError(context, exception);
          }
      }
    }

    return Container(
      width: widget.width,
      height: widget.height,
    );
  }

  @override
  void dispose() {
    _folder = null;
    _file = null;
    _loadState = null;
    super.dispose();
  }

  String _getFolderId(PluginFolder? folder) => folder?.id ?? '';

  Widget _buildLoading(
    BuildContext context,
    PluginFolder? folder,
  ) {
    return Container(
      width: widget.width,
      height: widget.height,
      child: widget.loadingBuilder != null
          ? widget.loadingBuilder!(context, folder)
          : null,
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    PluginFolder? folder,
    PluginImage? image,
  ) {
    return image != null
        ? PluginThumbnailWidget(
            image: image,
            thumbnailWidthPx: widget.thumbnailWidthPx,
            thumbnailHeightPx: widget.thumbnailHeightPx,
            width: widget.width,
            height: widget.height,
            boxFit: widget.boxFit,
            loadingBuilder: widget.loadingBuilder != null
                ? (BuildContext context, PluginImage image) {
                    return widget.loadingBuilder!(context, folder);
                  }
                : null,
            loadedBuilder: widget.loadedBuilder,
            errorBuilder: widget.errorBuilder,
          )
        : Container(
            width: widget.width,
            height: widget.height,
          );
  }

  Widget _buildEmpty(
    BuildContext context,
    PluginFolder? folder,
  ) {
    return Container(
      width: widget.width,
      height: widget.height,
      child: widget.emptyBuilder != null
          ? widget.emptyBuilder!(context, folder)
          : null,
    );
  }

  Widget _buildError(
    BuildContext context,
    Object e,
  ) {
    return Container(
      width: widget.width,
      height: widget.height,
      child:
          widget.errorBuilder != null ? widget.errorBuilder!(context, e) : null,
    );
  }

  Future<void> _loadAsync(PluginFolder? folder) async {
    try {
      PluginDataSet<PluginImage>? dataSet =
          await StoreCameraPluginMedia.getImages(_getFolderId(folder),
              limit: 1);
      if (dataSet != null) {
        if (mounted) {
          setState(() {
            _loadState = _LoadState.LOADED;
            _file = dataSet.list.isNotEmpty ? dataSet.list.first : null;
          });
        }
      } else {
        throw Exception('Plugin Folder image files load failed');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadState = _LoadState.ERROR;
          _exception = e;
        });
      }
    }
  }
}
