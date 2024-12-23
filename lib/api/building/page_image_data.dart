import 'dart:async';
import 'dart:ui' as ui;

import 'package:campus_navigator/api/building/parsing/common.dart';
import 'package:flutter/material.dart';

import 'parsing/common.dart' as common;
import 'parsing/layer_data.dart';

class PageImageData with ChangeNotifier {
  Map<String, ui.Image> imageMap = {};
  late int qualiStep;

  PageImageData({
    required this.qualiStep,
    required this.imageMap,
  });

  ui.Image? getLayerSymbol(String symbolName) {
    return imageMap[symbolName];
  }

  ui.Image? getBackgroundImage(int x, int y) {
    return imageMap["${x}_$y"];
  }

  /// Starts fetching all images for a floor plan given the `pngFileName` of
  /// the current page and all it's layers(needed for fetching of the symbolds)
  PageImageData.fetchLevelImages(String pngFileName, List<LayerData> layers,
      {int qualiIndex = 3}) {
    final List<int> qualiSteps = [1, 2, 4, 8];
    qualiStep = qualiSteps[qualiIndex];

    // Holds all futures
    List<Future<(String, ui.Image?)>> imageFutures = [];

    // Background tiles
    for (int x = 0; x < qualiStep; x++) {
      for (int y = 0; y < qualiStep; y++) {
        final uri = Uri.parse(
            "$baseURL/images/etplan_cache/${pngFileName}_$qualiStep/${x}_$y.png/nobase64");

        final imageFuture =
            common.fetchImage(uri).then((image) => ("${x}_$y", image));

        imageFutures.add(imageFuture);
      }
    }

    // Layer symbols
    for (final layer in layers) {
      final imageFuture = common
          .fetchImage(layer.getSymbolUri())
          .then((image) => (layer.symbolPNG, image));

      imageFutures.add(imageFuture);
    }

    imageMap = {};
    for (final future in imageFutures) {
      future.then((e) {
        if (e.$2 == null) return;
        imageMap[e.$1] = e.$2!;
        notifyListeners();
      });
    }
  }
}
