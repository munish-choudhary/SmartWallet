# GEMINI.md

Guidance for Gemini (CLI/Code Assist) when working in this repository. Read fully before making changes. This file mirrors [CLAUDE.md](CLAUDE.md) — that file is the source of truth for architecture, security, and conventions. This file adds scope boundaries and handoff rules specific to Gemini's assignment.

## Your scope: `features/portfolio/`

You are assigned the **Portfolio** feature only:

```
lib/features/portfolio/
  data/        # portfolio_repository.dart, DTOs
  view_model/  # portfolio_cubit.dart, portfolio_state.dart
  view/        # screens and widgets
```

Also relevant but read-only unless a task explicitly asks you to touch them:
- `lib/core/chains/chain_adapter.dart` and per-chain adapters (you call these, you don't modify their interfaces)
- `lib/core/db/` (Drift tables/DAOs for balances, token metadata — ask before adding/changing schema)
- `lib/core/design_system/` (reuse existing components; don't fork or duplicate them)

**Do not touch, under any circumstance, without explicit user sign-off first:**
- `lib/core/vault/` — key management, encryption, PIN/biometrics
- `lib/core/signing/` — signing pipeline
- `lib/app/router.dart`, `lib/app/routes.dart` — routing is centrally owned
- Any other feature folder (`send/`, `swap/`, `walletconnect/`, `ai_assistant/`, etc.)

If a portfolio task seems to require changes outside this scope, stop and flag it rather than editing across the boundary.

## Everything else: follow CLAUDE.md exactly

The full project rules apply unchanged — read [CLAUDE.md](CLAUDE.md) in full before starting any task. Highlights most relevant to portfolio work:

- **Architecture:** View (dumb widget) → ViewModel (Cubit, `PortfolioCubit`) → Repository (`PortfolioRepository`) → Service. No business logic in widgets, no direct repo/service calls from views.
- **State:** `PortfolioState` is a `freezed` sealed union (`loading` / `loaded(data, {refreshing})` / `failure`). No nullable-flag soup.
- **Cache-first:** emit cached data immediately via Drift `watch()` streams, refresh from network in the background. Throttle websocket price updates to ~1/sec.
- **Error handling:** repository/service methods return `Result<T>`, never throw across layers. Map `AppFailure` to UI messages.
- **Performance:** `BlocSelector` to scope rebuilds, `const` constructors, `RepaintBoundary` around continuously animated widgets (charts, AI orb), static translucent glass in list items (no live `BackdropFilter` blur in lists).
- **Naming:** `portfolio_cubit.dart`, `portfolio_state.dart`, `portfolio_repository.dart`, `*_service.dart`, `*_screen.dart`.
- **Tests:** `bloc_test` for `PortfolioCubit`, golden tests for any new design-system components. Run `dart run build_runner build --delete-conflicting-outputs` after touching `freezed`/`json_serializable`/Drift files.
- **Never** put secrets in Cubit/Bloc state — not applicable to portfolio data itself, but if a task touches wallet/account identifiers, treat addresses as public, never mnemonics/keys.
- **Dependencies:** do not add any new package without asking first (no Riverpod/Provider/GetX/get_it either).

## Handoff protocol

- Work in small, focused, PR-sized commits scoped to `features/portfolio/`.
- Before opening a PR, run: `flutter analyze` and `flutter test test/features/portfolio/`.
- If a change requires modifying a shared file outside your scope (a `ChainAdapter` interface, a Drift table used by other features, a design-system component), open the PR with that change isolated and clearly called out in the description, and flag it for review before merging — don't bundle it silently with portfolio changes.
- Do not modify `CLAUDE.md` or this file as part of a feature PR.
