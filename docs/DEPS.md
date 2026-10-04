# Dependencies: geodraw-core

Reusable Flutter packages (`designsystem`, `geocalc`, `geodraw`) live in
[Akash-dvd/geodraw-core](https://github.com/Akash-dvd/geodraw-core).

## Cloud / CI

`pubspec.yaml` (root, `packages/geoapp`, `packages/frontpage`) pin those packages
via pub `git:` dependencies on `main` with `path: packages/...` inside the core repo.

GitHub Actions and other CI runners resolve those git URLs; do **not** commit
`pubspec_overrides.yaml` (it is gitignored).

## Local monorepo siblings

Clone both repos next to each other:

```text
…/python/internal/
  geodraw-core/
  geofrontapp/
```

Then enable path overrides so `flutter pub get` uses the sibling checkout:

```bash
cp pubspec_overrides.yaml.example pubspec_overrides.yaml
flutter pub get
```

Flutter always applies `pubspec_overrides.yaml` when that file is present, which
is why it must stay gitignored—otherwise CI without a sibling tree would break.

Edit core packages under `../geodraw-core/packages/…` and push that repo separately.
