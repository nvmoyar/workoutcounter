// filepath: /Users/nvmoyar/Documents/workspace/WorkoutCounter/WorkoutCounter/WorkoutView.swift
//
//  WorkoutView.swift
//  WorkoutCounter
//
//  Created by Nohemy Pereira-Veiga Moyar on 18/6/25.
//

// [WorkoutView.swift - UI Layout]
// [WorkoutView.swift - Full File v1.3 (Two Progress Bars UI + Safe Controls)]
// [WorkoutView.swift - Full File v1.4 (Beats UI + Step Progress Jumps)]
// [WorkoutView.swift - Full File v1.6 (Beats 1/2/3, Step Progress, Optional 1-2-3 Rows)]
// [WorkoutView.swift - Full File v1.6.2 (Snap steps; align beat row with bar)]
// [WorkoutView.swift - CHANGED v1.7 (UI for Presets: pick, save, update, delete)]
import SwiftUI

struct WorkoutView: View {
    @StateObject private var vm = WorkoutViewModel()
    @StateObject private var store = PresetStore()

    @State private var showSaveSheet = false
    @State private var newPresetName: String = ""

    var body: some View {
        VStack(spacing: 20) {

            // ────────────── PRESETS ──────────────
            GroupBox("Presets") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Active preset")
                        Spacer()
                        Picker("Active preset", selection: $store.selectedID) {
                            ForEach(storePresets) { p in
                                Text(p.name).tag(p.id as UUID?)
                            }
                        }
                        .frame(minWidth: 220)
                        .disabled(vm.isRunning) // avoid mid-rep changes
                    }

                    HStack(spacing: 12) {
                        Button {
                            newPresetName = suggestedPresetName()
                            showSaveSheet = true
                        } label: {
                            Label("Save as New", systemImage: "plus.circle")
                        }
                        .disabled(vm.isRunning)

                        Button {
                            guard let id = store.selectedID,
                                  let current = store.preset(id: id) else { return }
                            // overwrite fields with current VM config, keep id & name
                            let updated = WorkoutPreset(
                                id: current.id,
                                name: current.name,
                                sets: vm.sets,
                                repsPerSet: vm.repsPerSet,
                                concDuration: vm.concDuration,
                                eccDuration: vm.eccDuration,
                                concBeats: vm.concBeats,
                                eccBeats: vm.eccBeats,
                                createdAt: current.createdAt
                            )
                            store.update(id: current.id, with: updated)
                        } label: {
                            Label("Update Selected", systemImage: "square.and.arrow.down")
                        }
                        .disabled(vm.isRunning || store.selectedID == nil)

                        Button(role: .destructive) {
                            if let id = store.selectedID { store.delete(id: id) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .disabled(vm.isRunning || store.selectedID == nil)
                    }
                }
            }
            .padding(.horizontal)

            // When preset selection changes, apply to VM
            .onChange(of: store.selectedID) { _, newValue in
                if let preset = store.preset(id: newValue) {
                    vm.apply(preset: preset)
                }
            }
            // ─────────── END PRESETS ────────────

            // … the rest of your existing UI (Inputs, Status, Bars, Controls) from v1.6.2 …

            // INPUTS (disabled while running)
            inputsSection

            statusAndBarsSection

            Spacer(minLength: 8)

            controlsSection
                .padding(.bottom, 24)
        }
        .padding(.top, 8)
        .sheet(isPresented: $showSaveSheet) {
            NavigationStack {
                Form {
                    Section("Preset name") {
                        // Apply platform-appropriate autocapitalization only on iOS (and Mac Catalyst).
                        #if os(iOS) || targetEnvironment(macCatalyst)
                        if #available(iOS 15, *) {
                            TextField("Enter a name", text: $newPresetName)
                                .textInputAutocapitalization(.words)
                        } else {
                            // Older iOS versions use `.autocapitalization`.
                            TextField("Enter a name", text: $newPresetName)
                                .autocapitalization(.words)
                        }
                        #else
                        // Other platforms (macOS/watchOS) — no autocapitalization modifier applied.
                        TextField("Enter a name", text: $newPresetName)
                        #endif
                    }
                    Section("Will save current configuration") {
                        configSummary
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .navigationTitle("Save Preset")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showSaveSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let preset = vm.makePreset(named: newPresetName.isEmpty ? suggestedPresetName() : newPresetName)
                            store.add(preset)
                            showSaveSheet = false
                        }
                        .disabled(vm.isRunning)
                    }
                }
            }
        }
    }

    // MARK: - Subviews pulled from your v1.6.2 view

    private var inputsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Number of sets")
                Spacer()
                Stepper(value: $vm.sets, in: 1...50) {
                    Text("\(vm.sets)").monospacedDigit()
                }
            }
            HStack {
                Text("Number of reps")
                Spacer()
                Stepper(value: $vm.repsPerSet, in: 1...500) {
                    Text("\(vm.repsPerSet)").monospacedDigit()
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Concentric duration")
                    Spacer()
                    Stepper(value: $vm.concDuration, in: 0.1...10.0, step: 0.1) {
                        Text(String(format: "%.1fs", vm.concDuration)).monospacedDigit()
                    }
                }
                HStack {
                    Text("Eccentric duration")
                    Spacer()
                    Stepper(value: $vm.eccDuration, in: 0.1...10.0, step: 0.1) {
                        Text(String(format: "%.1fs", vm.eccDuration)).monospacedDigit()
                    }
                }
            }

            // Beats (1,2,3,4)
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Concentric beats")
                    Spacer()
                    Picker("Concentric beats", selection: $vm.concBeats) {
                        Text("1").tag(1); Text("2").tag(2); Text("3").tag(3); Text("4").tag(4)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }
                HStack {
                    Text("Eccentric beats")
                    Spacer()
                    Picker("Eccentric beats", selection: $vm.eccBeats) {
                        Text("1").tag(1); Text("2").tag(2); Text("3").tag(3); Text("4").tag(4)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }
            }
            
            /*
            // Optional 1–2–3 toggles
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Show 1-2-3 (Concentric)", isOn: $vm.showConcBeatNumbers)
                Toggle("Show 1-2-3 (Eccentric)",  isOn: $vm.showEccBeatNumbers)
            }
             */
            Text(String(format: "Rep duration: %.1fs", vm.repDuration))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .font(.title3)
        .padding(.horizontal)
        .disabled(vm.isRunning)
    }

    private var statusAndBarsSection: some View {
        VStack(spacing: 16) {
            Text(statusTitle)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .monospacedDigit()
            Text(phaseSubtitle)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            // Concentric
            VStack(spacing: 6) {
                HStack {
                    Text("Concentric").font(.title3.weight(.semibold))
                    Spacer()
                    Text("\(String(format: "%.1f", vm.concElapsedDisplay)) / \(String(format: "%.1f", vm.concDuration)) s")
                        .font(.callout).foregroundStyle(.secondary).monospacedDigit()
                }
                ProgressView(value: vm.concentricStepProgress)
                    .progressViewStyle(.linear)
                    .tint(vm.phase == .concentric ? .primary : .secondary)
                    .scaleEffect(y: 1.3, anchor: .center)
                if vm.showConcBeatNumbers {
                    beatRow(total: vm.concBeatsEffective, activeIndex: vm.activeBeatConcentric)
                }
            }

            // Eccentric
            VStack(spacing: 6) {
                HStack {
                    Text("Eccentric").font(.title3.weight(.semibold))
                    Spacer()
                    Text("\(String(format: "%.1f", vm.eccElapsedDisplay)) / \(String(format: "%.1f", vm.eccDuration)) s")
                        .font(.callout).foregroundStyle(.secondary).monospacedDigit()
                }
                ProgressView(value: vm.eccentricStepProgress)
                    .progressViewStyle(.linear)
                    .tint(vm.phase == .eccentric ? .primary : .secondary)
                    .scaleEffect(y: 1.3, anchor: .center)
                if vm.showEccBeatNumbers {
                    beatRow(total: vm.eccBeatsEffective, activeIndex: vm.activeBeatEccentric)
                }
            }

            Text(coachCueLine)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }

    private var controlsSection: some View {
        HStack(spacing: 40) {
            Button {
                if vm.isFinished || vm.currentRep == 0 { vm.start() } else { vm.resume() }
            } label: { controlCircle(icon: "play.fill", label: "PLAY") }

            Button { vm.pause() }
            label: { controlCircle(icon: "pause.fill", label: "PAUSE") }
            .disabled(!vm.isRunning)
            .opacity(vm.isRunning ? 1 : 0.35)

            Button { vm.reset() }
            label: { controlCircle(icon: "arrow.counterclockwise", label: "RESET") }
        }
    }

    // MARK: - Helpers reused from your earlier version
    private var statusTitle: String {
        "Set \(vm.currentSet)/\(vm.sets) · Rep \(max(vm.currentRep, 0))/\(vm.repsPerSet)"
    }
    private var phaseSubtitle: String {
        if vm.isFinished { return "Finished — great job!" }
        if vm.currentRep == 0 { return "Ready" }
        return "\(vm.phase.rawValue)  \(String(format: "%.1f", vm.phaseElapsed)) / \(String(format: "%.1f", vm.phaseTotal)) s"
    }
    private var coachCueLine: String {
        guard vm.currentRep > 0 else { return "—" }
        return /*"Beat \(vm.currentBeatInPhase)/\(vm.phaseBeats)*/ "(\(vm.phase.rawValue))  |  Rep \(vm.currentRep)"
    }
    @ViewBuilder
    private func controlCircle(icon: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .bold))
                .frame(width: 70, height: 70)
                .background(Circle().strokeBorder(.primary, lineWidth: 2))
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }
    @ViewBuilder
    private func beatRow(total: Int, activeIndex: Int) -> some View {
        HStack(spacing: 16) {
            ForEach(1...total, id: \.self) { i in
                Text("\(i)")
                    .font(.title3.weight(i == activeIndex ? .bold : .regular))
                    .foregroundStyle(i == activeIndex ? .primary : .secondary)
                    .opacity(i == activeIndex ? 1 : 0.35)
                    .monospacedDigit()
            }
        }
        .padding(.top, 2)
        .accessibilityIdentifier("beatRow\(total)")
    }

    private var storePresets: [WorkoutPreset] { store.presets }

    private func suggestedPresetName() -> String {
        // e.g., "Preset 3-2 · 12x3"
        "Preset \(vm.concBeats)-\(vm.eccBeats) · \(vm.repsPerSet)x\(vm.sets)"
    }

    private var configSummary: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Sets/Reps: \(vm.sets)x\(vm.repsPerSet)")
            Text(String(format: "Concentric: %.1fs (%d beats)", vm.concDuration, vm.concBeats))
            Text(String(format: "Eccentric:  %.1fs (%d beats)", vm.eccDuration, vm.eccBeats))
        }
    }
}

// [WorkoutView.swift - Live Preview]
#Preview { WorkoutView() }
