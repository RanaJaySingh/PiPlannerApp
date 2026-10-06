import SwiftUI

struct GoalsView: View {
    @Environment(AppState.self) private var app
    @State private var showTransfer = false
    @State private var showWithdrawal = false
    @State private var showDelete: Goal?
    @State private var showManualAdd = false
    @State private var showUpdateBalance = false
    @State private var showUPIPin = false
    @State private var redisPercents: [UUID: Double] = [:]
    @State private var errorMessage: String?
    @State private var path: [UUID] = []

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(app.greeting())
                        .font(.title2.bold())
                        .foregroundStyle(PaytmTheme.navy)

                    CardView {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Dedicated balance")
                                .font(.caption)
                                .foregroundStyle(PaytmTheme.textSecondary)
                            Text(INRFormatting.string(app.engine.dedicatedBalance))
                                .font(.largeTitle.bold())
                                .foregroundStyle(PaytmTheme.navy)
                            if let account = app.engine.dedicatedAccount {
                                Text("\(account.displayName) · \(account.maskedLabel)")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(PaytmTheme.textSecondary)
                            }
                        }
                    }

                    if !app.syncNarration.isEmpty {
                        Text(app.syncNarration)
                            .font(.subheadline)
                            .foregroundStyle(PaytmTheme.primaryBlue)
                    }

                    ForEach(app.engine.goals) { goal in
                        Button {
                            path.append(goal.id)
                        } label: {
                            GoalCard(
                                goal: goal,
                                adjusted: app.engine.adjustedTarget(for: goal),
                                required: app.engine.requiredPerMonth(for: goal),
                                months: app.engine.monthsRemaining(for: goal)
                            ) {
                                showDelete = goal
                                let redis = app.engine.defaultRedistribution(forDeletedGoalId: goal.id)
                                redisPercents = Dictionary(uniqueKeysWithValues: redis.map {
                                    ($0.goalId, NSDecimalNumber(decimal: $0.percent).doubleValue)
                                })
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    creditActions

                    HStack(spacing: 12) {
                        Button("Transfer") { showTransfer = true }
                            .font(.headline)
                            .foregroundStyle(PaytmTheme.navy)
                            .frame(maxWidth: .infinity)
                        Button("Withdraw") { showWithdrawal = true }
                            .font(.headline)
                            .foregroundStyle(PaytmTheme.navy)
                            .frame(maxWidth: .infinity)
                    }

                    NavigationLink {
                        StandingSplitView()
                    } label: {
                        Text("Standing split")
                            .font(.headline)
                            .foregroundStyle(PaytmTheme.primaryBlue)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(24)
            }
            .background(PaytmTheme.background.ignoresSafeArea())
            .navigationTitle("Goals")
            .navigationDestination(for: UUID.self) { id in
                GoalDetailView(goalId: id)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Reset demo", role: .destructive) {
                            app.resetDemo()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showTransfer) { TransferView() }
            .sheet(isPresented: $showWithdrawal) { WithdrawalView() }
            .sheet(isPresented: $showManualAdd) {
                NavigationStack {
                    ManualAmountView(isPostSetupAdd: true, onDone: { showManualAdd = false })
                }
            }
            .sheet(isPresented: $showUpdateBalance) {
                NavigationStack {
                    PostSetupUpdateBalanceSheet(
                        onManual: {
                            showUpdateBalance = false
                            showManualAdd = true
                        },
                        onNeedPin: {
                            showUpdateBalance = false
                            showUPIPin = true
                        },
                        onSynced: { showUpdateBalance = false }
                    )
                }
            }
            .sheet(isPresented: $showUPIPin) {
                NavigationStack {
                    PostSetupUPIPINSheet(onDone: { showUPIPin = false })
                }
            }
            .sheet(item: $showDelete) { goal in
                DeleteGoalView(goal: goal, percents: $redisPercents) {
                    confirmDelete(goal)
                }
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .overlay(alignment: .bottom) {
                if let toast = app.toast {
                    Text(toast)
                        .font(.caption)
                        .padding(12)
                        .background(PaytmTheme.navy)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        .padding(.bottom, 12)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                app.toast = nil
                            }
                        }
                }
            }
        }
    }

    @ViewBuilder
    private var creditActions: some View {
        if app.engine.consent == .allowed {
            PrimaryButton(title: "Sync") { sync() }
        } else if app.engine.consentOffPath == .balanceSync {
            PrimaryButton(title: "Sync / Update balance") {
                if app.engine.needsUPIPinForBalanceSync && !app.engine.pinVerified {
                    showUPIPin = true
                } else {
                    sync()
                }
            }
        } else {
            PrimaryButton(title: "Update balance") {
                showUpdateBalance = true
            }
            PrimaryButton(title: "Add amount") {
                showManualAdd = true
            }
        }
    }

    private func sync() {
        do {
            let entry = try app.engine.sync()
            Task { await app.loadSyncNarration(amount: entry.amount) }
            app.openNewHistoryEntry(entry.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func confirmDelete(_ goal: Goal) {
        let redis: [(UUID, Decimal)] = redisPercents.map { ($0.key, Decimal($0.value)) }
        do {
            _ = try app.engine.deleteGoal(id: goal.id, redistribution: redis)
            showDelete = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct GoalCard: View {
    let goal: Goal
    let adjusted: Decimal
    let required: Decimal
    let months: Int
    let onDelete: () -> Void

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(goal.name).font(.headline)
                    Spacer()
                    Text("\(goal.standingPercent)%")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(PaytmTheme.primaryBlue.opacity(0.15))
                        .clipShape(Capsule())
                }
                Text("Saved \(INRFormatting.string(goal.saved))")
                    .foregroundStyle(PaytmTheme.success)
                Text("Target \(INRFormatting.string(goal.target)) → adjusted \(INRFormatting.string(adjusted))")
                    .font(.caption)
                    .foregroundStyle(PaytmTheme.textSecondary)
                Text("Required ~\(INRFormatting.string(required))/mo · \(months) months")
                    .font(.subheadline.bold())
                    .foregroundStyle(PaytmTheme.navy)
                Button("Delete", role: .destructive, action: onDelete)
                    .font(.caption)
            }
        }
    }
}
