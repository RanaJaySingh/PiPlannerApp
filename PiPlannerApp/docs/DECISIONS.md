# PiPlannerApp (FE-009) — design decisions

## Sources unavailable at build time
- **Design SoT** `https://claude.ai/artifact/VtHM2P9uhkH8o8o2kqFHE5` returned empty / auth-walled when fetched.
- **Hackathon docs** `/workspace/pip-hackathon-v3/` were **missing** on this box.
- Built from **contract-fe009.md** + Paytm-like English UI. Journeys J1–J8 inferred from FE-007/FE-008 decisions + FE-009 full scope.
- Patterns read from FE-008 reference zip; **rebuilt fresh** — prior code not shipped unchanged.

## Platform
- iOS 17+, iPhone portrait only (`TARGETED_DEVICE_FAMILY=1`, `UIInterfaceOrientationPortrait`).
- Bundle id `com.rana.piplanner.app`; scheme **PiPlannerApp**; folder **PiPlannerApp/**; display name **PiPlanner**.
- SwiftUI + Observation (`@Observable` / `@Environment` / `@Bindable`).
- No login, backend, real bank/payments, Autopay, widgets, push, charts, shopping review.

## Engine
- Pure Swift `LedgerEngine` in `Packages/PiPlannerCore` (copies also under `PiPlannerApp/Core/` for the Xcode synchronized app target).
- In-memory only; injectable clock; default demo today **6 Oct 2026** (`Asia/Kolkata`).
- Mock opening **₹1,00,000**; Sync balance **₹1,50,000** → delta **+₹50,000**.
- Exactly one dedicated savings account; standing % must sum to **100**.
- One goal → standing **100%**; `shouldSkipSplitUI` skips Opening split (locks directly after Inflation).
- History credit / manual-add: **open-once** % override, then save → locked.
- Consent Yes = auto mock fetch. Consent No = Manual **or** Balance sync (mock UPI PIN if `linkedInPaytm`).
- **Transfer**, **Delete + redistribution**, **Withdrawal** supported in engine + UI.

## Inflation months
- `monthsRemaining = max(1, (targetYear − todayYear) × 12)` — intra-year offsets ignored.
- Oct 2026 → Mar 2028 = **24** months; Car ₹10L @ 7% → adjusted **₹11,44,900**; after ₹60k saved → **₹45,204**/mo.

## Grok
- `TemplateCopyProvider` is the default (always works offline).
- `GrokCopyProvider` optional: endpoint/API key from **env** `GROK_ENDPOINT` / `GROK_API_KEY` or **Info.plist** keys only — never hardcoded secrets.
- UI shows template first, then optionally upgrades; ledger never waits on Grok.
- Includes proposal, inflation sentence, sync narration, **transfer narration**, Ask answers.

## FE-009 vs FE-008
- Fresh rebuild from complete scope (NO cuts).
- All screens: Welcome, Accounts, Consent, Update balance, UPI PIN, Manual amount, Goal chat/form, Inflation, Opening split, Goals, History list+entry, Goal detail, Standing split, Sync/Update, Transfer, Delete, Withdrawal, Ask, Grok templates (incl transfer), Settings/Reset demo.

## Xcode risks
- Hand-written `project.pbxproj` **objectVersion 77** + `PBXFileSystemSynchronizedRootGroup` on `PiPlannerApp/`.
- Requires **Xcode 16+** (objectVersion 77). Older Xcode may fail to open.
- `GENERATE_INFOPLIST_FILE=YES`. Engine tests via SPM `swift test` (not an Xcode test target).
- Core sources are duplicated under the app folder (same pattern as FE-007/FE-008) so the synced group compiles without a local package dependency — keep package + app Core in sync when editing.
- **HistoryEntryView**: use `else if !entry.saved` after `if let entry` — do **not** nest `else if let entry` (avoids SwiftUI bug).

## Untouched
- Sibling Desktop folders, other workspaces — not modified.
