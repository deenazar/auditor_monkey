/// The 34 default categories created when the database is first made.
///
/// The ids are FIXED on purpose (hard-coded UUID v4 values). Never change
/// or regenerate them: the same ids must exist on every phone and in the
/// cloud, and imports and sync rely on them.
library;

import '../../../features/categories/domain/category.dart';

/// One default category.
class DefaultCategory {
  const DefaultCategory(
    this.id,
    this.name,
    this.kind,
    this.colourGroup,
    this.icon,
  );

  final String id;
  final String name;
  final CategoryKind kind;
  final CategoryColourGroup colourGroup;
  final String icon;
}

/// 26 expense categories, then 8 income categories. The list order is the
/// `sort_order` value.
const List<DefaultCategory> defaultCategories = <DefaultCategory>[
  DefaultCategory(
    '576c9c25-6fcc-43b0-b451-d383b6a89bf0',
    'Groceries',
    CategoryKind.expense,
    CategoryColourGroup.essentials,
    'shopping-cart',
  ),
  DefaultCategory(
    '476785b6-3cbc-4591-b95b-96c928721674',
    'Food & Dining',
    CategoryKind.expense,
    CategoryColourGroup.food,
    'utensils',
  ),
  DefaultCategory(
    'ef57ccdf-11c0-4dcd-be5b-03d122915e7e',
    'Tea & Snacks',
    CategoryKind.expense,
    CategoryColourGroup.food,
    'coffee',
  ),
  DefaultCategory(
    '16a5cabd-8410-40f8-a1e3-1a9898e7aee7',
    'Fuel',
    CategoryKind.expense,
    CategoryColourGroup.transport,
    'fuel',
  ),
  DefaultCategory(
    '57b37ac5-5c60-4cb1-9477-ac4bd5b876b9',
    'Transport',
    CategoryKind.expense,
    CategoryColourGroup.transport,
    'bus',
  ),
  DefaultCategory(
    '8cbccf73-0a18-43bf-9a03-12294f38d2a8',
    'Rent',
    CategoryKind.expense,
    CategoryColourGroup.home,
    'house',
  ),
  DefaultCategory(
    'b658bc01-eda7-4d4c-8330-87bba6185863',
    'Electricity & Water',
    CategoryKind.expense,
    CategoryColourGroup.home,
    'zap',
  ),
  DefaultCategory(
    '172b660f-7428-4c6b-b450-921d332f3434',
    'Gas (LPG)',
    CategoryKind.expense,
    CategoryColourGroup.home,
    'flame',
  ),
  DefaultCategory(
    '656ecff0-0a64-4281-98e2-b1651519e265',
    'Mobile & Internet',
    CategoryKind.expense,
    CategoryColourGroup.home,
    'smartphone',
  ),
  DefaultCategory(
    '71c7bb1b-d326-48c8-a15d-1ab4f087f9f4',
    'Household',
    CategoryKind.expense,
    CategoryColourGroup.home,
    'sofa',
  ),
  DefaultCategory(
    'da66f3c8-a295-423b-b4a1-8c2df1236042',
    'Repairs & Maintenance',
    CategoryKind.expense,
    CategoryColourGroup.home,
    'wrench',
  ),
  DefaultCategory(
    '034c4a2b-be1a-430d-9e70-2572e707dda0',
    'Shopping',
    CategoryKind.expense,
    CategoryColourGroup.lifestyle,
    'shopping-bag',
  ),
  DefaultCategory(
    'a2765658-0891-4035-a2b4-0efc3e90c50f',
    'Clothes',
    CategoryKind.expense,
    CategoryColourGroup.lifestyle,
    'shirt',
  ),
  DefaultCategory(
    '928dce4e-9319-43a3-83a6-8f916fa120ea',
    'Personal Care',
    CategoryKind.expense,
    CategoryColourGroup.lifestyle,
    'scissors',
  ),
  DefaultCategory(
    '1465eb32-e586-4886-ad55-5b593497095c',
    'Entertainment & OTT',
    CategoryKind.expense,
    CategoryColourGroup.lifestyle,
    'tv',
  ),
  DefaultCategory(
    '9e926922-148d-4b8f-a875-9400be78cb6f',
    'Travel',
    CategoryKind.expense,
    CategoryColourGroup.lifestyle,
    'plane',
  ),
  DefaultCategory(
    '113783ca-0155-402e-831e-7eba1a7d0bf7',
    'Health & Medicine',
    CategoryKind.expense,
    CategoryColourGroup.health,
    'heart-pulse',
  ),
  DefaultCategory(
    'ca6763e1-61e6-4c9a-877c-6f6d5583cc09',
    'Education',
    CategoryKind.expense,
    CategoryColourGroup.family,
    'graduation-cap',
  ),
  DefaultCategory(
    '3193e3f0-9a82-4f9b-9695-f4a913ea0d0c',
    'Family Support',
    CategoryKind.expense,
    CategoryColourGroup.family,
    'users',
  ),
  DefaultCategory(
    'e03398ba-4ec3-4a12-87c2-d4a406bf19f9',
    'Gifts & Festivals',
    CategoryKind.expense,
    CategoryColourGroup.family,
    'gift',
  ),
  DefaultCategory(
    '91a4c66f-3546-4d24-9274-66e561c43dcf',
    'Donations',
    CategoryKind.expense,
    CategoryColourGroup.family,
    'hand-heart',
  ),
  DefaultCategory(
    'd4f8c371-f9b3-456c-834a-6ec9e37932f4',
    'EMI',
    CategoryKind.expense,
    CategoryColourGroup.finance,
    'landmark',
  ),
  DefaultCategory(
    '113e6614-e393-40fe-b6a1-2067cf3fe56c',
    'Insurance',
    CategoryKind.expense,
    CategoryColourGroup.finance,
    'shield',
  ),
  DefaultCategory(
    'e28dfe15-f534-48b6-8690-c20be2f1cf34',
    'Loan Given',
    CategoryKind.expense,
    CategoryColourGroup.finance,
    'hand-coins',
  ),
  DefaultCategory(
    'f39f6b89-ca75-49a4-aa73-ec0c67b87b68',
    'Loan Repayment',
    CategoryKind.expense,
    CategoryColourGroup.finance,
    'banknote',
  ),
  DefaultCategory(
    '5dd4b51f-47be-4b7e-a88b-e620bffbf628',
    'Other Expense',
    CategoryKind.expense,
    CategoryColourGroup.other,
    'ellipsis',
  ),
  DefaultCategory(
    '4864b7f7-cbc0-4baa-99ca-f73c2cff5a9d',
    'Salary',
    CategoryKind.income,
    CategoryColourGroup.income,
    'briefcase',
  ),
  DefaultCategory(
    '4c488238-c6e3-45d2-9ed3-8e9985428cb5',
    'Business / Freelance',
    CategoryKind.income,
    CategoryColourGroup.income,
    'laptop',
  ),
  DefaultCategory(
    '469b6957-6b38-45fc-82af-76542ff622cb',
    'Interest',
    CategoryKind.income,
    CategoryColourGroup.income,
    'percent',
  ),
  DefaultCategory(
    '5118736d-4a65-4de9-a5ab-1772788d930c',
    'Refund / Cashback',
    CategoryKind.income,
    CategoryColourGroup.income,
    'undo-2',
  ),
  DefaultCategory(
    'dec25851-fa74-475d-aeba-eecc4809a869',
    'Gifts Received',
    CategoryKind.income,
    CategoryColourGroup.income,
    'gift',
  ),
  DefaultCategory(
    'ae691750-e226-45d0-80e4-679967449afe',
    'Loan Received',
    CategoryKind.income,
    CategoryColourGroup.income,
    'hand-coins',
  ),
  DefaultCategory(
    '4411a279-5a2f-49a6-923b-3c2f9ef3adca',
    'Loan Repayment Received',
    CategoryKind.income,
    CategoryColourGroup.income,
    'banknote',
  ),
  DefaultCategory(
    'e230604b-a130-4ded-b8b5-f9389a6d4a60',
    'Other Income',
    CategoryKind.income,
    CategoryColourGroup.income,
    'ellipsis',
  ),
];

/// Ids of the 4 loan categories (Loan Given, Loan Repayment, Loan Received,
/// Loan Repayment Received). Quick Add hides them until the loan screens
/// exist, because an entry with a loan category but no loan link would count
/// as normal spending or income. The ids are the stable key: never match on
/// the display names.
const Set<String> loanCategoryIds = <String>{
  'e28dfe15-f534-48b6-8690-c20be2f1cf34',
  'f39f6b89-ca75-49a4-aa73-ec0c67b87b68',
  'ae691750-e226-45d0-80e4-679967449afe',
  '4411a279-5a2f-49a6-923b-3c2f9ef3adca',
};
