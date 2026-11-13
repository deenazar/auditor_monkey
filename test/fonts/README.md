# Test-only font

`Roboto-Regular.ttf` is copied from the Flutter SDK (`bin/cache/artifacts/material_fonts`, Apache License 2.0). The app fonts (Unbounded, DM Sans, DM Mono) have no rupee sign, so on a real phone the system font draws it. Tests have no system font, so `test/flutter_test_config.dart` loads this file as the fallback family `RupeeFallback`, and golden tests add it as a font fallback. It is never part of the app.
