import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Makes row ids: random UUID v4 text (36 characters).
class IdGenerator {
  const IdGenerator();

  static const Uuid _uuid = Uuid();

  String newId() => _uuid.v4();
}

final Provider<IdGenerator> idGeneratorProvider = Provider<IdGenerator>(
  (Ref ref) => const IdGenerator(),
);
