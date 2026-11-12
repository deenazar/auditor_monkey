import '../../../core/utils/validators.dart';
import 'category.dart';

/// Checks a category draft and returns a cleaned copy.
CategoryDraft validateCategoryDraft(CategoryDraft draft) {
  final String name = validateName('name', draft.name, max: 40);
  final String icon = validateName('icon', draft.icon, max: 40);
  return CategoryDraft(
    name: name,
    kind: draft.kind,
    colourGroup: draft.colourGroup,
    icon: icon,
    sortOrder: draft.sortOrder,
    archived: draft.archived,
  );
}
