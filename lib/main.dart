import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:complex/complex.dart';
import 'package:flutter/material.dart';

const maxIter = 1000;

var x0 = -2.0;
var x1 = 1.0;
var y0 = -1.0;
var y1 = 1.0;

int _mandelbrot(double x, double y) {
  final C = Complex(x, y);
  var z = C;
  for (int i = 1; i < maxIter; i++) {
    z = (z * z) + C;
    if (z.abs() > 20.0) {
      return i;
    }
  }
  return maxIter;
}

Future<ui.Image> drawMandelbrot(int width, int height) async {
  Color getColorFromValue(int index) {
    const div = 256;
    final divIndex = index % div;
    final hue = ((divIndex.toDouble() / (div)) * 360.0) +
        25; // 0부터 128까지의 값을 0부터 360까지의 색상(Hue) 값으로 변환
    const saturation = 0.75; // 채도(Saturation) 값은 일정하게 설정
    const value = 1.0; // 명도(Value) 값은 일정하게 설정
    final color =
        HSVColor.fromAHSV(1.0, hue % 360, saturation, value).toColor();
    return color;
  }

  final c = Completer<ui.Image>();

  final w = x1 - x0;
  final h = y1 - y0;

  final pixels = <int>[];
  for (int i = 0; i < height; i++) {
    for (int j = 0; j < width; j++) {
      // 해상도 좌표를 좌표축상의 좌표로 변환
      final x = ((j * w) / width) + x0;
      final y = ((i * h) / height) + y0;

      // 해당 좌표가 만델브로 집합군에 속하는지 확인 (발산 Count 확인)
      int count = _mandelbrot(x, y);
      if (count < maxIter) {
        // 발산은 발산 Count별 색상 출력
        final color = getColorFromValue(count);
        pixels.add(color.red);
        pixels.add(color.green);
        pixels.add(color.blue);
        pixels.add(0xff);
      } else {
        // 수렴은 검정색
        pixels.add(0x00);
        pixels.add(0x00);
        pixels.add(0x00);
        pixels.add(0xff);
      }
    }
  }

  ui.decodeImageFromPixels(
      Uint8List.fromList(pixels), width, height, ui.PixelFormat.rgba8888,
      (image) {
    c.complete(image);
  });

  return c.future;
}

class ImagePainter extends CustomPainter {
  final ui.Image image;

  ImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(ImagePainter oldDelegate) {
    return false;
  }
}

class Mandelbrot extends StatefulWidget {
  const Mandelbrot({super.key});

  @override
  State<Mandelbrot> createState() => _MandelbrotState();
}

class _MandelbrotState extends State<Mandelbrot> {
  ui.Image? _image;

  var nx0 = x0;
  var nx1 = x1;
  var ny0 = y0;
  var ny1 = y1;

  var gx0 = 0.0;
  var gx1 = 0.0;
  var gy0 = 0.0;
  var gy1 = 0.0;

  void redraw() {
    const unitSize = 512;
    drawMandelbrot(unitSize * 3, unitSize * 2)
        .then((image) => setState(() => _image = image));
  }

  @override
  void initState() {
    super.initState();
    redraw();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onPanDown: (details) {
                  gx0 = gx1 = details.globalPosition.dx;
                  gy0 = gy1 = details.globalPosition.dy;
                  nx0 = ((gx0 * (x1 - x0)) / width) + x0;
                  ny0 = ((gy0 * (y1 - y0)) / height) + y0;
                  setState(() {});
                },
                onPanEnd: (details) {
                  x0 = nx0;
                  y0 = ny0;
                  x1 = nx1;
                  y1 = ny1;
                  gx0 = gx1 = gy0 = gy1 = 0.0;

                  redraw();
                },
                onPanUpdate: (details) {
                  gx1 = details.globalPosition.dx;
                  gy1 = details.globalPosition.dy;
                  nx1 = ((gx1 * (x1 - x0)) / width) + x0;
                  ny1 = ((gy1 * (y1 - y0)) / height) + y0;
                  setState(() {});
                },
                child: _image != null
                    ? CustomPaint(
                        painter: ImagePainter(_image!),
                      )
                    : const Center(
                        child: SizedBox(
                          width: 200,
                          height: 200,
                          child: CircularProgressIndicator(),
                        ),
                      ),
              ),
            ),
            Positioned(
              left: gx0,
              top: gy0,
              child: Container(
                width: gx1 - gx0,
                height: (gy1 - gy0).abs(),
                color: Colors.blue.withOpacity(0.25),
              ),
            ),
          ],
        );
      },
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: Mandelbrot(),
  ));
}
