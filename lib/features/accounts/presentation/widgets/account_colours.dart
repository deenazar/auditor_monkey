import 'package:flutter/painting.dart';

import '../../../../shared/theme/app_colors.dart';

/// Colour token names (as stored in `accounts.colour`) mapped to tokens.
/// Every token in `accountColourTokens` is here.
const Map<String, Color> _colours = <String, Color>{
  'primary': AppColors.primary,
  'lime': AppColors.lime,
  'sun': AppColors.sun,
  'accountAxis': AppColors.accountAxis,
  'accountSbi': AppColors.accountSbi,
  'accountScb': AppColors.accountScb,
  'accountHand': AppColors.accountHand,
  'accountFoodCard': AppColors.accountFoodCard,
  'accountOutside': AppColors.accountOutside,
  'accountPf': AppColors.accountPf,
};

/// Colours offered when choosing an account colour. `sun` is left out: it is
/// the same yellow as `accountAxis`. It stays in [_colours] so stored values
/// still resolve.
const List<String> pickerAccountColours = <String>[
  'primary',
  'lime',
  'accountAxis',
  'accountSbi',
  'accountScb',
  'accountHand',
  'accountFoodCard',
  'accountOutside',
  'accountPf',
];

/// Tokens whose text must be `onDark` (DESIGN.md Accounts table). All other
/// account colours take `ink` text.
const Set<String> _onDarkTokens = <String>{'accountSbi', 'accountPf'};

/// Human name for each colour, used by screen readers and the swatch picker.
const Map<String, String> _colourNames = <String, String>{
  'primary': 'Mint',
  'lime': 'Lime',
  'sun': 'Sun yellow',
  'accountAxis': 'Yellow',
  'accountSbi': 'Magenta',
  'accountScb': 'Green',
  'accountHand': 'Orange',
  'accountFoodCard': 'Pale lime',
  'accountOutside': 'Sky blue',
  'accountPf': 'Deep green',
};

/// Fallback for an unknown token. Never throws: a bad stored value shows
/// as the brand mint instead of crashing the screen.
const Color accountFallbackColour = AppColors.primary;

/// The colour for a stored colour token, e.g. `accountSbi` -> magenta.
/// Unknown tokens give [accountFallbackColour].
Color accountColourFor(String token) =>
    _colours[token] ?? accountFallbackColour;

/// The text colour to use on [accountColourFor] (`onDark` or `ink`).
Color accountTextColourFor(String token) =>
    _onDarkTokens.contains(token) ? AppColors.onDark : AppColors.ink;

/// Human-readable colour name for a token, e.g. `accountSbi` -> "Magenta".
/// Unknown tokens give "Colour".
String accountColourName(String token) => _colourNames[token] ?? 'Colour';
