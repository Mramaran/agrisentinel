import 'dart:typed_data';
import 'package:image/image.dart' as img;

class LeafAnalysis {
  final bool isLeaf;
  final double leafFraction;
  final double lesionFraction;
  final double yellowFraction;
  final double brownFraction;
  final double darkFraction;
  final double quality; // 0..1, higher is sharper
  final Uint8List maskPng; // lesion pixels tinted red over a dimmed image

  const LeafAnalysis({
    required this.isLeaf,
    required this.leafFraction,
    required this.lesionFraction,
    required this.yellowFraction,
    required this.brownFraction,
    required this.darkFraction,
    required this.quality,
    required this.maskPng,
  });

  double get severityPct => lesionFraction * 100;
}

enum _Px { background, green, yellow, brown, dark }

_Px _classify(int r, int g, int b) {
  final sum = r + g + b;
  if (g > r + 15 && g > b + 15) return _Px.green;
  if (r > 140 && g > 120 && b < 110 && r >= g) return _Px.yellow;
  if (r > g && g >= b && r > 60 && (r - b) > 40 && r < 200) return _Px.brown;
  if (sum < 150) return _Px.dark;
  return _Px.background;
}

/// Marks every pixel reachable from the image border without crossing plant
/// tissue. Those are outside the leaf; anything left is enclosed by it.
List<bool> _floodFromBorder(List<bool> tissue, int w, int h) {
  final outside = List<bool>.filled(w * h, false);
  final stack = <int>[];
  void push(int i) {
    if (!tissue[i] && !outside[i]) {
      outside[i] = true;
      stack.add(i);
    }
  }

  for (var x = 0; x < w; x++) {
    push(x);
    push((h - 1) * w + x);
  }
  for (var y = 0; y < h; y++) {
    push(y * w);
    push(y * w + w - 1);
  }
  while (stack.isNotEmpty) {
    final i = stack.removeLast();
    final x = i % w, y = i ~/ w;
    if (x > 0) push(i - 1);
    if (x < w - 1) push(i + 1);
    if (y > 0) push(i - w);
    if (y < h - 1) push(i + w);
  }
  return outside;
}

LeafAnalysis analyzeLeaf(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return LeafAnalysis(
      isLeaf: false, leafFraction: 0, lesionFraction: 0, yellowFraction: 0,
      brownFraction: 0, darkFraction: 0, quality: 0, maskPng: Uint8List(0),
    );
  }
  final im = img.copyResize(decoded, width: 160);
  final w = im.width, h = im.height;
  int green = 0, yellow = 0, brown = 0, dark = 0;
  final classes = List<_Px>.filled(w * h, _Px.background);
  final gray = List<double>.filled(w * h, 0);

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = im.getPixel(x, y);
      final r = p.r.toInt(), g = p.g.toInt(), b = p.b.toInt();
      classes[y * w + x] = _classify(r, g, b);
      gray[y * w + x] = 0.299 * r + 0.587 * g + 0.114 * b;
    }
  }

  // Dark pixels are ambiguous: necrotic blight looks the same as soil, shadow
  // or foliage behind the leaf. Green, yellow and brown are unambiguously plant
  // tissue, so grow that mask and keep only the dark pixels lying inside it.
  // Necrosis at a leaf margin sits within a few pixels of live tissue and is
  // kept; dark background away from the leaf is dropped.
  final tissue = List<bool>.filled(w * h, false);
  for (var i = 0; i < w * h; i++) {
    final c = classes[i];
    tissue[i] = c == _Px.green || c == _Px.yellow || c == _Px.brown;
  }
  final outside = _floodFromBorder(tissue, w, h);
  for (var i = 0; i < w * h; i++) {
    if (classes[i] == _Px.dark && outside[i]) classes[i] = _Px.background;
  }

  for (var i = 0; i < w * h; i++) {
    switch (classes[i]) {
      case _Px.green: green++;
      case _Px.yellow: yellow++;
      case _Px.brown: brown++;
      case _Px.dark: dark++;
      case _Px.background: break;
    }
  }

  final total = w * h;
  final leafPx = green + yellow + brown + dark;
  final leafFraction = leafPx / total;
  final lesionPx = yellow + brown + dark;
  final lesionFraction = leafPx == 0 ? 0.0 : lesionPx / leafPx;

  // Blur score: variance of a 4-neighbour Laplacian over leaf pixels.
  // Pixels touching the background are skipped, otherwise the leaf outline
  // swamps the measurement and every image reads as sharp.
  double sum = 0, sumSq = 0;
  int n = 0;
  for (var y = 1; y < h - 1; y++) {
    for (var x = 1; x < w - 1; x++) {
      final i = y * w + x;
      if (classes[i] == _Px.background) continue;
      if (classes[i - 1] == _Px.background ||
          classes[i + 1] == _Px.background ||
          classes[i - w] == _Px.background ||
          classes[i + w] == _Px.background) {
        continue;
      }
      final lap = 4 * gray[i] - gray[i - 1] - gray[i + 1] - gray[i - w] - gray[i + w];
      sum += lap;
      sumSq += lap * lap;
      n++;
    }
  }
  final variance = n == 0 ? 0.0 : (sumSq / n) - (sum / n) * (sum / n);
  final quality = (variance / 400).clamp(0.0, 1.0);

  // Mask: dim everything, tint lesion pixels red.
  final mask = img.Image.from(im);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final c = classes[y * w + x];
      final p = mask.getPixel(x, y);
      if (c == _Px.yellow || c == _Px.brown || c == _Px.dark) {
        mask.setPixelRgb(x, y, 220, 40, 40);
      } else {
        mask.setPixelRgb(x, y, (p.r * 0.5).toInt(), (p.g * 0.5).toInt(), (p.b * 0.5).toInt());
      }
    }
  }

  return LeafAnalysis(
    isLeaf: leafFraction > 0.25 && green / total > 0.08,
    leafFraction: leafFraction,
    lesionFraction: lesionFraction,
    yellowFraction: leafPx == 0 ? 0 : yellow / leafPx,
    brownFraction: leafPx == 0 ? 0 : brown / leafPx,
    darkFraction: leafPx == 0 ? 0 : dark / leafPx,
    quality: quality,
    maskPng: Uint8List.fromList(img.encodePng(mask)),
  );
}
