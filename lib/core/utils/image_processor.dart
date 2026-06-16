import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

enum SketchFilter {
  none,
  pencilSketch,
  inkDrawing,
  outline,
  tattooStencil,
  coloringPage,
}

class ImageProcessorParams {
  final String inputPath;
  final String outputPath;
  final SketchFilter filter;
  final double intensity; // 0.0 to 1.0 parameter
  final bool removeBackground;
  final int bgColorToRemove; // Hex color (AARRGGBB)
  final double bgTolerance; // 0.0 to 1.0

  ImageProcessorParams({
    required this.inputPath,
    required this.outputPath,
    required this.filter,
    this.intensity = 0.5,
    this.removeBackground = false,
    this.bgColorToRemove = 0xFFFFFFFF, // Default white
    this.bgTolerance = 0.15,
  });
}

class ImageProcessor {
  // Public method to run image processing in a background Isolate
  static Future<String> processImage(ImageProcessorParams params) async {
    return await compute(_processInBackground, params);
  }

  // Isolate worker function
  static Future<String> _processInBackground(ImageProcessorParams params) async {
    final bytes = await File(params.inputPath).readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) throw Exception("Failed to decode image");

    // 1. Apply Filters
    switch (params.filter) {
      case SketchFilter.pencilSketch:
        image = _applyPencilSketch(image, params.intensity);
        break;
      case SketchFilter.inkDrawing:
        image = _applyInkDrawing(image, params.intensity);
        break;
      case SketchFilter.outline:
        image = _applySobelOutline(image, params.intensity);
        break;
      case SketchFilter.tattooStencil:
        image = _applyTattooStencil(image, params.intensity);
        break;
      case SketchFilter.coloringPage:
        image = _applyColoringPage(image, params.intensity);
        break;
      case SketchFilter.none:
      default:
        break;
    }

    // 2. Local Background Removal
    if (params.removeBackground) {
      image = _removeBackground(image, params.bgColorToRemove, params.bgTolerance);
    }

    // 3. Save Output file
    final encoded = img.encodePng(image);
    final outFile = File(params.outputPath);
    await outFile.writeAsBytes(encoded);
    return outFile.path;
  }

  // 1. Pencil Sketch Filter
  // Concept: Grayscale + Invert + Gaussian Blur + Color Dodge
  static img.Image _applyPencilSketch(img.Image src, double intensity) {
    // 1. Grayscale
    final gray = img.grayscale(img.Image.from(src));
    
    // 2. Invert Grayscale
    final inverted = img.invert(img.Image.from(gray));

    // 3. Gaussian Blur based on intensity (kernel size 3 to 15)
    final blurRadius = (3 + (intensity * 12)).round();
    final blurred = img.gaussianBlur(inverted, radius: blurRadius);

    // 4. Color Dodge blend mode: dest / (1 - src)
    final result = img.Image(width: src.width, height: src.height, numChannels: 4);

    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        final gPixel = gray.getPixel(x, y);
        final bPixel = blurred.getPixel(x, y);

        final gVal = gPixel.r.toInt();
        final bVal = bPixel.r.toInt();

        // Color dodge blend formula
        int dodgeVal = 255;
        if (bVal < 255) {
          dodgeVal = ((gVal << 8) / (255 - bVal)).round();
          if (dodgeVal > 255) dodgeVal = 255;
        }

        // Apply back with alpha
        result.setPixelRgba(x, y, dodgeVal, dodgeVal, dodgeVal, gPixel.a.toInt());
      }
    }
    return result;
  }

  // 2. Ink Drawing Filter
  // High contrast thresholding + clean details
  static img.Image _applyInkDrawing(img.Image src, double intensity) {
    final gray = img.grayscale(img.Image.from(src));
    // Dynamic threshold based on intensity (e.g. 80 to 180)
    final threshold = (80 + (intensity * 100)).round();

    final result = img.Image(width: src.width, height: src.height, numChannels: 4);
    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        final pixel = gray.getPixel(x, y);
        final grayVal = pixel.r.toInt();
        
        final inkVal = (grayVal < threshold) ? 0 : 255;
        result.setPixelRgba(x, y, inkVal, inkVal, inkVal, pixel.a.toInt());
      }
    }
    return result;
  }

  // 3. Sobel Edge Detection (Outline)
  static img.Image _applySobelOutline(img.Image src, double intensity) {
    final gray = img.grayscale(img.Image.from(src));
    final result = img.Image(width: src.width, height: src.height, numChannels: 4);
    
    // Sobel kernels
    const kx = [-1, 0, 1, -2, 0, 2, -1, 0, 1];
    const ky = [-1, -2, -1, 0, 0, 0, 1, 2, 1];

    final sensitivity = 1.0 + (intensity * 9.0); // Multiplier for edges

    for (int y = 1; y < src.height - 1; y++) {
      for (int x = 1; x < src.width - 1; x++) {
        double px = 0.0;
        double py = 0.0;

        // Apply Sobel convolution
        for (int cy = -1; cy <= 1; cy++) {
          for (int cx = -1; cx <= 1; cx++) {
            final val = gray.getPixel(x + cx, y + cy).r.toDouble();
            final kidx = (cy + 1) * 3 + (cx + 1);
            px += val * kx[kidx];
            py += val * ky[kidx];
          }
        }

        // Gradient magnitude
        double mag = sqrt(px * px + py * py) * sensitivity;
        int edgeVal = (255 - mag.clamp(0.0, 255.0)).round();

        final origPixel = src.getPixel(x, y);
        result.setPixelRgba(x, y, edgeVal, edgeVal, edgeVal, origPixel.a.toInt());
      }
    }
    
    // Fill edges with white
    for (int x = 0; x < src.width; x++) {
      result.setPixelRgba(x, 0, 255, 255, 255, 255);
      result.setPixelRgba(x, src.height - 1, 255, 255, 255, 255);
    }
    for (int y = 0; y < src.height; y++) {
      result.setPixelRgba(0, y, 255, 255, 255, 255);
      result.setPixelRgba(src.width - 1, y, 255, 255, 255, 255);
    }

    return result;
  }

  // 4. Tattoo Stencil Filter
  // High contrast edge outline with binary thresholding
  static img.Image _applyTattooStencil(img.Image src, double intensity) {
    // Sobel outline first
    final outline = _applySobelOutline(src, intensity);
    final result = img.Image(width: src.width, height: src.height, numChannels: 4);

    // Apply high threshold to keep only strong lines
    final threshold = 230 - (intensity * 50).round();

    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        final pixel = outline.getPixel(x, y);
        final val = pixel.r.toInt();
        // If darker than threshold, make black. Otherwise, white.
        final stencilVal = (val < threshold) ? 0 : 255;
        result.setPixelRgba(x, y, stencilVal, stencilVal, stencilVal, pixel.a.toInt());
      }
    }
    return result;
  }

  // 5. Coloring Page Filter
  // Delicate contours, removing inner shading
  static img.Image _applyColoringPage(img.Image src, double intensity) {
    // Smooth first to remove details
    final smoothed = img.gaussianBlur(img.Image.from(src), radius: 2);
    // Sobel on smoothed
    final outline = _applySobelOutline(smoothed, intensity * 0.7);
    
    final result = img.Image(width: src.width, height: src.height, numChannels: 4);
    
    // Thin edges using strict binarization
    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        final pixel = outline.getPixel(x, y);
        final val = pixel.r.toInt();
        final lineVal = (val < 240) ? 0 : 255;
        result.setPixelRgba(x, y, lineVal, lineVal, lineVal, pixel.a.toInt());
      }
    }
    return result;
  }

  // 6. Local Background Removal
  // Compare each pixel with a target background color (AARRGGBB) using color-space distance tolerance.
  static img.Image _removeBackground(img.Image src, int hexColor, double tolerance) {
    final targetA = (hexColor >> 24) & 0xFF;
    final targetR = (hexColor >> 16) & 0xFF;
    final targetG = (hexColor >> 8) & 0xFF;
    final targetB = hexColor & 0xFF;

    final result = img.Image(width: src.width, height: src.height, numChannels: 4);
    
    // Euclidean distance threshold in RGB space (max is sqrt(255^2 * 3) ~ 441.67)
    final maxDistance = sqrt(255 * 255 * 3);
    final distanceThreshold = tolerance * maxDistance;

    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        final pixel = src.getPixel(x, y);
        
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        final a = pixel.a.toInt();

        // Calculate color distance
        final dr = r - targetR;
        final dg = g - targetG;
        final db = b - targetB;
        final distance = sqrt(dr * dr + dg * dg + db * db);

        if (distance <= distanceThreshold) {
          // Transparent
          result.setPixelRgba(x, y, r, g, b, 0);
        } else {
          // Keep pixel
          result.setPixelRgba(x, y, r, g, b, a);
        }
      }
    }
    return result;
  }
}
