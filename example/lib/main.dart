import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:storecamera_photo/camera_data/camera_plugin_type.dart';
import 'package:storecamera_photo/camera_widget/camera_plugin_widget.dart';
import 'package:storecamera_photo/storecamera_plugin_camera.dart';
import 'package:storecamera_photo/storecamera_plugin_media.dart';
import 'package:storecamera_photo_example/album_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera plugin Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Camera plugin Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
            ElevatedButton(
              child: const Text('album'),
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const AlbumPage()));
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            final hasP = await StoreCameraPluginMedia.hasPermission();
            debugPrint('#######: $hasP');
            final result = await StoreCameraPluginMedia.requestPermission();
            switch (result) {
              case PermissionResult.GRANTED:
                if (!mounted) return;
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const CameraPage(),
                ));
                break;
              case PermissionResult.DENIED:
                return showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Permission denied'),
                        content: const Text('Permission denied'),
                        actions: [
                          TextButton(
                              child: const Text('Ok'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              }),
                        ],
                      );
                    });
              case PermissionResult.DENIED_TO_APP_SETTING:
                return showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Permission denied'),
                        content: const Text('Permission denied Forever'),
                        actions: [
                          TextButton(
                              child: const Text('Ok'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              }),
                        ],
                      );
                    });
            }
          } catch (_) {
            if (kDebugMode) {
              print('error ${_.toString()}');
            }
          }
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  StoreCameraPluginCamera? _cameraPlguin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 3 / 4,
              child: CameraPluginWidget(onPlugin: (_) {
                _cameraPlguin = _;
                _cameraPlguin?.resume();
              }),
            ),
            Expanded(
                child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        // primary: Colors.blue,
                        elevation: 8,
                        shape: const CircleBorder()),
                    onPressed: () async {
                      Uint8List? result = await _cameraPlguin?.capture(
                          CameraRatio.RATIO_3_4, CameraResolution.LOW);
                      if (result != null) {
                        ui.decodeImageFromList(
                          result,
                          (ui.Image result) {
                            _showImageDialog(context, result);
                          },
                        );
                      }
                    },
                    child: const SizedBox(
                      width: 64,
                      height: 64,
                    ),
                  )
                  // ElevatedButton(onPressed: onPressed, child: child)
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

void _showImageDialog(BuildContext context, ui.Image image) async {
  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Capture Image'),
        content: RawImage(
          image: image,
          fit: BoxFit.contain,
        ),
        actions: [
          TextButton(
            child: const Text('Ok'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );

  image.dispose();
}
