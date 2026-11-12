import 'package:auditor_monkey/app/router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

String? _go(String location, AsyncValue<bool> status) =>
    resolveSetupRedirect(location: Uri.parse(location), status: status);

void main() {
  const AsyncValue<bool> loading = AsyncLoading<bool>();
  final AsyncValue<bool> failed = AsyncError<bool>(
    StateError('x'),
    StackTrace.empty,
  );
  const AsyncValue<bool> none = AsyncData<bool>(false);
  const AsyncValue<bool> some = AsyncData<bool>(true);

  group('loading or failed', () {
    test('everything goes to /start and remembers where it was going', () {
      expect(_go('/home', loading), '/start?from=%2Fhome');
      expect(_go('/accounts/abc', loading), '/start?from=%2Faccounts%2Fabc');
      expect(_go('/home', failed), '/start?from=%2Fhome');
    });

    test('already on /start stays', () {
      expect(_go('/start', loading), isNull);
      expect(_go('/start?from=%2Fhome', failed), isNull);
    });

    test('/setup while loading goes to plain /start', () {
      expect(_go('/setup', loading), '/start');
    });
  });

  group('no accounts', () {
    test('everything goes to /setup', () {
      expect(_go('/home', none), '/setup');
      expect(_go('/accounts', none), '/setup');
      expect(_go('/start', none), '/setup');
      expect(
        _go('/accounts/118ca4e7-af5f-414a-9332-19254608cd87', none),
        '/setup',
      );
    });

    test('/setup stays', () {
      expect(_go('/setup', none), isNull);
    });
  });

  group('accounts exist', () {
    test('normal tabs and statements stay', () {
      for (final String p in <String>[
        '/home',
        '/insights',
        '/transactions',
        '/accounts',
        '/accounts/118ca4e7-af5f-414a-9332-19254608cd87',
        '/accounts/not-a-uuid', // the screen shows "not available"
      ]) {
        expect(_go(p, some), isNull, reason: p);
      }
    });

    test('/start goes to where the person was going, else Home', () {
      expect(_go('/start?from=%2Faccounts%2Fabc', some), '/accounts/abc');
      expect(_go('/start', some), '/home');
    });

    test('/start ignores unsafe or looping "from" values', () {
      for (final String from in <String>[
        'https://evil.example',
        '%2F%2Fevil.example',
        'home',
        '%2Fstart',
        '%2Fsetup',
        '',
      ]) {
        expect(_go('/start?from=$from', some), '/home', reason: from);
      }
    });

    test('a finished wizard goes to Accounts', () {
      expect(_go('/setup', some), '/accounts');
    });
  });
}
