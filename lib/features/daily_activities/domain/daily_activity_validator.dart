import '../../../core/utils/validators.dart';
import 'daily_activity.dart';

DailyActivityDraft validateDailyActivityDraft(DailyActivityDraft draft) {
  validateDate('date', draft.date);
  return DailyActivityDraft(
    date: draft.date,
    title: validateName('title', draft.title, max: 80),
    note: validateOptionalText('note', draft.note, max: 1000),
  );
}
