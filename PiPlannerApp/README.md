# PiPlannerApp (FE-009)

Full SwiftUI iPhone portrait PiPlanner savings-ledger hackathon app. Fresh rebuild from FE-008.

## Requirements

- **Platform**: iOS 17+, iPhone portrait only
- **Bundle ID**: `com.rana.piplanner.app`
- **Display Name**: PiPlanner
- **Xcode**: 16+ (objectVersion 77)

## Project Structure

```
PiPlannerApp/
├── PiPlannerApp.xcodeproj/    # Xcode project
├── PiPlannerApp/              # App target (SwiftUI)
│   ├── App/                   # App entry, AppState, navigation
│   ├── Core/                  # Engine, Models, Copy providers
│   ├── Features/              # Feature modules (screens)
│   └── Shared/                # Theme, components, formatting
├── Packages/
│   └── PiPlannerCore/         # SPM package with engine + tests
├── contracts/                 # Contract documents
└── docs/                      # Design decisions
```

## Features

- **Setup flow**: Welcome → Accounts → Consent (Yes/No) → Goals → Inflation → Opening split
- **Main tabs**: Goals, History, Ask, Settings
- **Consent Yes**: Auto mock fetch ₹1,00,000 opening
- **Consent No**: Manual amount OR Balance sync (mock UPI PIN if linkedInPaytm)
- **One goal**: 100% standing, skips split UI
- **Sync**: +₹50,000 delta, one-time override, then locked
- **Transfer**: Move saved between goals
- **Delete**: Redistribute saved to remaining goals
- **Withdrawal**: Reduce goal saved (mock only)
- **Ask**: Template/Grok answers from engine data
- **Reset demo**: Return to Welcome

## Running Tests

Engine tests via SPM in the Packages folder:

```bash
cd Packages/PiPlannerCore
swift test
```

## Demo

Opening: ₹1,00,000 → 60% Car / 40% Emergency
Sync: +₹50,000 delta
Demo date: 6 Oct 2026 (Asia/Kolkata)

## Out of Scope

- Login, backend, real bank/payment APIs
- Autopay, shopping/review
- Widgets, push notifications, charts
