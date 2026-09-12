# Flutter Fundament

A feature-first Clean Architecture base for Flutter apps, using Bloc for state
management and `fpdart` for functional error handling. It's meant to be
copied/forked as the starting point for a new app rather than depended on as a
package — a fully working Auth (login/logout) feature is included end-to-end
to prove every architectural seam actually works.

## What's included

- **Feature-first Clean Architecture** — `lib/core/` for cross-cutting
  concerns, `lib/features/<feature>/{data,domain,presentation}/` per feature.
- **Auth feature, end-to-end** — login, logout, and a guarded home route,
  demonstrating both a Cubit (`LoginCubit`, screen-scoped form state) and a
  Bloc (`AuthSessionBloc`, app-wide session state consumed by the router).
- **Functional error handling** — every repository method returns
  `TaskEither<Failure, T>` (`fpdart`); data sources throw, repositories catch
  via `TaskEither.tryCatch`, presentation consumes via `.match()`. No raw
  exceptions cross a layer boundary.
- **Routing** — `go_router`, with `AuthSessionBloc`'s state stream driving
  redirect-based auth guarding via a `GoRouterRefreshStream` adapter.
- **Dependency injection** — `get_it` + `injectable`, generated via
  `build_runner`. Repositories/mappers/services are `@lazySingleton`,
  screen-scoped Cubits are `@injectable` (factory).
- **Networking** — a single `Dio` client (`lib/core/network/`) with
  interceptors for auth-header injection and logging.
- **Flavors** — `dev`, `staging`, `prod`, each with its own entrypoint
  (`lib/main_<flavor>.dart`) and compile-time config generated via `envied`
  from a gitignored `.env.<flavor>` file.
- **Secure storage** — auth tokens and the cached user session live in
  `flutter_secure_storage`, never in plain state.
- **One-shot side effects** — `bloc_presentation` for things like error
  snackbars, instead of flags in persisted state.
- **Quality gate** — `very_good_analysis` + an `import_lint` rule enforcing
  that `presentation` never imports `data`, and `domain` never imports `data`
  or `presentation`. Enforced in CI (`.github/workflows/ci.yml`) alongside
  formatting, analysis, and tests.

See `docs/agents/plans/2026-09-12-flutter-clean-architecture-base.md` for the
full design rationale and trade-offs behind these choices.

## Requirements

- [FVM](https://fvm.app/) — this project's Flutter/Dart SDK version is
  managed *only* through FVM, never a system-wide Flutter install. `.fvmrc`
  pins the exact version (currently `3.47.4`, bundling Dart `3.13.3`, which
  satisfies the `sdk: ^3.8.0` constraint in `pubspec.yaml`).
- Xcode (iOS) and/or Android Studio (Android) for platform builds. Targets are
  iOS and Android only.

Every command below is run through `fvm` (`fvm flutter ...` / `fvm dart ...`)
so it always uses the version pinned in `.fvmrc`, regardless of what's
installed globally on your machine.

## Getting started

1. **Set up the pinned SDK.** From the repo root, this downloads (if needed)
   and activates the exact Flutter/Dart version in `.fvmrc` for this project:

   ```bash
   fvm install
   fvm use
   ```

2. **Install dependencies**

   ```bash
   fvm flutter pub get
   ```

3. **Generate code** (DI registrations, Freezed unions, JSON
   serialization, `envied` env classes) — required before the app compiles:

   ```bash
   fvm dart run build_runner build --delete-conflicting-outputs
   ```

   Re-run this after changing anything annotated with `@injectable`,
   `@freezed`, `@JsonSerializable`, or `@Envied`.

4. **Set up environment config.** Copy `.env.example` to `.env.dev`,
   `.env.staging`, and `.env.prod`, then fill in real values (these files are
   gitignored):

   ```bash
   cp .env.example .env.dev
   cp .env.example .env.staging
   cp .env.example .env.prod
   ```

5. **Run a flavor.** Each flavor has its own entrypoint:

   ```bash
   fvm flutter run --flavor dev --target=lib/main_dev.dart
   fvm flutter run --flavor staging --target=lib/main_staging.dart
   fvm flutter run --flavor prod --target=lib/main_prod.dart
   ```

## Testing

```bash
# Unit and widget tests (bloc_test + mocktail)
fvm flutter test

# Integration test: login -> guarded home route -> logout -> redirect to login
fvm flutter test integration_test/app_test.dart
```

## Linting

```bash
fvm dart format --output=none --set-exit-if-changed .
fvm flutter analyze

# Layer-boundary rule (presentation ↛ data, domain ↛ data/presentation)
fvm dart pub global activate import_lint
fvm dart pub global run import_lint
```

## Building

```bash
fvm flutter build apk --flavor dev --debug --target=lib/main_dev.dart
fvm flutter build apk --flavor prod --release --target=lib/main_prod.dart
fvm flutter build ipa --flavor prod --target=lib/main_prod.dart
```

> **Note:** CI (`.github/workflows/ci.yml`) doesn't use FVM — it pins Flutter
> directly via `subosito/flutter-action` to the same version as `.fvmrc`. If
> you bump `.fvmrc`, bump the `flutter-version` in the CI workflow to match.

## Using this as a base for a new app

This project isn't published to pub.dev (`publish_to: 'none'`) — it's meant to
be copied. To start a new app from it:

1. Copy the repository and rename the package in `pubspec.yaml` (and update
   the resulting import paths under `lib/`).
2. Replace the Auth feature's data sources with your real backend, or keep it
   as a reference implementation while building your first real feature
   alongside it under `lib/features/`.
3. Update `android/app/build.gradle.kts` and the iOS scheme/target flavor
   config with your app's real application ID / bundle ID per flavor.
4. Fill in `.env.dev` / `.env.staging` / `.env.prod` with your app's real API
   base URL and flags.

## Project structure

```
lib/
├── bootstrap.dart              # Shared entrypoint: DI, Bloc observer, runApp
├── main_dev.dart                main_staging.dart / main_prod.dart — per-flavor entrypoints
├── core/
│   ├── config/                # Env interface + per-flavor `envied` config
│   ├── di/                    # get_it + injectable setup
│   ├── error/                 # Sealed `Failure` hierarchy
│   ├── mapper/                # Generic `Mapper<Input, Output>`
│   ├── network/                # Dio client + auth/logging interceptors
│   ├── observer/               # App-wide BlocObserver
│   ├── router/                 # go_router + auth-aware redirect adapter
│   ├── storage/                # flutter_secure_storage wrapper
│   └── theme/                  # App theme
└── features/
    └── auth/
        ├── data/                # Data sources, models, mappers, repository impl
        ├── domain/              # Entities, repository interface, use cases
        └── presentation/        # Bloc/Cubit + pages
```
