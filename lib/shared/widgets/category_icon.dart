import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Icon used when a category's icon name is not known. Never throws.
const IconData categoryFallbackIcon = LucideIcons.ellipsis;

/// Lucide icon for a seeded category icon name (kebab-case, as stored in the
/// database, e.g. `shopping-cart`). Unknown names give [categoryFallbackIcon].
IconData categoryIconFor(String iconName) {
  return switch (iconName) {
    'banknote' => LucideIcons.banknote,
    'briefcase' => LucideIcons.briefcase,
    'bus' => LucideIcons.bus,
    'coffee' => LucideIcons.coffee,
    'ellipsis' => LucideIcons.ellipsis,
    'flame' => LucideIcons.flame,
    'fuel' => LucideIcons.fuel,
    'gift' => LucideIcons.gift,
    'graduation-cap' => LucideIcons.graduationCap,
    'hand-coins' => LucideIcons.handCoins,
    'hand-heart' => LucideIcons.handHeart,
    'heart-pulse' => LucideIcons.heartPulse,
    'house' => LucideIcons.house,
    'landmark' => LucideIcons.landmark,
    'laptop' => LucideIcons.laptop,
    'percent' => LucideIcons.percent,
    'plane' => LucideIcons.plane,
    'scissors' => LucideIcons.scissors,
    'shield' => LucideIcons.shield,
    'shirt' => LucideIcons.shirt,
    'shopping-bag' => LucideIcons.shoppingBag,
    'shopping-cart' => LucideIcons.shoppingCart,
    'smartphone' => LucideIcons.smartphone,
    'sofa' => LucideIcons.sofa,
    'tv' => LucideIcons.tv,
    'undo-2' => LucideIcons.undo2,
    'users' => LucideIcons.users,
    'utensils' => LucideIcons.utensils,
    'wrench' => LucideIcons.wrench,
    'zap' => LucideIcons.zap,
    _ => categoryFallbackIcon,
  };
}
