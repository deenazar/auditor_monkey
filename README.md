# Auditor Monkey

A personal money tracker for iPhone and Android that replaces an Excel
sheet. It records expenses, income and transfers across all accounts,
shows live balances and keeps a full history. Indian Rupee only; money
is stored as whole paise and shown as `₹1,23,456.00`. It works fully
offline (cloud sync comes in roadmap session 9).

## Docs
- [CLAUDE.md](CLAUDE.md): company standards (read first)
- [docs/PROJECT.md](docs/PROJECT.md): requirements, tech stack, roadmap
- [docs/DECISIONS.md](docs/DECISIONS.md): every decision and why
- [docs/FEATURES.md](docs/FEATURES.md): what each feature does, status
- [docs/DATABASE.md](docs/DATABASE.md): tables and money rules
- [DESIGN.md](DESIGN.md): design tokens and rules
- [CHANGELOG.md](CHANGELOG.md): one entry per pull request

## Tech
Flutter 3.47.9 (stable), Riverpod, go_router, Drift (SQLite), fl_chart.

## Run
```bash
flutter pub get
flutter run
```

## Check before a pull request
CI runs the same three steps on every pull request.
```bash
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test
```

Golden (screenshot) masters are made only on Linux with Flutter 3.47.9:
```bash
flutter test --tags golden --update-goldens
```

After changing a Drift table, regenerate the code:
```bash
dart run build_runner build
```

## Branches
Work goes on `feature/`, `fix/`, `docs/` or `chore/` branches cut from
`develop`, and is merged into `develop` by pull request. `develop` is
merged into `main` for releases only.
