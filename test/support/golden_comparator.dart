import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Share of pixels that may differ before a golden test fails (0.5%).
/// It only absorbs tiny anti-alias noise; any real change is far above it.
const double goldenTolerance = 0.005;

/// A [LocalFileComparator] that passes when at most [goldenTolerance] of
/// the pixels differ. Failures write the usual `failures/` images next to
/// the golden (git-ignored; CI uploads them).
class ToleranceFileComparator extends LocalFileComparator {
  ToleranceFileComparator(super.testFile, {this.tolerance = goldenTolerance});

  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= tolerance) {
      result.dispose();
      return true;
    }
    final String error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}

/// Swaps the default comparator for [ToleranceFileComparator], keeping the
/// folder of the test file.
void useToleranceComparator() {
  final GoldenFileComparator current = goldenFileComparator;
  if (current is LocalFileComparator && current is! ToleranceFileComparator) {
    goldenFileComparator = ToleranceFileComparator(
      current.basedir.resolve('test.dart'),
    );
  }
}
