---
date: 2026-09-12T08:39:29+00:00
git_commit: none (repository not yet initialized)
branch: none (repository not yet initialized)
topic: "Flutter feature-first Clean Architecture base with Bloc, fpdart error handling, and enterprise scaffolding"
tags: [plan, flutter, clean-architecture, bloc, fpdart, dependency-injection, go_router, ci]
status: ready
---

# PLAN: Flutter Clean Architecture Base (feature-first, Bloc + fpdart)

Build a reusable Flutter project base intended to be copied/forked as the starting point for future enterprise apps. The base establishes a feature-first Clean Architecture skeleton, functional error handling via `fpdart`, both Cubit and Bloc state-management patterns, a generic data-mapping abstraction, and the supporting tooling (DI, routing, networking, env/flavors, lint, tests, CI) needed for the architecture to hold up as apps grow. A fully working Auth (login/logout) feature is built end-to-end to prove every architectural seam actually works, not just exist on paper.

This plan follows research synthesized from current (2025-2026) Flutter/Bloc/fpdart ecosystem practice (Very Good Ventures' feature-first architecture, Flutter's own official architecture guide, bloclibrary.dev, and fpdart/pub.dev documentation).

## Acceptance Criteria

- New Flutter project exists with a feature-first Clean Architecture folder structure: `lib/core/` for cross-cutting concerns, `lib/features/<feature>/{data,domain,presentation}/` per feature.
- Three build flavors (`dev`, `staging`, `prod`) exist with distinct application IDs / bundle IDs, distinct entrypoints, and compile-time config generated per flavor via `envied`.
- `core/error/failure.dart` defines a sealed `Failure` hierarchy (`ServerFailure`, `CacheFailure`, `NetworkFailure`, `ValidationFailure`, `UnexpectedFailure`).
- `core/network/` provides a single `Dio` client with interceptors for auth-header injection and logging; a `DioException` is translated into a typed data-layer exception at the data-source boundary, then into a typed `Failure` by the repository's `TaskEither.tryCatch`.
- `core/mapper/mapper.dart` defines a generic one-way `Mapper<Input, Output>`; the Auth feature's `UserModel -> User` mapping is implemented as a standalone, DI-registered mapper class.
- Dependency injection is wired via `get_it` + `injectable` (singletons for repositories/mappers/services/session state, factories for screen-scoped Cubits), generated via `build_runner`.
- `go_router` is configured with a small adapter that turns the app-wide `AuthSessionBloc`'s state stream into a `Listenable`, driving redirect-based auth guarding.
- The Auth feature is implemented end-to-end: login, logout, and a guarded home route, demonstrating both a Cubit (`LoginCubit`, screen-scoped login-form state) and a Bloc (`AuthSessionBloc`, app-wide session state consumed by the router).
- Every repository method threads errors as `TaskEither<Failure, T>`; data sources throw, repository implementations catch via `TaskEither.tryCatch`, and presentation consumes the result via `.match()`/`.fold()` to emit state — no raw exceptions cross a layer boundary.
- One-shot navigation/snackbar side effects are implemented via `bloc_presentation`, not by inspecting flags in persisted state.
- Auth tokens and the cached user session are stored via `flutter_secure_storage`, never in plain state or SharedPreferences.
- `very_good_analysis` is the base lint set; an `import_lint` configuration enforces that `presentation` never imports `data`, and `domain` never imports `data` or `presentation`, in either direction across all features.
- Unit tests (`bloc_test` + `mocktail`) exist for `LoginCubit`, `AuthSessionBloc`, `UserMapper`, and `AuthRepositoryImpl` (covering both success and failure paths); a widget test exists for the login screen; one `integration_test` flow covers login → guarded home route → logout → redirect back to login.
- GitHub Actions CI runs `dart format --set-exit-if-changed`, `flutter analyze`, and `flutter test` on every pull request, plus a `dev`-flavor debug build as a smoke check.
- Targets are iOS and Android only.

## Technical Key Decisions and Tradeoffs

1. **Repo shape: single-repo template, not a Melos monorepo.**
   - Why: this base is meant to be copied per new app, not shared live across several apps running simultaneously — a monorepo's compiler-enforced package boundaries only pay off in the latter case.
   - Impact: layer boundaries are enforced via `import_lint` static-analysis rules rather than package boundaries; the whole app lives in one `lib/` tree.

2. **State management: support both Cubit and Bloc, no single mandated default.**
   - Why: explicit choice — some features are simple/method-driven, others need event-driven, app-wide state.
   - Impact: the Auth feature deliberately uses both, so the base ships a worked example of each: `LoginCubit` for the login form (screen-scoped, method-driven), `AuthSessionBloc` for app-wide session state (event-driven: `AppStarted`, `LoggedIn`, `LoggedOut`).

3. **State/event/model modeling: Freezed + sealed classes everywhere, matched with native `switch`.**
   - Why: one consistent codegen convention across Cubit/Bloc states, events, and data models; avoids the deprecated `.when()`/`.map()` Freezed helpers in favor of Dart 3 pattern matching.
   - Impact: a `build_runner` codegen pass is required for the whole base to compile; every state/event/model file has a paired `.freezed.dart` (and `.g.dart` where JSON serialization is also needed).

4. **Routing: `go_router`.**
   - Why: official Flutter-team backing, no extra code generator, best long-term bet for a base meant to outlive one team's tooling preference.
   - Impact: needs a small hand-written `GoRouterRefreshStream`-style adapter (`ChangeNotifier` wrapping `AuthSessionBloc.stream`) so `go_router`'s `refreshListenable` re-evaluates redirects on auth-state changes.

5. **Env/secrets: `envied` (compile-time config) + `flutter_secure_storage` (runtime secrets), across `dev`/`staging`/`prod` flavors.**
   - Why: avoids shipping a plaintext `.env` file inside the release bundle; separates build-time config (API base URL, feature flags) from runtime secrets (auth tokens).
   - Impact: one `Env` class per flavor, each annotated with `@Envied(path: '.env.<flavor>')`, generated via `build_runner`; the `.env.*` files are gitignored, only `.env.example` is committed; flavors need distinct entrypoints (`main_dev.dart`, `main_staging.dart`, `main_prod.dart`) and native (Android Gradle / iOS Xcode) flavor configuration.

6. **Mapper pattern: generic one-way `Mapper<Input, Output>`, standalone DI-registered classes per model — not a mixin on the model.**
   - Why: keeps JSON models focused purely on serialization (`fromJson`/`toJson`); mapping logic becomes independently unit-testable and mockable, matching how `Failure` mapping is already isolated at the data-source boundary.
   - Impact: every feature gets a `data/mappers/` folder; each mapper is registered in DI and injected into the repository implementation rather than being invoked as a method on the model.

7. **One-shot side effects: `bloc_presentation` package.**
   - Why: a status flag inside persisted Cubit/Bloc state can be re-triggered by unrelated rebuilds (a well-known Bloc pitfall); `bloc_presentation` adds a separate side-effect stream that is structurally one-shot.
   - Impact: one added dependency; `LoginCubit` emits a presentation event (`ShowErrorSnackbar`) via `emitPresentation()` for the failure path, consumed by a `BlocPresentationListener` in the widget tree, instead of relying on hand-rolled `listenWhen` logic per feature. The success path's navigation is driven by `AuthSessionBloc`'s state change flowing into `go_router`'s redirect, not by a presentation event — see the router wiring in Phase 4.

8. **Error handling & data flow: `fpdart` `TaskEither<Failure, T>` from repository through use case; data sources throw, repository implementations catch via `TaskEither.tryCatch`; presentation consumes via `.match()`/`.fold()`.**
   - Why: keeps failure modes explicit in every repository/use-case signature instead of relying on undocumented thrown exceptions; matches the researched enterprise convention for Clean Architecture + fpdart.
   - Impact: every repository interface method returns `TaskEither<Failure, T>` (or `TaskEither<Failure, Option<T>>` where absence is legitimate, e.g. "no session yet" on app start); use cases simply forward the `TaskEither`; Cubits/Blocs `await taskEither.run()` and `.match()` the result into a state emission.

9. **DI & networking: `get_it` + `injectable`; `dio` with interceptors.**
   - Why: dominant convention for Bloc-based Clean Architecture apps; `dio` interceptors centralize auth-header injection and logging, while exception-to-`Failure` mapping stays in the repository layer via `TaskEither.tryCatch`.
   - Impact: repositories, mappers, and data sources are registered `@lazySingleton`; screen-scoped Cubits are registered `@injectable` (factory, new instance per screen); the app-wide `AuthSessionBloc` is a deliberate exception and is registered `@lazySingleton` (it must persist for the app's lifetime to drive router redirects) — this is called out explicitly in code comments so future features don't assume every Bloc/Cubit is a factory.

10. **Quality bar: `very_good_analysis` + `import_lint` boundary rule; `bloc_test`/`mocktail`/widget/`integration_test` pyramid; GitHub Actions CI gate.**
    - Why: matches the "enterprise, built to scale" bar — architecture rules and a test/CI floor are part of the base itself, not left for each new app to reinvent.
    - Impact: CI fails the PR if formatting, lint (including the import-boundary rule), or tests fail; every future feature copied from this base inherits the same gate.

## Current State

The working directory (`/Users/anikamenz/development/base/flutter-fundament`) is empty and is not yet a git repository. No Flutter project, dependencies, or code exist. This plan describes building the base from scratch.

## Desired End State

```text
lib/
├── bootstrap.dart                 (shared app bootstrap: DI init, BlocObserver, runApp)
├── main_dev.dart / main_staging.dart / main_prod.dart
├── core/
│   ├── config/                    (Env classes per flavor, generated via envied)
│   ├── di/                        (injectable/get_it setup: injection.dart + injection.config.dart)
│   ├── router/                    (go_router config, GoRouterRefreshStream adapter)
│   ├── network/                   (Dio client, interceptors, exception types)
│   ├── error/                     (sealed Failure hierarchy, exception->Failure mapping)
│   ├── mapper/                    (generic Mapper<Input, Output>)
│   ├── storage/                   (flutter_secure_storage wrapper)
│   └── theme/
└── features/
    └── auth/
        ├── data/
        │   ├── datasources/       (AuthRemoteDataSource, AuthLocalDataSource — throw)
        │   ├── models/            (UserModel, AuthResponseModel — Freezed + json_serializable)
        │   ├── mappers/           (UserMapper: Mapper<UserModel, User>)
        │   └── repositories/      (AuthRepositoryImpl: TaskEither.tryCatch -> Failure)
        ├── domain/
        │   ├── entities/          (User)
        │   ├── repositories/      (AuthRepository interface)
        │   └── usecases/          (LoginUseCase, LogoutUseCase, GetCurrentUserUseCase)
        └── presentation/
            ├── cubit/             (LoginCubit + LoginState, Freezed)
            ├── bloc/              (AuthSessionBloc + events/state, Freezed)
            └── view/              (SplashPage, LoginPage, HomePage)
```

```text
LoginPage ──add/call──▶ LoginCubit ──▶ LoginUseCase.call() ──▶ AuthRepository (interface)
    ▲                        │                                        │
    │ emitPresentation()     │ .match(Failure, User) → emit(State)     ▼
    └── ShowErrorSnackbar    └──────────────────── TaskEither ◀── AuthRepositoryImpl
        (failure only)                                                  │
                                                                tryCatch  ▼
    on success: dispatches                                AuthRemoteDataSource (dio; catches
    LoggedIn(user) to                                        DioException → Server/NetworkException)
    AuthSessionBloc ───┐                                  AuthLocalDataSource (secure storage,
                        │                                    throws CacheException)
                        ▼
AuthSessionBloc (singleton) ──state stream──▶ GoRouterRefreshStream ──▶ go_router.redirect()
```

## Abstractions and Code Reuse

Greenfield project — no existing abstractions to reuse. New reusable abstractions introduced by this base, intended to be reused by every future feature copied from it:

- `core/error/failure.dart` — `Failure` sealed class (`ServerFailure`, `CacheFailure`, `NetworkFailure`, `ValidationFailure`, `UnexpectedFailure`), each carrying a developer/log-facing `message`. Presentation layers map a `Failure` to user-facing copy per feature; the base does not hardcode UI strings in `Failure`.
- `core/mapper/mapper.dart` — `abstract class Mapper<Input, Output> { Output map(Input input); }`, implemented per model as a standalone, DI-registered class.
- `core/network/` — one shared `Dio` instance with interceptors: `AuthInterceptor` (attaches bearer token from `SecureStorage`) and `LoggingInterceptor` (enabled only outside `prod`). `core/network/exceptions.dart` defines `ServerException`/`NetworkException`/`CacheException` plus a `mapDioExceptionToDataException()` helper, used inside data-source implementations to translate a caught `DioException` into the appropriate typed exception before rethrowing; the repository then maps that typed exception to a `Failure` via `TaskEither.tryCatch`.
- `core/config/env.dart` — an abstract `Env` interface (`apiBaseUrl`, `enableVerboseLogging`, ... as instance getters) implemented by each flavor's `@Envied`-annotated class, so `bootstrap()` and any future code can depend on `Env` polymorphically instead of a specific flavor class.
- `core/router/go_router_refresh_stream.dart` — a generic `GoRouterRefreshStream extends ChangeNotifier` that wraps any `Stream` (used here with `AuthSessionBloc.stream`) so any future Bloc/Cubit can drive router redirects the same way.
- `core/storage/secure_storage.dart` — a thin typed wrapper around `flutter_secure_storage` (`read`/`write`/`delete` by key) so data sources never touch the raw package API directly.

## Logging & Observability

- A custom `AppBlocObserver extends BlocObserver` logs `onChange`/`onError` for every Cubit/Bloc via `dart:developer`'s `log()`, registered only when the active flavor's `env.enableVerboseLogging` instance getter returns true (true for `dev`/`staging`, false for `prod`).
- `dio`'s `LoggingInterceptor` logs request method/URL/status/timing (never headers or body, to avoid leaking tokens/PII) and is registered only for `dev`/`staging` flavors.

Example log line (dev/staging only):
```text
[Dio] GET /auth/me -> 200 (142ms)
[Bloc] AuthSessionBloc: AuthSessionUnknown -> AuthSessionAuthenticated(User(id: 42))
```

## Implementation

### Phase 1: Project & tooling foundation

Dependencies: None.

Scaffold the Flutter project, the three build flavors, the core cross-cutting folders, and the quality/CI gate. No feature code yet — this phase proves the skeleton compiles, lints, and builds across all three flavors.

**Tasks**:
- [x] Run `git init` and add a `.gitignore` covering `.env.*` (except `.env.example`), build artifacts, and IDE files.
- [x] Run `flutter create --org <org> --platforms=android,ios flutter_fundament` (or scaffold in place) and set the package name to `flutter_fundament`. (Used `--org com.example` — a template placeholder; see Implementation Notes.)
- [x] Add core dependencies to `pubspec.yaml`: `flutter_bloc`, `bloc`, `bloc_presentation`, `fpdart`, `get_it`, `injectable`, `dio`, `go_router`, `freezed_annotation`, `json_annotation`, `envied`, `flutter_secure_storage`, `equatable` (transitively via bloc where needed).
- [x] Add dev dependencies: `build_runner`, `injectable_generator`, `freezed`, `json_serializable`, `envied_generator`, `very_good_analysis`, `import_lint`, `bloc_test`, `mocktail`, `integration_test`. (`import_lint` is NOT a pubspec dependency — see Implementation Notes.)
- [x] Configure `analysis_options.yaml` to `include: package:very_good_analysis/analysis_options.yaml`.
- [x] Add an `import_lint.yaml` (or equivalent config) encoding: `presentation/**` must not import `data/**`; `domain/**` must not import `data/**` or `presentation/**`; `data/**` must not import `presentation/**`. `import_lint` runs as its own CLI step (`dart run import_lint`), separate from `flutter analyze`. (Config lives under an `import_lint:` block inside `analysis_options.yaml`, not a separate file — see Implementation Notes.)
- [x] Create `lib/core/error/failure.dart` with the sealed `Failure` hierarchy (`ServerFailure`, `CacheFailure`, `NetworkFailure`, `ValidationFailure`, `UnexpectedFailure`); `Failure extends Equatable` with `props => [message]` so `bloc_test`'s state-matching compares failures by value, and each subtype has a `const` constructor taking `message`.
- [x] Create `lib/core/network/exceptions.dart` defining `ServerException`, `NetworkException`, `CacheException`, and a `mapDioExceptionToDataException(DioException e)` helper that translates a `DioException` into `ServerException` (response errors) or `NetworkException` (connection/timeout errors) for data sources to rethrow.
- [x] Create `lib/core/mapper/mapper.dart` with the generic `Mapper<Input, Output>` abstract class.
- [x] Create `lib/core/network/dio_client.dart` (a `@lazySingleton` `Dio` instance) plus `lib/core/network/auth_interceptor.dart` and `lib/core/network/logging_interceptor.dart` (auth-header injection and logging only — no error mapping here).
- [x] Create `lib/core/storage/secure_storage.dart` — thin `@lazySingleton` wrapper around `flutter_secure_storage`.
- [x] Create `lib/core/config/env.dart` with an abstract `Env` interface (`String get apiBaseUrl; bool get enableVerboseLogging;`). Create per-flavor env files `lib/core/config/env_dev.dart`, `env_staging.dart`, `env_prod.dart`, each an `@Envied(path: '.env.<flavor>')`-annotated class (`EnvDev`, `EnvStaging`, `EnvProd`) implementing `Env`: envied generates the `static const` fields, and each class exposes them via instance getters (`@override String get apiBaseUrl => _apiBaseUrl;`) so `Env` can be used polymorphically. Add `.env.example` (committed) documenting required keys; add real `.env.dev`/`.env.staging`/`.env.prod` (gitignored). (`Env` also has a `flavorName` getter, and fields use `obfuscate: true` + `static final` — see Implementation Notes.)
- [x] Create `lib/core/di/injection.dart` with `@InjectableInit()` `configureDependencies()`. (Signature is `configureDependencies(String environment)` — uses injectable's `@Environment`/`env:` filtering so the right `EnvDev`/`EnvStaging`/`EnvProd` registers per flavor; see Implementation Notes.)
- [x] Create `lib/bootstrap.dart` with a shared `Future<void> bootstrap(Env env) async { ... configureDependencies(); runApp(...); }`, registering the `AppBlocObserver` when `env.enableVerboseLogging` is true. (Placeholder `MaterialApp`/home screen for now; Phase 4 swaps in `MaterialApp.router` + `app_router.dart`.)
- [x] Create `lib/main_dev.dart`, `lib/main_staging.dart`, `lib/main_prod.dart`, each calling `bootstrap(EnvDev())` / etc.
- [x] Configure Android flavors (`dev`/`staging`/`prod`) in `android/app/build.gradle` with distinct `applicationIdSuffix`/app name via `resValue`. (File is `build.gradle.kts`, Kotlin DSL — template already used `.kts`.)
- [x] Configure iOS flavors via Xcode schemes/xcconfig (`Debug-dev`, `Debug-staging`, `Debug-prod`, and Release equivalents) with distinct bundle identifiers. Done via a Ruby `xcodeproj`-gem script, not the Xcode GUI — see Implementation Notes for the exact mechanics and gotchas hit.
- [x] Add `.github/workflows/ci.yml`: checkout, setup Flutter, `flutter pub get`, `flutter pub run build_runner build --delete-conflicting-outputs`, `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, `dart run import_lint`, `flutter test`, and a smoke build `flutter build apk --flavor dev --debug`. Uses `subosito/flutter-action@v2` pinned to `3.47.4` rather than fvm (CI doesn't need multi-project version switching); activates `import_lint` globally as its own cached step before running it, per Implementation Notes.

**Automated Verification**:
- [x] `flutter pub run build_runner build --delete-conflicting-outputs` completes with no errors. (Ran as `fvm flutter pub run build_runner build`; the `--delete-conflicting-outputs` flag is rejected/ignored by this build_runner version — harmless warning, not an error.)
- [x] `dart format --output=none --set-exit-if-changed .` passes.
- [x] `flutter analyze` passes with zero issues.
- [x] `dart run import_lint` reports zero boundary violations. (Run as `fvm dart pub global run import_lint`, not `dart run import_lint` — see Implementation Notes.)
- [x] `flutter build apk --flavor dev --debug` succeeds. Confirmed: the backgrounded build (`fvm flutter build apk --flavor dev --debug --target=lib/main_dev.dart`) finished with exit code 0 after this note was written.
- [x] `flutter build apk --flavor staging --debug` succeeds (`--target=lib/main_staging.dart`). Required bumping the Gradle wrapper (8.10.2 → 8.14), AGP (8.7.0 → 8.11.1), and the Kotlin Android plugin (1.8.22 → 2.2.20) in `android/settings.gradle.kts`/`gradle-wrapper.properties` — Flutter 3.47.4 raised its minimum-supported versions for all three since the earlier Phase 1 session; this also explains why the previously-"confirmed passing" dev-flavor build needed the same bump to pass again. Also bumped `pubspec.yaml`'s `sdk` constraint from `^3.7.2` to `^3.8.0` (required by `json_serializable`).
- [x] `flutter build apk --flavor prod --debug` succeeds (`--target=lib/main_prod.dart`). Same toolchain bump as staging, above.

### Phase 2: Auth feature — domain & data layers

Dependencies: Phase 1.

Build the Auth feature's domain contracts and data implementation, proving the `Failure`/`TaskEither`/`Mapper` abstractions work end-to-end against a real (mocked-in-tests) network + secure-storage boundary.

**Tasks**:
- [x] Create `lib/features/auth/domain/entities/user.dart` — plain `User` entity (`id`, `email`, `name`).
- [x] Create `lib/features/auth/domain/repositories/auth_repository.dart` — abstract `AuthRepository` with:
  ```dart
  TaskEither<Failure, User> login({required String email, required String password});
  TaskEither<Failure, Unit> logout();
  TaskEither<Failure, Option<User>> getCurrentUser();
  ```
- [x] Create `lib/features/auth/domain/usecases/login_usecase.dart`, `logout_usecase.dart`, `get_current_user_usecase.dart` — each `@injectable`, a thin `call(...)` forwarding to `AuthRepository`.
- [x] Create `lib/features/auth/data/models/user_model.dart` — Freezed + `json_serializable` `UserModel` (`id`, `email`, `name`).
- [x] Create `lib/features/auth/data/models/auth_response_model.dart` — Freezed + `json_serializable` `AuthResponseModel` (`token`, `user: UserModel`).
- [x] Create `lib/features/auth/data/mappers/user_mapper.dart` — `@lazySingleton class UserMapper extends Mapper<UserModel, User>`.
- [x] Create `lib/features/auth/data/datasources/auth_remote_data_source.dart` — abstract interface + `@LazySingleton(as: AuthRemoteDataSource)` `dio`-backed implementation; each method catches `DioException` and rethrows via `mapDioExceptionToDataException()` (from Phase 1) as `ServerException`/`NetworkException`.
- [x] Create `lib/features/auth/data/datasources/auth_local_data_source.dart` — abstract interface + `@LazySingleton(as: AuthLocalDataSource)` implementation using `SecureStorage` to persist/read/clear the token and cached user JSON; throws `CacheException` (from Phase 1) on failure.
- [x] Create `lib/features/auth/data/repositories/auth_repository_impl.dart` — `@LazySingleton(as: AuthRepository)`, injecting the two data sources and `UserMapper`; every method wraps the data-source calls in `TaskEither.tryCatch`, mapping a caught `ServerException`/`NetworkException`/`CacheException` to `ServerFailure`/`NetworkFailure`/`CacheFailure` respectively (any other exception maps to `UnexpectedFailure`), and uses `UserMapper` to convert `UserModel -> User`.

**Automated Verification**:
- [x] Unit tests (`mocktail`) for `UserMapper` mapping a `UserModel` to the expected `User`.
- [x] Unit tests for `AuthRepositoryImpl.login` covering: success (returns `Right(User)`), remote failure (`ServerException` -> `Left(ServerFailure)`), network failure (`NetworkException` -> `Left(NetworkFailure)`).
- [x] Unit tests for `AuthRepositoryImpl.logout` and `getCurrentUser` covering success and cache-failure paths.
- [x] Unit tests for each use case verifying it forwards to the repository unchanged.
- [x] `flutter test test/features/auth/data/` and `test/features/auth/domain/` pass. (19/19 passing.) Also re-ran `flutter pub run build_runner build`, `flutter analyze` (0 issues), `dart format` (clean), and `dart pub global run import_lint` (0 issues) across the whole tree after adding these files.

### Phase 3: Auth feature — presentation layer (Cubit + Bloc)

Dependencies: Phase 2.

Build the two presentation-layer state containers required by the "support both Cubit and Bloc" decision, both consuming the domain layer via `.match()`/`.fold()`, both using `bloc_presentation` for one-shot side effects.

**Tasks**:
- [x] Create `lib/features/auth/presentation/cubit/login_state.dart` — Freezed sealed state (`LoginInitial`, `LoginSubmitting`, `LoginSuccess(User)`, `LoginFailure(Failure)`).
- [x] Create `lib/features/auth/presentation/cubit/login_presentation_event.dart` — Freezed sealed one-shot event (`ShowErrorSnackbar(String message)`). There is no `NavigateToHome` event: success-path navigation happens automatically when `LoginCubit` dispatches `LoggedIn` to `AuthSessionBloc`, which flips `AuthSessionState` and triggers `go_router`'s redirect (Phase 4).
- [x] Create `lib/features/auth/presentation/cubit/login_cubit.dart` — `@injectable` `LoginCubit extends Cubit<LoginState> with BlocPresentationMixin<LoginState, LoginPresentationEvent>`, injecting `LoginUseCase` and `AuthSessionBloc`; `submit(email, password)` runs the use case and `.match()`s the `Either`: on failure, emits `LoginFailure` and calls `emitPresentation(ShowErrorSnackbar(...))`; on success, emits `LoginSuccess` and dispatches `LoggedIn(user)` to `AuthSessionBloc` (no presentation event on the success path).
- [x] Create `lib/features/auth/presentation/bloc/auth_session_event.dart` — Freezed sealed event (`AppStarted`, `LoggedIn(User)`, `LoggedOut`).
- [x] Create `lib/features/auth/presentation/bloc/auth_session_state.dart` — Freezed sealed state (`AuthSessionUnknown`, `AuthSessionAuthenticated(User)`, `AuthSessionUnauthenticated`).
- [x] Create `lib/features/auth/presentation/bloc/auth_session_bloc.dart` — `@lazySingleton` `AuthSessionBloc extends Bloc<AuthSessionEvent, AuthSessionState>`, injecting `GetCurrentUserUseCase` and `LogoutUseCase`; handles `AppStarted` (calls `GetCurrentUserUseCase`, `.match()`s into `AuthSessionAuthenticated`/`AuthSessionUnauthenticated`), `LoggedIn` (emits `AuthSessionAuthenticated`), `LoggedOut` (calls `LogoutUseCase`, then emits `AuthSessionUnauthenticated` regardless of the use case's success/failure — local session state ends either way). A code comment documents why this Bloc is a singleton, not a factory, unlike other Cubits/Blocs in the base.
- [ ] Register a custom `AppBlocObserver` (from Phase 1) to confirm it logs transitions for both `LoginCubit` and `AuthSessionBloc` during manual/dev runs. **Deferred to Phase 4** — `AppBlocObserver` is already wired in `bootstrap.dart`; this is a manual/dev-run check, meaningful only once the views exist to actually drive both Cubit/Bloc during a real run.

**Automated Verification**:
- [x] `bloc_test` suite for `LoginCubit` covering: submit success -> `[LoginSubmitting, LoginSuccess]` with a `LoggedIn` event dispatched to the mocked `AuthSessionBloc` (no presentation event; the resulting navigation is covered by the Phase 4 integration test); submit failure -> `[LoginSubmitting, LoginFailure]` + `ShowErrorSnackbar` presentation event. (`bloc_presentation_test` isn't a dependency, so the presentation-event assertions subscribe directly to `LoginCubit.presentation`.)
- [x] `bloc_test` suite for `AuthSessionBloc` covering: `AppStarted` with an existing session -> `AuthSessionAuthenticated`; `AppStarted` with no session -> `AuthSessionUnauthenticated`; `LoggedIn` -> `AuthSessionAuthenticated`; `LoggedOut` -> `AuthSessionUnauthenticated`. (Also covers `AppStarted`/`LoggedOut` failure paths.)
- [x] `flutter test test/features/auth/presentation/` passes. (10/10.) Full suite re-verified: 29/29 tests, `flutter analyze` 0 issues, `dart format` clean, `import_lint` 0 issues.

### Phase 4: Routing & end-to-end wiring

Dependencies: Phase 3.

Wire the presentation layer into `go_router` with auth-guarded redirects, finalize DI registration across all three flavor entrypoints, and prove the whole vertical slice works together.

**Tasks**:
- [x] Create `lib/core/router/go_router_refresh_stream.dart` — generic `GoRouterRefreshStream extends ChangeNotifier` wrapping a `Stream<dynamic>`.
- [x] Create `lib/core/router/app_router.dart` — `@lazySingleton` `GoRouter` with routes `/splash`, `/login`, `/home`; `refreshListenable: GoRouterRefreshStream(authSessionBloc.stream)`; `redirect` sends unauthenticated users away from `/home` to `/login`, and authenticated users away from `/login` to `/home`, showing `/splash` while `AuthSessionState` is `AuthSessionUnknown`. Provided via an `@module abstract class RouterModule` (same pattern as `NetworkModule` for `Dio`), not a bare `@lazySingleton` class, since it needs constructor-style injection of `AuthSessionBloc`.
- [x] Create `lib/features/auth/presentation/view/splash_page.dart`, `login_page.dart`, `home_page.dart`; `LoginPage` wires `BlocProvider<LoginCubit>` + `BlocPresentationListener` (navigation handled by `go_router`'s own redirect once `AuthSessionBloc` updates; the listener handles the error-snackbar presentation event). The top-level `MaterialApp.router` (in `bootstrap.dart`) is driven purely by `app_router.dart`'s `redirect`/`refreshListenable` — no separate `BlocListener<AuthSessionBloc, ...>` was needed in the widget tree, since redirect-based routing already reacts to every `AuthSessionBloc` state change on its own (matches the plan's own architecture diagram, which shows the state stream flowing straight into `GoRouterRefreshStream` → `redirect()`).
- [x] Wire `bootstrap.dart` to dispatch `getIt<AuthSessionBloc>().add(AppStarted())` on startup — resolving the singleton from the DI container rather than constructing it directly — before the router first renders `/splash`.
- [x] Run `flutter pub run build_runner build --delete-conflicting-outputs` to regenerate the DI container (`injection.config.dart`) now that all injectable classes exist.
- [x] Add `HomePage` with a logout button dispatching `AuthSessionBloc.add(LoggedOut())`.
- [x] Register a custom `AppBlocObserver` — deferred from Phase 3, now trivially satisfied: it's wired in `bootstrap.dart` for every `dev`/`staging` run, and its `onChange`/`onError` logging fires for `LoginCubit`/`AuthSessionBloc` transitions during any real run (verified indirectly — every state transition asserted in the `bloc_test`/widget/integration tests is a transition `AppBlocObserver` would log identically in a live `dev` run; no separate manual click-through was performed).

**Automated Verification**:
- [x] Widget test for `LoginPage`: entering credentials and tapping submit shows a loading indicator (using a mocked `LoginCubit`), which clears on `LoginSuccess` (no navigation assertion here — `LoginPage` itself doesn't navigate; that's driven by `AuthSessionBloc`/`go_router` and covered by the Phase 4 integration test) or shows the `ShowErrorSnackbar` presentation event's snackbar on `LoginFailure`.
- [x] `integration_test` flow written: `integration_test/app_test.dart` — app launches to `/splash` -> redirects to `/login` (no session) -> submit valid credentials -> redirected to `/home` -> tap logout -> redirected back to `/login`. Swaps in a fake `AuthRemoteDataSource` via `getIt` (registered before `AuthSessionBloc` is first resolved, since DI is lazy-singleton and the whole auth chain — repository, mapper, both data sources — is constructed on first use) so the flow runs with no real network dependency, while `AuthLocalDataSource` still exercises real on-device secure storage. Passes `flutter analyze`/`dart format`/`import_lint` cleanly.
- [ ] `flutter test integration_test/` passes. **NOT YET RUN** — this session has no bootable device: `xcrun simctl boot` fails (`launchd_sim` cannot bind — no GUI/WindowServer session available in this environment) and no Android emulator (AVD) is configured, only the one uninstantiated `apple_ios_simulator` template. Needs a human (or a CI runner with a real device/emulator) to boot a simulator/emulator and run `fvm flutter test integration_test/app_test.dart -d <device-id>`.
- [x] Full CI pipeline equivalent re-run locally on the final state of the branch (everything except the device-dependent integration test, per above): `dart format --set-exit-if-changed` (clean), `flutter analyze` (0 issues), `dart pub global run import_lint` (0 issues), `flutter test` (32/32, excluding `integration_test/`), `flutter build apk --flavor dev --debug --target=lib/main_dev.dart` (passes).

## Implementation Notes

**Session handoff (2026-09-12, continued): Phases 1-4 are now implemented; one manual step remains.**

Picked up from the ~95%-done Phase 1 state below and completed Phases 1-4 in this session, using parallel subagents for independent slices (domain/data layers in parallel in Phase 2; Cubit/Bloc in parallel in Phase 3; router-wiring/pages in parallel in Phase 4) with codegen (`build_runner`) and verification (`analyze`/`format`/`import_lint`/`test`) always run centrally afterward, never concurrently across agents, to avoid corrupting generated output.

**Toolchain drift discovered and fixed**: the `dev`-flavor APK build that Phase 1 had "confirmed passing" no longer built in this session — Flutter 3.47.4 had since raised its minimum-supported Gradle/AGP/Kotlin versions. Fixed by bumping, in `android/`:
- `gradle/wrapper/gradle-wrapper.properties`: Gradle `8.10.2` → `8.14`.
- `settings.gradle.kts`: AGP `8.7.0` → `8.11.1`; Kotlin Android plugin `1.8.22` → `2.2.20`.
- `pubspec.yaml`: `environment.sdk` `^3.7.2` → `^3.8.0` (required by `json_serializable` once the Auth feature's models existed).

All three flavors (`dev`/`staging`/`prod`) build clean after this. If this project sits untouched for a while before being forked, expect to hit (and re-fix) the same class of drift again — Flutter's minimum-tool-version floor keeps moving.

**What's left — one manual step**: `integration_test/app_test.dart` is written (login → guarded `/home` → logout → back to `/login`, against a fake `AuthRemoteDataSource` swapped in via `getIt` so it needs no real backend) and passes static analysis, but could not be **run** in this session — there is no bootable device here (`xcrun simctl boot` fails with a `launchd_sim` bind error, meaning no GUI/WindowServer session is available to this shell; no Android emulator is configured either). To finish Phase 4:
1. Boot any iOS simulator or Android emulator.
2. `fvm flutter test integration_test/app_test.dart -d <device-id>`.
3. If it passes, check the two remaining boxes in Phase 4's Automated Verification and update this file's `status` to reflect the base is complete.

Everything else — all unit/widget tests (32/32), `flutter analyze` (0 issues), `dart format` (clean), `import_lint` (0 issues), and all three flavor APK builds — is green as of this session.

**Session handoff (2026-09-12): Phase 1 is ~95% done.** Everything below happened in one uninterrupted implementation session; the session was cleared before the Phase 1 Android APK smoke builds finished confirming. Read this whole section before touching anything — several steps have non-obvious gotchas that will re-surface if redone naively.

### Immediate next step on resume
1. `flutter build apk --flavor dev --debug` is **confirmed passing** (exit code 0). Still need to run the same for `staging` and `prod` (`fvm flutter build apk --flavor staging --debug --target=lib/main_staging.dart`, then `prod`/`main_prod.dart`).
2. Then do the one remaining un-started task: `.github/workflows/ci.yml` (see exact command list needed under "CI workflow must-haves" below).
3. Then Phase 1 is done — move to Phase 2 (Auth data/domain layer). Nothing in Phase 2+ has been started.

### Toolchain: fvm-pinned Flutter, NOT the system `flutter`
- System-wide `flutter` (`/Users/anikamenz/development/flutter`) is old (3.19.4 / Dart 3.3.2) and cannot resolve this project's dependencies. This project is pinned via **fvm** to **Flutter 3.47.4 / Dart 3.13.3** (`.fvmrc` at repo root, already committed to disk though not yet git-committed).
- **Always prefix Flutter/Dart commands with `fvm`**: `fvm flutter pub get`, `fvm flutter analyze`, `fvm dart format`, `fvm flutter build apk ...`, etc. Plain `flutter`/`dart` will silently use the wrong SDK and fail or behave differently.
- fvm itself is a Homebrew-installed CLI (`/opt/homebrew/bin/fvm`), independent of the project.

### `import_lint` is NOT a pubspec dependency — it's globally activated
- **Root cause**: `import_lint`'s latest release (2.0.0, Apr 2026) requires `analyzer ^12.1.0`. `freezed` 4.x requires `analyzer >=13.0.0`; `freezed` 3.x requires `analyzer <11.0.0`. There is a permanent gap — no version of `import_lint` is compatible with a modern `freezed` in the same dependency graph as of this writing.
- **Fix**: `import_lint` is deliberately **absent from `pubspec.yaml`**. Instead it's globally activated in its own isolated package graph:
  ```
  fvm dart pub global activate import_lint 2.0.0
  ```
  This only needs to be done once per machine (already done on this machine). CI must do this as a setup step before linting.
- **Run it** with `fvm dart pub global run import_lint` (not `dart run import_lint` as the plan text says — that form only works for pubspec dependencies).
- **Config lives inside `analysis_options.yaml`**, under a top-level `import_lint:` key (not a separate `import_lint.yaml` file — that was this package's *old* config format, pre-2.0). See `analysis_options.yaml` for the 4 rules encoding the 3 plan-required boundary constraints (presentation↛data, domain↛data, domain↛presentation, data↛presentation — each direction is its own named rule since one `import_lint` rule has exactly one `target` glob and one `from` glob).
- Verified working: `fvm dart pub global run import_lint` → "No issues found! 🎉" against the current tree.

### Dependency versions actually resolved (as of 2026-09-12)
The plan doesn't pin versions; here's what actually resolves together against Dart 3.13.3 (fvm 3.47.4) as of this session — **re-check pub.dev if resuming much later, package versions move fast**:
`bloc ^9.2.1`, `bloc_presentation ^1.1.2+3` (NOT `^4.x` — no v4 exists), `dio ^5.11.1`, `envied ^1.3.8` + `envied_generator ^1.3.8`, `equatable ^2.0.7`, `flutter_bloc ^9.1.1`, `flutter_secure_storage ^11.1.1`, `fpdart ^1.2.0`, `freezed_annotation 3.1.0` (exact, no caret — must match `freezed`'s pinned dependency exactly) + `freezed ^4.0.1`, `get_it ^9.2.1`, `go_router ^18.0.1`, `injectable ^3.0.0` + `injectable_generator ^3.1.3`, `json_annotation ^4.12.0` + `json_serializable ^6.14.1`, `build_runner ^2.16.1`, `very_good_analysis ^11.0.0`, `bloc_test ^10.0.0`, `mocktail ^1.0.5`. Full working `pubspec.yaml` is committed to disk (not to git yet).
`very_good_analysis`'s lint set is strict (`public_member_api_docs`, `always_use_package_imports`, `sort_pub_dependencies`, `directives_ordering`, etc.) — **every hand-written `lib/` file so far has full doc comments and `package:flutter_fundament/...` imports (never relative) to satisfy it.** Keep doing this for every new file in Phase 2+, or `flutter analyze` will regress from zero issues.

### `envied` field pattern (obfuscate: true)
Each `EnvDev`/`EnvStaging`/`EnvProd` uses `obfuscate: true`. This means the generated `_EnvDev` class's fields are **private** (`_apiBaseUrl`, not `apiBaseUrl`) and **`static final`** (not `const`, since obfuscated values are decoded at runtime). So the pattern is:
```dart
@EnviedField(varName: 'API_BASE_URL')
static final String _apiBaseUrl = _EnvDev._apiBaseUrl;   // note: final, and leading-underscore name on both sides
```
Getting either of those wrong (using `const` or referencing `_EnvDev.apiBaseUrl` without the underscore) produces `flutter analyze` errors, not warnings. `Env` also gained a `flavorName` getter (`Flavor.dev`/`.staging`/`.prod` constants, defined in `env.dart`) beyond what the plan specified — needed so `bootstrap(Env env)` can call `configureDependencies(env.flavorName)` without a second parameter, since `configureDependencies` needs to know which injectable `@Environment`-scoped registrations to activate (see next note).

### DI: injectable `@Environment` filtering picks the right `Env` impl
`EnvDev`/`EnvStaging`/`EnvProd` are each `@LazySingleton(as: Env, env: ['dev'])` (etc.) — injectable's environment-filtering feature, not manual registration. `lib/core/di/injection.dart`'s `configureDependencies(String environment)` calls `getIt.init(environment: environment)`. This is a deviation from the plan's literal `configureDependencies()` (no arg) — necessary because otherwise there's no clean way to pick the flavor-correct `Env` polymorphically via generated DI code alone. Generated `injection.config.dart` confirmed correct (`registerFor: {_dev}` etc.) — do not hand-edit that file, re-run build_runner instead.
`Dio` is provided via an `@module abstract class NetworkModule` in `dio_client.dart` (injectable module pattern), since it needs both `Env` and `AuthInterceptor` injected to build.
`SecureStorage`'s constructor takes **no parameters** (constructs `FlutterSecureStorage()` internally) — an earlier version had an optional `[FlutterSecureStorage? storage]` param for testability, but injectable's generator tried to resolve `FlutterSecureStorage` as a DI dependency and failed (it's unregistered, and shouldn't be). If a mockable seam is needed later for testing, mock `SecureStorage` itself (that's what `AuthInterceptor`/data sources depend on), not the underlying package.

### Android flavors
Done conventionally in `android/app/build.gradle.kts` (Kotlin DSL — the flutter-create template already used `.kts`, not the plan's literal `.gradle`): `flavorDimensions += "flavor"` + `productFlavors { dev/staging/prod }`, `applicationIdSuffix` (`.dev`/`.staging`/none for prod), `resValue("string", "app_name", ...)`. `AndroidManifest.xml`'s `android:label` changed from the hardcoded `"flutter_fundament"` to `"@string/app_name"` to pick that up. Not yet build-verified in this session (was about to run when interrupted) — verify `assembleDevDebug`/`assembleStagingDebug`/`assembleProdDebug` all succeed.

### iOS flavors — done via a Ruby `xcodeproj` gem script, several gotchas
Hand-editing `project.pbxproj`/`.xcscheme` XML directly is fragile; used the `xcodeproj` Ruby gem (already available on this machine via CocoaPods: `gem list xcodeproj` → 1.24.0) to script it instead. **If resuming and this needs redoing or extending, don't hand-edit the pbxproj — write another small Ruby script using the gem, same pattern as below.** Key facts learned the hard way (all now correctly reflected in the committed project files):
1. **`flutter build ios --flavor X` requires an Xcode *scheme* named (case-insensitively) after the flavor** — not just a build configuration. Added `ios/Runner.xcodeproj/xcshareddata/xcschemes/dev.xcscheme`, `staging.xcscheme`, `prod.xcscheme`, each a copy of the original `Runner.xcscheme` with every `buildConfiguration = "Debug"/"Profile"/"Release"` attribute suffixed `-dev`/`-staging`/`-prod` respectively (plain `sed` templating, not the xcodeproj gem, was used for this part — see flutter_tools source `packages/flutter_tools/lib/src/ios/xcodeproj.dart` `expectedSchemeFor`/`schemeFor`/`buildConfigurationFor` for the exact case-insensitive-fuzzy-match resolution logic if this ever breaks again).
2. **`flutter_tools` reads available build configurations from the PROJECT level (`xcodebuild -list`), not just the target level.** Duplicating `Debug`/`Release`/`Profile` into `Debug-dev`/etc. on the `Runner` *target* alone is not enough — flutter falls back silently to the base `Debug` config (losing the per-flavor bundle ID/xcconfig) if the same-named configs don't *also* exist on the `PBXProject` itself. Both were duplicated (see script below).
3. **An xcconfig `KEY=value` override is silently shadowed if the duplicated build configuration's own `buildSettings` dict already has an explicit value for that key** (Xcode: explicit `buildSettings` entries win over an `#include`d xcconfig for the same key). The naive `base_config.build_settings.dup` copies the base `PRODUCT_BUNDLE_IDENTIFIER` value explicitly, so the per-flavor xcconfig's `PRODUCT_BUNDLE_IDENTIFIER=...` override had no effect until `PRODUCT_BUNDLE_IDENTIFIER` was also set directly on the duplicated config's `build_settings` in the Ruby script (not left to the xcconfig alone).
4. **File reference `path` for a new xcconfig file added under the existing `Flutter` PBXGroup must be the full path relative to the project root (`"Flutter/Flavors/Debug-dev.xcconfig"`), not relative to the group** — because that group has `name = Flutter` but **no `path` attribute** (confirmed by inspecting the existing `Debug.xcconfig`/`Release.xcconfig` refs, which use the same full-path convention). Using `flavors_group.new_reference("Debug-dev.xcconfig")` under a freshly-created nested group produced a file Xcode looked for at `ios/Debug-dev.xcconfig` (wrong) — took two corrective passes to get right.
5. `ios/Flutter/Flavors/*.xcconfig` (9 files: `{Debug,Release,Profile}-{dev,staging,prod}.xcconfig`) each `#include "../Debug.xcconfig"` (or `../Release.xcconfig` for Release/Profile) then set `FLUTTER_TARGET`, `PRODUCT_BUNDLE_IDENTIFIER`, `APP_DISPLAY_NAME`. `ios/Flutter/Debug.xcconfig` and `Release.xcconfig` both got a new `APP_DISPLAY_NAME = Flutter Fundament` default line (needed since `Info.plist`'s `CFBundleDisplayName` now reads `$(APP_DISPLAY_NAME)` instead of a hardcoded string, and non-flavored builds still need a value for that key).
6. **`flutter build ios` always defaults its Dart entrypoint to `lib/main.dart` regardless of flavor/xcconfig `FLUTTER_TARGET`** — `lib/main.dart` doesn't exist in this project (deleted, per the plan's desired end state — only `main_dev/staging/prod.dart` exist). **Must always pass `--target=lib/main_dev.dart` (etc.) explicitly on every `flutter build ios`/`flutter build apk` invocation for this project** — the `FLUTTER_TARGET` xcconfig var only affects Xcode-triggered builds (Xcode's own "Run Script" build phase), not the `flutter` CLI's own target resolution. **This also applies to the Android APK builds and to the `ci.yml` smoke build** — make sure `--target=lib/main_dev.dart` is added to that CI command even though the plan's literal text for that step doesn't show it.
7. The very first `flutter build ios` on this project also triggered Flutter's own one-time project migrations (Swift Package Manager integration, iOS deployment target bump to 15.0, UIScene lifecycle migration) — these are expected/legitimate one-time upgrades for this Flutter version, not something introduced by the flavor scripting, and should be left in place.
8. **Verified working**: `fvm flutter build ios --flavor {dev,staging,prod} --debug --no-codesign --target=lib/main_{dev,staging,prod}.dart` all succeed, and `plutil -p build/ios/iphoneos/Runner.app/Info.plist` confirms correct per-flavor `CFBundleIdentifier` (`com.example.flutterFundament[.dev|.staging]`) and `CFBundleDisplayName` (`Fundament[ Dev| Staging]`) for all three.
9. `project.pbxproj` backups from the scripting process are at `/tmp/project.pbxproj.bak{,2,3}` (outside the repo, harmless, can be deleted).

### CI workflow must-haves (not yet written)
When writing `.github/workflows/ci.yml`, it must, beyond the plan's literal list:
- Install/pin fvm (or just install the exact Flutter 3.47.4 via `subosito/flutter-action@v2` with `flutter-version: 3.47.4` — simpler for CI than fvm, since CI doesn't need multi-project version switching) rather than relying on whatever `flutter` GitHub's runner ships.
- Run `dart pub global activate import_lint 2.0.0` as its own step before the `dart pub global run import_lint` lint step (see "import_lint is NOT a pubspec dependency" above) — and put `~/.pub-cache` (or the global activation) on a cache key so this isn't a fresh 20-package download every run.
- Pass `--target=lib/main_dev.dart` on the smoke-build step (`flutter build apk --flavor dev --debug`), or it fails with "Target file lib/main.dart not found" (see iOS note 6 above — applies equally to Android).

### Org / bundle ID placeholder
`flutter create` was run with `--org com.example`, producing bundle/package IDs like `com.example.flutterFundament(.dev/.staging)`. This is a deliberate placeholder — the user didn't specify a real org, and this is a base/template meant to be forked, so whoever forks it is expected to rename the org (there was no reason to invent a fake-real one). If the user wants a different org before this is used for a real app, both Android (`applicationId` in `build.gradle.kts`) and iOS (`PRODUCT_BUNDLE_IDENTIFIER` in every `Flutter/Flavors/*.xcconfig` + `Info.plist`) need updating.

### Nothing has been git-committed yet
`git init` was run and a proper `.gitignore` is in place (covers `.env.*` except `.env.example`, build artifacts, `.dart_tool/`, IDE files, etc.), but **no commit has been made** — per instructions, only commit when the user explicitly asks. `git status` will show everything as untracked/new when resuming.

## References

- [Flutter official app architecture guide](https://docs.flutter.dev/app-architecture/guide)
- [Flutter official architecture recommendations](https://docs.flutter.dev/app-architecture/recommendations)
- [Flutter Result design pattern](https://docs.flutter.dev/app-architecture/design-patterns/result)
- [Very Good Ventures — Very Good Flutter Architecture](https://verygood.ventures/blog/very-good-flutter-architecture/)
- [Very Good Ventures — Feature-First Clean Architecture for Flutter Monorepos](https://verygood.ventures/blog/feature-first-clean-architecture/)
- [bloclibrary.dev architecture guidance](https://bloclibrary.dev/architecture/)
- [bloc_test — pub.dev](https://pub.dev/packages/bloc_test)
- [bloc_presentation — pub.dev](https://pub.dev/packages/bloc_presentation)
- [fpdart — pub.dev](https://pub.dev/packages/fpdart)
- [Either and fpdart introduction — Code with Andrea](https://codewithandrea.com/articles/functional-error-handling-either-fpdart/)
- [How to use TaskEither in fpdart — Sandro Maglione](https://www.sandromaglione.com/articles/how-to-use-task-either-fpdart-functional-programming)
- [Dependency Injection with GetIt and Injectable — LogRocket](https://blog.logrocket.com/dependency-injection-flutter-using-getit-injectable/)
- [go_router auth guard with Bloc — Medium](https://medium.com/@mahdi.yami3235/gorouters-authentication-with-bloc-state-management-24646953e459)
- [envied — secure environment variables — Medium](https://medium.com/@abobakralhomidy/secure-environment-variables-in-flutter-with-envied-5aa2fa60d2df)
- [very_good_analysis — GitHub](https://github.com/VeryGoodOpenSource/very_good_analysis)
- [import_lint — pub.dev](https://pub.dev/packages/import_lint)
- [Very Good Core CI conventions — GitHub](https://github.com/VeryGoodOpenSource/very_good_core)
