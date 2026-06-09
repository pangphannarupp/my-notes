import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

enum BackgroundPattern { solid, lined, grid }

class PatternPainter extends CustomPainter {
  final BackgroundPattern pattern;
  final Color color;

  PatternPainter(this.pattern, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (pattern == BackgroundPattern.solid) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    if (pattern == BackgroundPattern.lined) {
      const double spacing = 30.0;
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    } else if (pattern == BackgroundPattern.grid) {
      const double spacing = 30.0;
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
      for (double x = spacing; x < size.width; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PatternPainter oldDelegate) {
    return oldDelegate.pattern != pattern || oldDelegate.color != color;
  }
}

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  late SignatureController _controller;
  Color _penColor = Colors.black;
  Color _bgColor = Colors.white;
  Color _patternColor = Colors.black26;
  BackgroundPattern _pattern = BackgroundPattern.solid;
  double _strokeWidth = 5.0;
  bool _isEraser = false;

  final GlobalKey _canvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = SignatureController(
      penStrokeWidth: _strokeWidth,
      penColor: _isEraser ? _bgColor : _penColor,
      exportBackgroundColor: Colors.transparent,
    );
  }

  void _updateController() {
    final points = _controller.points;
    _controller.dispose();
    _initController();
    _controller.points = points;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveDrawing() async {
    if (_controller.isEmpty) {
      context.pop(null);
      return;
    }

    try {
      RenderRepaintBoundary boundary = _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/drawing_${const Uuid().v4()}.png');
      await file.writeAsBytes(bytes);
      context.pop(file.path);
    } catch (e) {
      context.pop(null);
    }
  }

  void _pickColor(bool isBackground) {
    Color tempColor = isBackground ? _bgColor : _penColor;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isBackground ? 'Background Color' : 'Pen Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: tempColor,
              onColorChanged: (color) {
                tempColor = color;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  if (isBackground) {
                    _bgColor = tempColor;
                  } else {
                    _penColor = tempColor;
                    _isEraser = false;
                  }
                  _updateController();
                });
                context.pop();
              },
              child: const Text('Select'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draw'),
        actions: [
          IconButton(icon: const Icon(Icons.undo), onPressed: () => _controller.undo()),
          IconButton(icon: const Icon(Icons.clear), onPressed: () => _controller.clear()),
          IconButton(icon: const Icon(Icons.check), onPressed: _saveDrawing),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RepaintBoundary(
              key: _canvasKey,
              child: Container(
                color: _bgColor,
                child: CustomPaint(
                  painter: PatternPainter(_pattern, _patternColor),
                  child: Signature(
                    controller: _controller,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
            ),
          ),
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text('Size:'),
                    Expanded(
                      child: Slider(
                        value: _strokeWidth,
                        min: 1.0,
                        max: 20.0,
                        onChanged: (val) {
                          setState(() {
                            _strokeWidth = val;
                            _updateController();
                          });
                        },
                      ),
                    ),
                    DropdownButton<BackgroundPattern>(
                      value: _pattern,
                      items: const [
                        DropdownMenuItem(value: BackgroundPattern.solid, child: Text('Solid')),
                        DropdownMenuItem(value: BackgroundPattern.lined, child: Text('Lined')),
                        DropdownMenuItem(value: BackgroundPattern.grid, child: Text('Grid')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          if (val != null) _pattern = val;
                        });
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      icon: Icon(Icons.color_lens, color: _penColor),
                      label: const Text('Pen'),
                      onPressed: () => _pickColor(false),
                    ),
                    TextButton.icon(
                      icon: Icon(Icons.format_color_fill, color: _bgColor == Colors.white ? Colors.black : _bgColor),
                      label: const Text('BG'),
                      onPressed: () => _pickColor(true),
                    ),
                    FilterChip(
                      label: const Text('Eraser'),
                      selected: _isEraser,
                      onSelected: (val) {
                        setState(() {
                          _isEraser = val;
                          _updateController();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
