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
import SwiftUI

struct WorkoutView: View {
    @StateObject private var vm = WorkoutViewModel()

    var body: some View {
        VStack(spacing: 28) {

            // ───────────────────────────────────────────────────────────────
            // INPUTS (disabled while running to avoid mid-rep surprises)
            // ───────────────────────────────────────────────────────────────
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

                // Durations
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

                // Beats (2 or 3) – segmented
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Concentric beats")
                        Spacer()
                        Picker("Concentric beats", selection: $vm.concBeats) {
                            Text("2").tag(2)
                            Text("3").tag(3)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)
                    }

                    HStack {
                        Text("Eccentric beats")
                        Spacer()
                        Picker("Eccentric beats", selection: $vm.eccBeats) {
                            Text("2").tag(2)
                            Text("3").tag(3)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)
                    }
                }

                Text(String(format: "Rep duration: %.1fs", vm.repDuration))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .font(.title3)
            .padding(.horizontal)
            .disabled(vm.isRunning)

            // ───────────────────────────────────────────────────────────────
            // STATUS + STEP PROGRESS (JUMPS)
            // ───────────────────────────────────────────────────────────────
            VStack(spacing: 16) {
                Text(statusTitle)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Text(phaseSubtitle)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)

                // Concentric bar (jumps)
                VStack(spacing: 6) {
                    HStack {
                        Text("Concentric")
                            .font(.title3.weight(.semibold))
                        Spacer()
                        Text("\(String(format: \"%.1f\", vm.concElapsedDisplay)) / \(String(format: \"%.1f\", vm.concDuration)) s")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    ProgressView(value: vm.concentricStepProgress)
                        .progressViewStyle(.linear)
                        .tint(vm.phase == .concentric ? .primary : .secondary)
                        .animation(.easeInOut(duration: 0.1), value: vm.concentricStepProgress)
                        .scaleEffect(y: 1.3, anchor: .center)
                }

                // Eccentric bar (jumps)
                VStack(spacing: 6) {
                    HStack {
                        Text("Eccentric")
                            .font(.title3.weight(.semibold))
                        Spacer()
                        Text("\(String(format: \"%.1f\", vm.eccElapsedDisplay)) / \(String(format: \"%.1f\", vm.eccDuration)) s")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    ProgressView(value: vm.eccentricStepProgress)
                        .progressViewStyle(.linear)
                        .tint(vm.phase == .eccentric ? .primary : .secondary)
                        .animation(.easeInOut(duration: 0.1), value: vm.eccentricStepProgress)
                        .scaleEffect(y: 1.3, anchor: .center)
                }

                // Coach-style cue: show current beat of total
                Text(coachCueLine)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            Spacer(minLength: 8)

            // ───────────────────────────────────────────────────────────────
            // CONTROLS
            // ───────────────────────────────────────────────────────────────
            HStack(spacing: 40) {
                Button {
                    if vm.isFinished || vm.currentRep == 0 { vm.start() } else { vm.resume() }
                } label: { controlCircle(icon: "play.fill", label: "PLAY") }

                Button {
                    vm.pause()
                } label: { controlCircle(icon: "pause.fill", label: "PAUSE") }
                .disabled(!vm.isRunning)
                .opacity(vm.isRunning ? 1 : 0.35)

                Button {
                    vm.reset()
                } label: { controlCircle(icon: "arrow.counterclockwise", label: "RESET") }
            }
            .padding(.bottom, 24)
        }
        .padding(.top, 8)
    }

    // MARK: - Private UI helpers

    private var statusTitle: String {
        "Set \(vm.currentSet)/\(vm.sets) · Rep \(max(vm.currentRep, 0))/\(vm.repsPerSet)"
    }

    private var phaseSubtitle: String {
        if vm.isFinished { return "Finished — great job!" }
        if vm.currentRep == 0 { return "Ready" }
        return "\(vm.phase.rawValue)  \(String(format: \"%.1f\", vm.phaseElapsed)) / \(String(format: \"%.1f\", vm.phaseTotal)) s"
    }

    private var coachCueLine: String {
        guard vm.currentRep > 0 else { return "—" }
        // e.g., "Beat 2/3 (Concentric) | Rep 7"
        return "Beat \(vm.currentBeatInPhase)/\(vm.phaseBeats) (\(vm.phase.rawValue))  |  Rep \(vm.currentRep)"
    }

    @ViewBuilder
    private func controlCircle(icon: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .bold))
                .frame(width: 70, height: 70)
                .background(Circle().strokeBorder(.primary, lineWidth: 2))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// [WorkoutView.swift - Live Preview]
#Preview { WorkoutView() }
