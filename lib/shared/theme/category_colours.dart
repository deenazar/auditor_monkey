import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Group name used for anything unknown (and for the "other" group itself).
const String categoryGroupOther = 'other';

/// Category colour groups (DESIGN.md "Category colour groups"). Keys are the
/// stored `CategoryColourGroup` names, so a stored value maps with no
/// conversion. Changing a colour later is a one-line change here.
const Map<String, Color> _groupColours = <String, Color>{
  'essentials': AppColors.accountScb,
  'food': AppColors.accountHand,
  'transport': AppColors.accountOutside,
  'home': AppColors.sun,
  'lifestyle': AppColors.accountSbi,
  'health': AppColors.teal,
  'family': AppColors.violet,
  'finance': AppColors.accountPf,
  'other': AppColors.iconInactive,
  'income': AppColors.lime,
};

/// The group colour (solid) for a stored group name, e.g. `food`.
/// Unknown names give the `other` colour. Never throws.
Color categoryGroupColour(String group) =>
    _groupColours[group] ?? AppColors.iconInactive;

/// The group colour at 20% opacity: the fill behind a category icon.
Color categoryGroupTint(String group) =>
    categoryGroupColour(group).withValues(alpha: 0.2);

/// The group names in display order (DESIGN.md order, `income` last).
const List<String> categoryGroupOrder = <String>[
  'essentials',
  'food',
  'transport',
  'home',
  'lifestyle',
  'health',
  'family',
  'finance',
  'other',
  'income',
];
