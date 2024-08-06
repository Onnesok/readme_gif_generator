import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/foundation.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            'Github Readme GIF Generator',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.black87,
        ),
        body: GifGenerator(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}



class GifGenerator extends StatefulWidget {
  @override
  _GifGeneratorState createState() => _GifGeneratorState();
}

class _GifGeneratorState extends State<GifGenerator> {
  final GlobalKey _globalKey = GlobalKey();
  String _text = "Hello, GitHub!";
  bool _isCapturing = false;
  Uint8List? _gifBytes;

  int _frameCount = 100; // Increased frame count for smoother animation
  Duration _animationDuration = const Duration(milliseconds: 5000); // Total duration of the text animation

  Future<List<img.Image>> _captureFrames(dynamic _) async {
    List<img.Image> frames = [];
    int intervalMillis = (_animationDuration.inMilliseconds / _frameCount).round();

    for (int i = 0; i < _frameCount; i++) {
      await Future.delayed(Duration(milliseconds: intervalMillis));
      try {
        RenderRepaintBoundary ? boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary == null) {
          print('Boundary is null');
          continue;
        }

        ui.Image image = await boundary.toImage(pixelRatio: 1.0);
        ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) {
          print('ByteData is null');
          continue;
        }
        Uint8List pngBytes = byteData.buffer.asUint8List();

        img.Image? frame = img.decodePng(pngBytes);
        if (frame == null) {
          print('Frame is null');
          continue;
        }

        img.Image resizedFrame = img.copyResize(frame, width: 360, height: 260);
        frames.add(resizedFrame);
      } catch (e) {
        print('Error capturing frame: $e');
      }
    }
    return frames;
  }


  Future<Uint8List?> _generateGif(List<img.Image> frames) async {
    final gifEncoder = img.GifEncoder(repeat: 0, delay: 3); // Reduced delay to speed up the GIF
    for (var frame in frames) {
      gifEncoder.addFrame(frame);
    }
    return Uint8List.fromList(gifEncoder.finish()!);
  }


  void _startCapture() async {
    setState(() {
      _isCapturing = true;
    });
    List<img.Image> frames = await compute(_captureFrames, null);
    _gifBytes = await compute(_generateGif, frames);

    setState(() {
      _isCapturing = false;
    });
  }


  void _downloadGif(Uint8List gifBytes) {
    // Convert the Uint8List to a Blob
    final blob = html.Blob([gifBytes], 'image/gif');

    // Create a new Anchor element
    final url = html.Url.createObjectUrlFromBlob(blob);
    final html.AnchorElement anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "animated_text.gif")
      ..click(); // Programmatically click the anchor to trigger download

    // Revoke the object URL after the download
    html.Url.revokeObjectUrl(url);
  }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Container(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            RepaintBoundary(
              key: _globalKey,
              child: Container(
                width: 360,
                height: 260,
                child: Center(
                  child: AnimatedTextKit(
                    animatedTexts: [
                      TypewriterAnimatedText(
                        _text,
                        textStyle: const TextStyle(
                          fontSize: 32.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                        speed: const Duration(milliseconds: 100),
                      ),
                    ],
                    repeatForever: true,
                  ),
                ),
              ),
            ),
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.7,
                child: TextFormField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: Colors.black87,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(
                        color: Colors.green,
                      ),
                    ),
                    hintText: "Input some text here",
                  ),
                  onChanged: (value) {
                    setState(() {
                      _text = value;
                    });
                  },
                ),
              ),
            ),


            SizedBox(height: 20,),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.all(20),
              ),
              onPressed: _isCapturing ? null : _startCapture,
              child: Text('Start Capture'),
            ),

            SizedBox(height: 30,),

            if (_isCapturing)
              CircularProgressIndicator(color: Colors.red,),
            if (_gifBytes != null && !_isCapturing)
              Column(
                children: [
                  Image.memory(_gifBytes!),

                  SizedBox(height: 10),

                  Container(
                    width: 260,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.all(20),
                      ),
                      onPressed: () => _downloadGif(_gifBytes!),
                      child: Text('Download GIF'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
