import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every original illustration in `assets/illustrations/`. Each one must
/// exist, stay small, use DESIGN.md colour tokens only and avoid text,
/// gradients and filters (flutter_svg draws them, but they break the flat
/// style and the size budget).
const List<String> _names = <String>[
  'empty_accounts',
  'empty_transactions',
  'empty_statement',
  'empty_insights',
  'empty_home',
  'error_generic',
  'wizard_welcome',
  'wizard_pick',
  'wizard_balances',
  'wizard_done',
  'mascot_poster',
];

/// DESIGN.md "Illustrations" palette, lower case, `#RRGGBB`.
const Set<String> _allowedHex = <String>{
  '#10202a', // ink
  '#5e6e76', // inkMuted (sec)
  '#ff6b4a', // coral
  '#0e9f9a', // teal
  '#ffd86e', // warm yellow (today bar top)
  '#ffc24d', // sun (night / burst)
  '#dfe7e5', // line
  '#ebf1ef', // fill
  '#f5f8f7', // panel
  '#ffffff', // card (white)
  '#ffe3db', // navIndicator
  '#c2410c', // accentText
};

const int _maxBytes = 8 * 1024;

final RegExp _paintAttr = RegExp(r'(fill|stroke|stop-color)="([^"]*)"');

void main() {
  group('illustrations', () {
    for (final String name in _names) {
      final String path = 'assets/illustrations/$name.svg';

      test('$name exists and is under 8KB', () {
        final File file = File(path);
        expect(file.existsSync(), isTrue, reason: 'missing $path');
        expect(file.lengthSync(), lessThan(_maxBytes), reason: path);
      });

      test('$name uses only DESIGN.md colours', () {
        final String svg = File(path).readAsStringSync();
        final Iterable<RegExpMatch> matches = _paintAttr.allMatches(svg);
        expect(matches, isNotEmpty, reason: '$path has no paint attributes');
        for (final RegExpMatch match in matches) {
          final String value = match.group(2)!.trim().toLowerCase();
          if (value == 'none') continue;
          expect(
            _allowedHex.contains(value),
            isTrue,
            reason: '$path uses $value, which is not a DESIGN.md token',
          );
        }
      });

      test('$name has no text, gradients or filters', () {
        final String svg = File(path).readAsStringSync();
        const List<String> banned = <String>[
          '<text',
          'Gradient',
          '<filter',
          '<mask',
          '<clipPath',
          '<image',
          '<style',
          'filter=',
          'mask=',
          'clip-path=',
        ];
        for (final String token in banned) {
          expect(svg.contains(token), isFalse, reason: '$path has $token');
        }
      });
    }
  });
}
