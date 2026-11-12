import '../../../core/utils/validators.dart';
import 'gold.dart';

GoldHoldingDraft validateGoldHoldingDraft(GoldHoldingDraft draft) {
  final String description = validateName(
    'description',
    draft.description,
    max: 80,
  );
  validateIntRange('weightMg', draft.weightMg, min: 1, max: maxGoldWeightMg);
  validateDate('purchaseDate', draft.purchaseDate);
  validatePaise('purchasePrice', draft.purchasePrice, min: 0);
  return GoldHoldingDraft(
    description: description,
    weightMg: draft.weightMg,
    purity: draft.purity,
    purchaseDate: draft.purchaseDate,
    purchasePrice: draft.purchasePrice,
    accountId: draft.accountId,
  );
}

GoldRateDraft validateGoldRateDraft(GoldRateDraft draft) {
  validateDate('date', draft.date);
  validateIntRange(
    'ratePerGram',
    draft.ratePerGram,
    min: 1,
    max: maxGoldRatePerGram,
  );
  return draft;
}
