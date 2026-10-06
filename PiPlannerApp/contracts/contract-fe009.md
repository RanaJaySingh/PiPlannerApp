# Feature: PiPlanner full hackathon rebuild | Request ID: FE-009 | Version: v1 | Date: 2026-10-06

## Changelog
- Supersedes FE-008 In-review tree at ~/Desktop/PiPlannerApp. Fresh rebuild from complete pack. NO cuts.

## Summary
Full SwiftUI iPhone portrait PiPlanner savings-ledger hackathon app. Rebuild ~/Desktop/PiPlannerApp from scratch (or replace contents). Do not touch ~/Desktop/PiPlannerLedger, PiPlanner, or PiPlannerQuantity.

## Standing rule
Source edits **only** via Cursor cloud agent / Cursor Origin. Mac = human Xcode Build/Run/check only. Do not Shell/sed/IDE-edit source on the Mac.

## Design / docs SoT
- Plan v3, SCREEN_FLOW, USER_FLOW (pack complete; check /workspace/pip-hackathon-v3/docs/ and Slack C0C714TQSLV:1791309819.097669)
- Design: https://claude.ai/artifact/VtHM2P9uhkH8o8o2kqFHE5 (J1–J8)

## In scope (NO cuts)
All FE-008 scope plus nothing deferred: Day 1 engine + setup, History list/entry, Goal detail, Standing split, Transfer, Delete, Withdrawal, Ask, Grok proposals (incl. transfer) with templates, Settings/Reset demo. Demo opening ₹1,00,000 → 60/40; Sync +₹50,000; Consent Yes/No; one goal = 100%.

## Out of scope
Login, backend, real bank/payment APIs, Autopay, shopping/review. Leave sibling Desktop folders untouched.

## Acceptance criteria
1. ~/Desktop/PiPlannerApp is the FE-009 app; siblings unchanged
2. Engine tests cover opening 60/40, Sync +50k, one-goal 100%, open-once, transfer, delete, withdrawal
3. Full setup + Goals/History/Ask/Settings flows work
4. Transfer, Delete, Withdrawal, Ask, Grok templates, Reset demo present (no cuts)
5. Source edited via Cursor cloud/Origin only
6. Ready for Xcode check reported to Internal Lead

## Open items
None — pack complete per Lead.
