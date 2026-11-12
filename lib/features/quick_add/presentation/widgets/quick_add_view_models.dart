import 'package:flutter/foundation.dart';

import '../../../transactions/domain/transaction_entry.dart';

/// One category chip. [colourGroup] is the stored group name (for example
/// `food`); unknown names show in the `other` tint.
@immutable
class CategoryChipData {
  const CategoryChipData({
    required this.id,
    required this.name,
    required this.icon,
    required this.colourGroup,
  });

  final String id;
  final String name;

  /// Lucide icon name in kebab case.
  final String icon;
  final String colourGroup;
}

/// One account in a pill or a picker. [colourToken] is the stored token
/// (for example `accountSbi`). [balancePaise] is integer paise.
@immutable
class AccountOption {
  const AccountOption({
    required this.id,
    required this.name,
    required this.colourToken,
    required this.balancePaise,
  });

  final String id;
  final String name;
  final String colourToken;
  final int balancePaise;
}

/// One recent entry shown as a chip. [label] is the category or account
/// text, e.g. "Groceries" or "SBI → Axis" (the caller builds it). Transfers
/// have no [categoryIcon]; they show the transfer arrow.
@immutable
class RecentEntryView {
  const RecentEntryView({
    required this.type,
    required this.amountPaise,
    required this.label,
    required this.colourGroup,
    this.categoryIcon,
  });

  final TransactionType type;

  /// Integer paise, always positive.
  final int amountPaise;
  final String label;
  final String colourGroup;

  /// Lucide icon name in kebab case; null for transfers.
  final String? categoryIcon;
}
