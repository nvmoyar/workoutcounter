// filepath: /Users/nvmoyar/Documents/workspace/WorkoutCounter/WorkoutCounter/WorkoutView.swift
//
//  WorkoutView.swift
//  WorkoutCounter
//
//  Created by Nohemy Pereira-Veiga Moyar on 18/6/25.
//

// [WorkoutView.swift - UI Layout]
// [WorkoutView.swift - Full File v1.3 (Two Progress Bars UI + Safe Controls)]
import SwiftUI

struct WorkoutView: View {
    // View owns the lifecycle of the brain (ViewModel)
    @StateObject private var vm = WorkoutViewModel()

    var body: some View {
        VStack(spacing: 28) {

            // ───────────────────────────────────────────────────────────────
            // [Inputs] Sets, Reps, Phase Durations (disabled while running)
            // ───────────────────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 18) {

                // [WorkoutView.swift/Input - Sets]
                HStack {
                    Text("Number of sets")
                    Spacer()
                    Stepper(value: $vm.sets, in: 1...50) {
                        Text("\(vm.sets)")
                            .monospacedDigit()
                    }
                    .accessibilityIdentifier("setsStepper")
                }

                // [WorkoutView.swift/Input - Reps]
                HStack {
                    Text("Number of reps")
                    Spacer()
                    Stepper(value: $vm.repsPerSet, in: 1...500) {
                        Text("\(vm.repsPerSet)")
                            .monospacedDigit()
                    }
                    .accessibilityIdentifier("repsStepper")
                }

                // [WorkoutView.swift/Input - Phase Durations]
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Time interval concentric phase")
                        Spacer()
                        Stepper(value: $vm.concDuration, in: 0.1...10.0, step: 0.1) {
                            Text(String(format: "%.1fs", vm.concDuration))
                                .monospacedDigit()
                        }
                        .accessibilityIdentifier("concStepper")
                    }
                    HStack {
                        Text("Time interval eccentric phase")
                        Spacer()
                        Stepper(value: $vm.eccDuration, in: 0.1...10.0, step: 0.1) {
                            Text(String(format: "%.1fs", vm.eccDuration))
                                .monospacedDigit()
                        }
                        .accessibilityIdentifier("eccStepper")
                    }
                }

                // [WorkoutView.swift/Derived - Rep Duration Hint]
                Text(String(format: "Rep duration: %.1fs", vm.repDuration))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("repDurationHint")
            }
            .font(.title3)
            .padding(.horizontal)
            .disabled(vm.isRunning) // prevent mid-rep reconfiguration to keep UX predictable

            // ───────────────────────────────────────────────────────────────
            // [Status + Dual Progress Bars]
            // ───────────────────────────────────────────────────────────────
            VStack(spacing: 12) {
                // [WorkoutView.swift/Status - Set & Rep]
                Text(statusTitle)
                    .font(.headline)
                    .accessibilityIdentifier("statusTitle")

                // [WorkoutView.swift/Status - Phase Label]
                Text(phaseSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("phaseSubtitle")

                // [WorkoutView.swift/Progress - Concentric]
                VStack(spacing: 6) {
                    HStack {
                        Text("Concentric")
                            .font(.subheadline)
                        Spacer()
                        Text("\(String(format: "%.1f", vm.concElapsedDisplay)) / \(String(format: "%.1f", vm.concDuration)) s")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    ProgressView(value: vm.concentricProgress)
                        .progressViewStyle(.linear)
                        .tint(vm.phase == .concentric ? .primary : .secondary)
                        .animation(.easeInOut(duration: 0.12), value: vm.concentricProgress)
                        .accessibilityIdentifier("concentricProgress")
                }

                // [WorkoutView.swift/Progress - Eccentric]
                VStack(spacing: 6) {
                    HStack {
                        Text("Eccentric")
                            .font(.subheadline)
                        Spacer()
                        Text("\(String(format: "%.1f", vm.eccElapsedDisplay)) / \(String(format: "%.1f", vm.eccDuration)) s")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    ProgressView(value: vm.eccentricProgress)
                        .progressViewStyle(.linear)
                        .tint(vm.phase == .eccentric ? .primary : .secondary)
                        .animation(.easeInOut(duration: 0.12), value: vm.eccentricProgress)
                        .accessibilityIdentifier("eccentricProgress")
                }

                // [WorkoutView.swift/Cue - Coach-Style Rhythm] (optional visual help)
                Text(coachCueLine)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("coachCue")
            }
            .padding(.horizontal)

            Spacer(minLength: 8)

            // ───────────────────────────────────────────────────────────────
            // [Controls] Play/Resume, Pause, Reset
            // ───────────────────────────────────────────────────────────────
            HStack(spacing: 40) {
                // [WorkoutView.swift/Control - Play or Resume]
                Button {
                    if vm.isFinished || vm.currentRep == 0 {
                        vm.start()
                    } else {
                        vm.resume()
                    }
                } label: {
                    controlCircle(icon: "play.fill", label: "PLAY")
                }
                .accessibilityIdentifier("playButton")

                // [WorkoutView.swift/Control - Pause]
                Button {
                    vm.pause()
                } label: {
                    controlCircle(icon: "pause.fill", label: "PAUSE")
                }
                .disabled(!vm.isRunning)
                .opacity(vm.isRunning ? 1 : 0.35)
                .accessibilityIdentifier("pauseButton")

                // [WorkoutView.swift/Control - Reset]
                Button {
                    vm.reset()
                } label: {
                    controlCircle(icon: "arrow.counterclockwise", label: "RESET")
                }
                .accessibilityIdentifier("resetButton")
            }
            .padding(.bottom, 24)
        }
        .padding(.top, 8)
    }

    // ────────────────────────────────────────────────────────────

    // MARK: - View helpers (computed strings + small control factory)
    private var statusTitle: String {
        // compact status line
        "Set \(vm.currentSet)/\(vm.sets)   ·   Rep \(max(vm.currentRep, 0))/\(vm.repsPerSet)"
    }

    private var phaseSubtitle: String {
        let elapsed = String(format: "%.1f", vm.phaseElapsed)
        let total = String(format: "%.1f", vm.phaseTotal)
        return "\(vm.phase.rawValue)  \(elapsed) / \(total) s"
    }

    private var coachCueLine: String {
        guard vm.currentRep > 0 && vm.isRunning else { return "" }
        let remaining = max(vm.phaseTotal - vm.phaseElapsed, 0)
        let rem = String(format: "%.1f", remaining)
        return vm.phase == .concentric ? "Contract — \(rem)s remaining" : "Lengthen — \(rem)s remaining"
    }

    private func controlCircle(icon: String, label: String) -> some View {
        ZStack {
            Circle()
                .stroke(.primary, lineWidth: 2)
                .frame(width: 72, height: 72)
            Image(systemName: icon)
                .font(.system(size: 36, weight: .bold))
            Text(label)
                .font(.caption2)
                .offset(y: 22)
        }
    }
}
