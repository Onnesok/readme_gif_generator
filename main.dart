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
  bool _isCapturing = false;
  Uint8List? _gifBytes;

  int _frameCount = 100; // Frame count for smoother animation
  Duration _animationDuration = const Duration(milliseconds: 5000); // Total duration of the text animation
  int _gifDelay = 3; // Delay between frames in the GIF

  // TextEditingControllers for the four input fields
  final TextEditingController _controller1 = TextEditingController(text: "Hello world");
  final TextEditingController _controller2 = TextEditingController(text: "I am Ratul Hasan");
  final TextEditingController _controller3 = TextEditingController(text: "Programmer");
  final TextEditingController _controller4 = TextEditingController(text: "Problem solver");

  Future<List<img.Image>> _captureFrames(dynamic _) async {
    List<img.Image> frames = [];
    int intervalMillis = (_animationDuration.inMilliseconds / _frameCount).round();

    for (int i = 0; i < _frameCount; i++) {
      await Future.delayed(Duration(milliseconds: intervalMillis));
      try {
        RenderRepaintBoundary? boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
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

        // Resize frame to its original size (no constraint)
        img.Image resizedFrame = img.copyResize(frame, width: frame.width, height: frame.height);
        frames.add(resizedFrame);
      } catch (e) {
        print('Error capturing frame: $e');
      }
    }
    return frames;
  }


  Future<Uint8List?> _generateGif(List<img.Image> frames) async {
    // Use user-defined delay
    final gifEncoder = img.GifEncoder(repeat: 0, delay: _gifDelay);
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
      child: Center(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[

              RepaintBoundary(
                key: _globalKey,
                child: Container(
                  color: Colors.transparent,
                  child: Center(
                    child: AnimatedTextKit(
                      animatedTexts: [
                        for (final txt in [_controller1.text, _controller2.text, _controller3.text, _controller4.text])
                          TypewriterAnimatedText(
                            txt,
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
              SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.4,
                    child: Column(
                      children: [
                        // Four TextFormFields for user input :)
                        ...[
                          _controller1,
                          _controller2,
                          _controller3,
                          _controller4
                        ].map((controller) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5.0),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.8,
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
                                hintText: "Your text",
                              ),
                              controller: controller,
                              onChanged: (value) => setState(() {}),
                            ),
                          ),
                        )),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),

                  SizedBox(width: 20,),

                  Container(
                    width: MediaQuery.of(context).size.width * 0.4,
                    margin: EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Container(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.settings, color: Colors.black87.withOpacity(0.6),),
                              Text("Settings", style: TextStyle(fontWeight: FontWeight.bold,color: Colors.grey, fontStyle: FontStyle.italic),),
                            ],
                          ),
                        ),
                        SizedBox(height: 20,),

                        Text('Animation Duration: ${_animationDuration.inSeconds} seconds'),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: Slider(
                            value: _animationDuration.inSeconds.toDouble(),
                            min: 1,
                            max: 10,
                            divisions: 9,
                            label: '${_animationDuration.inSeconds} seconds',
                            onChanged: (value) {
                              setState(() {
                                _animationDuration = Duration(seconds: value.toInt());
                              });
                            },
                          ),
                        ),

                        Text('Frame Count: $_frameCount'),

                        Container(
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: Slider(
                            value: _frameCount.toDouble(),
                            min: 20,
                            max: 200,
                            divisions: 18,
                            label: '$_frameCount frames',
                            onChanged: (value) {
                              setState(() {
                                _frameCount = value.toInt();
                              });
                            },
                          ),
                        ),

                        Text('GIF Delay (ms): $_gifDelay'),

                        Container(
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: Slider(
                            value: _gifDelay.toDouble(),
                            min: 1,
                            max: 10,
                            divisions: 9,
                            label: '$_gifDelay ms',
                            onChanged: (value) {
                              setState(() {
                                _gifDelay = value.toInt();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                ],
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
      ),
    );
  }
}
