# Project Context

## Purpose
CakeWallet is an open-source cryptocurrency wallet application for Android and iOS that supports Monero (XMR), Bitcoin (BTC), and Litecoin (LTC). The wallet enables users to:
- Create, manage, and restore cryptocurrency wallets
- Send and receive cryptocurrency transactions
- Exchange between supported cryptocurrencies
- Manage contacts and transaction templates
- Buy cryptocurrency through integrated services

## Tech Stack
- **Framework:** Flutter 2.x (Dart SDK >=2.7.0 <3.0.0)
- **State Management:** MobX (mobx, flutter_mobx, mobx_codegen)
- **Dependency Injection:** get_it
- **Local Storage:** Hive (hive, hive_flutter, hive_generator)
- **Secure Storage:** flutter_secure_storage
- **Reactive Programming:** RxDart
- **HTTP Client:** Dio, http
- **Native Crypto Libraries:** cw_monero (custom Monero wallet bindings), bitcoin_flutter
- **Build Tools:** build_runner, build_resolvers

### Platform Requirements
- **Android:** SDK 28+, NDK 17c
- **iOS:** Standard Flutter iOS requirements
- **Build Environment:** Ubuntu 16.04+ (for Android builds)

## Project Conventions

### Code Style
- **Linting:** Pedantic-based strict analysis (see `analysis_options.yaml`)
- **Strong mode:** No implicit casts, no implicit dynamic
- **Naming:**
  - Classes: `PascalCase` (e.g., `WalletListPage`, `DashboardViewModel`)
  - Files: `snake_case.dart` (e.g., `wallet_list_page.dart`, `auth_view_model.dart`)
  - Constants: `camelCase` with `constant_identifier_names` rule
  - Variables/Methods: `camelCase`
- **Documentation:** Slash-style doc comments (`///`)
- **Constructors:** Sort constructors first in class declarations
- **Imports:** Group by dart/flutter core, packages, then project files

### Architecture Patterns
- **MVVM Pattern:**
  - `lib/src/screens/` - UI layer (Pages/Widgets)
  - `lib/view_model/` - Business logic (ViewModels)
  - `lib/store/` - Application state stores (MobX stores)
  - `lib/entities/` - Domain models and entities
- **Service Layer:**
  - `lib/core/` - Core services (auth, backup, wallet services)
  - `lib/bitcoin/`, `lib/monero/` - Cryptocurrency-specific implementations
- **Dependency Injection:**
  - All dependencies registered in `lib/di.dart` using get_it
  - Pages and ViewModels instantiated via `getIt.get<T>()`
- **Navigation:**
  - Centralized routing in `lib/router.dart`
  - Route constants in `lib/routes.dart`
- **Reactions:**
  - MobX reactions for state changes in `lib/reactions/`

### Testing Strategy
- Widget tests in `test/` directory
- Use `flutter_test` for testing
- Tests should cover critical wallet operations and UI flows

### Git Workflow
- Feature branches for new development
- Semantic versioning (current: 4.2.7+62)
- Build numbers increment with releases

## Domain Context
- **Wallet Types:** Monero, Bitcoin, Litecoin - each with different address formats and transaction structures
- **Subaddresses:** Monero feature for generating multiple receive addresses from one wallet
- **Seed Phrases:** Mnemonic recovery phrases for wallet restoration
- **Exchange:** Built-in cryptocurrency exchange functionality
- **Nodes:** Remote nodes for blockchain synchronization (configurable per currency)
- **UTXO Management:** Bitcoin/Litecoin unspent transaction output tracking
- **PIN/Biometric Auth:** Security layer for wallet access

## Important Constraints
- **Security:** Sensitive data (seeds, keys) must use flutter_secure_storage
- **Privacy:** Monero's privacy features must be preserved
- **Offline-first:** Wallet should function with cached data when possible
- **Localization:** Full i18n support required (12+ languages in `assets/faq/`)
- **Platform Parity:** Features should work consistently on both Android and iOS

## External Dependencies
- **Electrum Servers:** Bitcoin/Litecoin light client servers (see `assets/*_electrum_server_list.yml`)
- **Monero Nodes:** Remote daemon connections (see `assets/node_list.yml`)
- **Exchange APIs:** Third-party exchange service integrations
- **Buy Services:** Cryptocurrency purchase provider integrations
