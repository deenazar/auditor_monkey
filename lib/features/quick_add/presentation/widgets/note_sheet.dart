import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import 'choice_pill.dart';

/// Longest note preview in the pill before it is cut (logical pixels).
const double _pillLabelMaxWidth = 200;

/// The note pill in the details row: "Add note" or the first words of the
/// note. Taps open [NoteSheet].
class NotePill extends StatelessWidget {
  const NotePill({required this.note, required this.onTap, super.key});

  /// The saved note, or null / empty when there is none.
  final String? note;
  final VoidCallback onTap;

  /// Shows the first [NoteSheet.previewWords] words of [note].
  static String previewOf(String note) {
    final List<String> words = note
        .trim()
        .split(RegExp(r'\s+'))
        .where((String w) => w.isNotEmpty)
        .toList();
    if (words.length <= NoteSheet.previewWords) return words.join(' ');
    return '${words.take(NoteSheet.previewWords).join(' ')}…';
  }

  @override
  Widget build(BuildContext context) {
    final String? text = note;
    final bool hasNote = text != null && text.trim().isNotEmpty;
    final String label = hasNote ? previewOf(text) : 'Add note';
    return ChoicePill(
      selected: false,
      onTap: onTap,
      semanticsLabel: hasNote ? 'Note: $text' : 'Add note',
      leadingBuilder: (bool _) => const Icon(
        LucideIcons.stickyNote,
        size: AppSizes.iconChip,
        color: AppColors.ink,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _pillLabelMaxWidth),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// Bottom sheet to write the note (DESIGN.md P3).
///
/// One line, at most [maxLength] characters. The counter shows from
/// [counterFrom]. Control characters are dropped on typing and pasting. "Done"
/// (or the keyboard's done key) returns the trimmed text. Closing the sheet
/// returns null, which means "no change".
class NoteSheet extends StatefulWidget {
  const NoteSheet({required this.initialNote, required this.onDone, super.key});

  static const int maxLength = 200;
  static const int counterFrom = 180;

  /// Words shown in the note pill.
  static const int previewWords = 3;

  /// Opens the sheet and returns the new note (trimmed, maybe empty), or
  /// null when it was closed without "Done".
  static Future<String?> show(
    BuildContext context, {
    required String initialNote,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder: (BuildContext sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: NoteSheet(
          initialNote: initialNote,
          onDone: (String value) => Navigator.of(sheetContext).pop(value),
        ),
      ),
    );
  }

  final String initialNote;

  /// Called with the trimmed note when the user is done.
  final ValueChanged<String> onDone;

  @override
  State<NoteSheet> createState() => _NoteSheetState();
}

/// Tabs, line breaks and other control characters are not allowed.
final TextInputFormatter _noControlCharacters =
    FilteringTextInputFormatter.deny(RegExp(r'[\x00-\x1F\x7F]'));

class _NoteSheetState extends State<NoteSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialNote,
  );

  void _done() => widget.onDone(_controller.text.trim());

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int length = _controller.text.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.space6,
        AppSpacing.screenPadding,
        AppSpacing.space6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppTextField(
            label: 'Note',
            controller: _controller,
            hintText: 'What was it for?',
            autofocus: true,
            maxLength: NoteSheet.maxLength,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            inputFormatters: <TextInputFormatter>[_noControlCharacters],
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _done(),
          ),
          if (length >= NoteSheet.counterFrom) ...<Widget>[
            const SizedBox(height: AppSpacing.space2),
            Text(
              '$length/${NoteSheet.maxLength}',
              textAlign: TextAlign.end,
              style: AppTextStyles.caption.copyWith(
                color: length >= NoteSheet.maxLength
                    ? AppColors.danger
                    : AppColors.inkMuted,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.space4),
          PrimaryButton(label: 'Done', onPressed: _done),
        ],
      ),
    );
  }
}
