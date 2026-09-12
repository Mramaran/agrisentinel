import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:agrisentinel_demo/core/leaf_analysis.dart';

Uint8List _png(img.Image i) => Uint8List.fromList(img.encodePng(i));

img.Image _leaf({double lesion = 0.0, bool blurry = false}) {
  final i = img.Image(width: 100, height: 100);
  for (var y = 0; y < 100; y++) {
    for (var x = 0; x < 100; x++) {
      final inLeaf = x >= 10 && x < 90 && y >= 10 && y < 90; // 6400 leaf px
      if (!inLeaf) {
        i.setPixelRgb(x, y, 240, 240, 240); // background
      } else if (x < 10 + (80 * lesion)) {
        i.setPixelRgb(x, y, 120, 70, 30); // brown lesion
      } else {
        // green with texture so quality is high
        final t = ((x + y) % 2 == 0 && !blurry) ? 30 : 0;
        i.setPixelRgb(x, y, 40 + t, 150 + t, 40);
      }
    }
  }
  return i;
}

void main() {
  test('healthy synthetic leaf: is leaf, near-zero lesion', () {
    final a = analyzeLeaf(_png(_leaf()));
    expect(a.isLeaf, true);
    expect(a.leafFraction, greaterThan(0.5));
    expect(a.severityPct, lessThan(2));
  });

  test('30 percent brown lesion is measured near 30', () {
    final a = analyzeLeaf(_png(_leaf(lesion: 0.3)));
    expect(a.severityPct, closeTo(30, 6));
    expect(a.brownFraction, greaterThan(a.yellowFraction));
  });

  test('flat grey image is not a leaf', () {
    final i = img.Image(width: 50, height: 50)..clear(img.ColorRgb8(200, 200, 200));
    final a = analyzeLeaf(_png(i));
    expect(a.isLeaf, false);
  });

  test('textured leaf has higher quality than blurry leaf', () {
    final sharp = analyzeLeaf(_png(_leaf()));
    final blur = analyzeLeaf(_png(_leaf(blurry: true)));
    expect(sharp.quality, greaterThan(blur.quality));
  });

  test('mask png decodes to same size as resized input', () {
    final a = analyzeLeaf(_png(_leaf(lesion: 0.2)));
    final m = img.decodePng(a.maskPng)!;
    expect(m.width, 160);
  });

  test('dark background is not counted as lesion', () {
    // Green leaf on a near-black ground, with one dark necrotic patch on the
    // leaf itself. Only the patch should register.
    final i = img.Image(width: 100, height: 100);
    for (var y = 0; y < 100; y++) {
      for (var x = 0; x < 100; x++) {
        final inLeaf = x >= 20 && x < 80 && y >= 20 && y < 80; // 3600 px
        final inPatch = x >= 30 && x < 42 && y >= 30 && y < 42; // 144 px = 4%
        if (!inLeaf) {
          i.setPixelRgb(x, y, 20, 22, 18); // dark soil/shadow
        } else if (inPatch) {
          i.setPixelRgb(x, y, 25, 20, 15); // necrosis on the leaf
        } else {
          i.setPixelRgb(x, y, 40 + ((x + y) % 2 == 0 ? 30 : 0), 150, 40);
        }
      }
    }
    final a = analyzeLeaf(_png(i));
    expect(a.isLeaf, true);
    // The patch is 144 of 3600 leaf px = 4%. If the background counted, the
    // lesion share would be far higher.
    expect(a.severityPct, closeTo(4, 3));
  });
}
