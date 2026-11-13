import 'package:flutter_riverpod/flutter_riverpod.dart';

/// When true the mascot always shows its still poster (tests override this
/// to true because the 3D WebView cannot render in widget tests).
final Provider<bool> mascotPosterOnlyProvider = Provider<bool>((ref) => false);
