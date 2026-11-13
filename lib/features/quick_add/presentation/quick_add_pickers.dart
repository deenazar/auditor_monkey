import 'package:flutter/material.dart';

import 'widgets/account_picker_sheet.dart';
import 'widgets/all_categories_sheet.dart';
import 'widgets/note_sheet.dart';
import 'widgets/quick_add_view_models.dart';

/// Opens the account picker and reports the pick. Nothing happens when the
/// sheet is closed without a pick, or when the sheet's owner has gone.
Future<void> pickAccountSheet(
  BuildContext context, {
  required String title,
  required List<AccountOption> accounts,
  required String? selectedId,
  required ValueChanged<String> onPicked,
  String? disabledId,
}) async {
  final String? id = await AccountPickerSheet.show(
    context,
    title: title,
    accounts: accounts,
    selectedId: selectedId,
    disabledId: disabledId,
  );
  if (id != null && context.mounted) onPicked(id);
}

/// Opens the full category list and reports the pick.
Future<void> openAllCategoriesSheet(
  BuildContext context, {
  required List<CategoryChipData> categories,
  required String? selectedId,
  required ValueChanged<String> onPicked,
}) async {
  final String? id = await AllCategoriesSheet.show(
    context,
    categories: categories,
    selectedId: selectedId,
  );
  if (id != null && context.mounted) onPicked(id);
}

/// Opens the note editor. A closed sheet (null) keeps the old note.
Future<void> editNoteSheet(
  BuildContext context, {
  required String note,
  required ValueChanged<String> onDone,
}) async {
  final String? result = await NoteSheet.show(context, initialNote: note);
  if (result != null && context.mounted) onDone(result);
}

/// The option with [id], or null.
AccountOption? optionById(List<AccountOption> options, String? id) {
  if (id == null) return null;
  for (final AccountOption o in options) {
    if (o.id == id) return o;
  }
  return null;
}
