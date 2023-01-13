import 'package:flutter/material.dart';
import 'package:storecamera_photo/storecamera_plugin_media.dart';

class AlbumPage extends StatefulWidget {
  const AlbumPage({Key? key}) : super(key: key);

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Album'),
      ),
      body: SafeArea(
        child: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text('Do'),
              onPressed: () async {
                var folder = await StoreCameraPluginMedia.getImageFolder();
                print(folder);
              },
            )
          ],
        )),
      ),
    );
  }
}
