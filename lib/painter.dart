import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:campus_navigator/api/building.dart';

// https://stackoverflow.com/questions/55147586/flutter-convert-color-to-hex-string
Color fromHex(String hexString) {
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

class MapPainter extends CustomPainter {
  final RoomResult roomResult;

  const MapPainter({
    required this.roomResult,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Setup correct scalign and offset so everything will fit into the given size
    Rect drawingArea = calculateDrawingArea();
    double scale = size.width / drawingArea.width;
    scale = min(scale, size.height / drawingArea.height);

    // Translate & Scale coordinate system
    canvas.scale(scale);
    canvas.translate(-drawingArea.topLeft.dx, -drawingArea.topLeft.dy);

    // Paint background image
    if (roomResult.backgroundImage != null) {
      // canvas.scale(1 / 4);
      double x = 0;
      double y = 0;
      int qualiCur = 0;
      List<double> qualiSteps = [1, 2, 4, 8];

      double canvWidth = roomResult.numberVariables["data_canv_width"]!;
      double canvHeight = roomResult.numberVariables["data_canv_height"]!;
      double qualiSize =
          roomResult.numberVariables["subpics_size"]! / qualiSteps[qualiCur];

      var imageOffset = Offset((-0.5 * canvWidth) + (x * qualiSize),
          (-0.5 * canvHeight) + (y * qualiSize));

      //print(
      //    "canvWidth: $canvWidth, canvHeight: $canvHeight, qualiSize: $qualiSize, imageOffset: $imageOffset");
      canvas.drawImage(roomResult.backgroundImage!, imageOffset, Paint());
    }

    final strokePaint = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..color = Colors.black.withAlpha(120);

    for (final RoomData r in roomResult.rooms) {
      for (int i = 0; i < r.points.length; i++) {
        for (int j = 0; j < r.points[i].length; j++) {
          final pointList = r.points[i][j];
          final fill = r.fills[i];

          var color = fill != null ? fromHex(fill) : Colors.red;

          // Normal rooms
          if (color.red == 240) color = Colors.grey;
          color = color.withAlpha(50);

          final fillPaint = Paint()
            ..strokeWidth = 2
            ..style = PaintingStyle.fill
            ..color = color;

          var path = Path();
          final mapped = mapPoints(pointList);

          if (mapped.isNotEmpty) {
            path.moveTo(mapped[0].dx, mapped[0].dy);

            for (final p in mapped.skip(0)) {
              path.lineTo(p.dx, p.dy);
            }
          }
          path.close();

          canvas.drawPath(path, fillPaint);
          canvas.drawPath(path, strokePaint);
        }
      }
    }

    var symbolPaint = Paint()
      ..strokeWidth = 4
      ..color = Colors.teal;

    for (final LayerData l in roomResult.layers) {
      canvas.drawPoints(PointMode.points, mapPoints2(l.symbol), symbolPaint);
    }

    // Beschriftungen
    for (final entry in roomResult.raumBezData.fills) {
      final txt = entry.qy;
      final offset = Offset(entry.x, entry.y);

      const width = 100.0;

      //const fontSize = 15.0;
      double fontSize = min(entry.my, entry.mx / entry.qy.length);

      final textPainter = TextPainter(
          text: TextSpan(
            text: txt,
            style: TextStyle(
              color: Colors.black,
              fontSize: fontSize,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center);

      textPainter.layout(minWidth: width, maxWidth: width);

      // Aligning the text vertically and horizontally
      // 0.15 is because the text won't be perfectly vertically centere
      textPainter.paint(canvas,
          offset.translate(-width / 2, -((fontSize / 2) + fontSize * 0.15)));
    }
  }

  @override
  bool shouldRepaint(MapPainter oldDelegate) {
    return roomResult.htmlData != oldDelegate.roomResult.htmlData;
  }

  Rect calculateDrawingArea() {
    var allPoints = roomResult.rooms
        .expand((r) => r.points.expand((p) => p.expand(mapPoints)))
        .toList();

    var minX = allPoints.fold(allPoints[0].dx,
        (previousValue, element) => min(previousValue, element.dx));

    var maxX = allPoints.fold(allPoints[0].dx,
        (previousValue, element) => max(previousValue, element.dx));

    var minY = allPoints.fold(allPoints[0].dy,
        (previousValue, element) => min(previousValue, element.dy));

    var maxY = allPoints.fold(allPoints[0].dy,
        (previousValue, element) => max(previousValue, element.dy));

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}

List<Offset> mapPoints(List<double> rawPoints) {
  List<Offset> chunks = [];
  int chunkSize = 2;
  for (var i = 0; i < rawPoints.length; i += chunkSize) {
    var point = Offset(rawPoints[i], rawPoints[i + 1]);
    chunks.add(point);
  }
  return chunks;
}

List<Offset> mapPoints2(List<Position> rawPoints) {
  List<Offset> chunks = [];
  for (var i = 0; i < rawPoints.length; i++) {
    var point = Offset(rawPoints[i].x as double, rawPoints[i].y as double);
    chunks.add(point);
  }
  return chunks;
}
