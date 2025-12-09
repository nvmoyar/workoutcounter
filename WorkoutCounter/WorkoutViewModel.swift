//
//  WorkoutViewModel.swift
//  WorkoutCounter
//
//  Created by Nohemy Pereira-Veiga Moyar on 18/6/25.
//

// [WorkoutViewModel.swift - Core Logic]
// [WorkoutViewModel.swift - Full File v1.3 (Phased Timer + Two Progress Bars, 0.1s)]
// [WorkoutViewModel.swift - Full File v1.4 (Beats: 2/3, Step Progress, 0.1s)]
// [WorkoutViewModel.swift - Full File v1.6 (Beats 1/2/3, Step Progress, Optional 1-2-3)]
// [WorkoutViewModel.swift - Full File v1.6.1 (Bugfix: show 100% at phase end)]
import Foundation
import Combine

@MainActor
final class WorkoutViewModel: ObservableObject {
    // MARK: - Configuration
    @Published var sets: Int = 3
    @Published var repsPerSet: Int = 25

    /// Phase durations in seconds (0.1 ... 10.0)
    @Published var concDuration: Double = 3.0
    @Published var eccDuration:  Double = 2.0

    /// Discrete beats (pulses) per phase. Allowed: 1, 2, or 3
    @Published var concBeats: Int = 3
    @Published var eccBeats:  Int = 3

    /// Optional per-phase numeric cues "1-2-3"
    @Published var showConcBeatNumbers: Bool = false
    @Published var showEccBeatNumbers:  Bool = false

    // MARK: - Runtime State
    @Published private(set) var currentSet: Int = 1
    @Published private(set) var currentRep: Int = 0
    @Published private(set) var phase: WorkoutPhase = .concentric
    @Published private(set) var phaseElapsed: Double = 0.0
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var isFinished: Bool = false

    // MARK: - Timer
    private var timer: Timer?
    private let tick: Double = 0.1
    private let eps: Double  = 1e-6

    // MARK: - Internal guards
    private var phaseSwitchPending = false   // ensures we don’t switch twice

    // MARK: - Derived
    var repDuration: Double { concDuration + eccDuration }

    /// Effective beats (clamped to 1...3)
    var concBeatsEffective: Int { min(max(concBeats, 1), 3) }
    var eccBeatsEffective:  Int { min(max(eccBeats,  1), 3) }

    /// Sub-beat durations per phase
    private var concSubBeat: Double { concDuration / Double(concBeatsEffective) }
    private var eccSubBeat:  Double { eccDuration  / Double(eccBeatsEffective) }

    /// Total time for the active phase
    var phaseTotal: Double { phase == .concentric ? concDuration : eccDuration }

    // MARK: - Step Progress (JUMPS at beat boundaries)
    var concentricStepProgress: Double {
        guard currentRep > 0 else { return 0 }
        if phase == .concentric {
            let completedBeats = min(Int(floor((phaseElapsed + eps) / concSubBeat)), concBeatsEffective)
            return Double(completedBeats) / Double(concBeatsEffective)
        } else {
            return 1.0
        }
    }

    var eccentricStepProgress: Double {
        guard currentRep > 0 else { return 0 }
        if phase == .eccentric {
            let completedBeats = min(Int(floor((phaseElapsed + eps) / eccSubBeat)), eccBeatsEffective)
            return Double(completedBeats) / Double(eccBeatsEffective)
        } else {
            return 0.0
        }
    }

    // Display helpers
    var concElapsedDisplay: Double {
        guard currentRep > 0 else { return 0 }
        return phase == .concentric ? phaseElapsed : concDuration
    }
    var eccElapsedDisplay: Double {
        guard currentRep > 0 else { return 0 }
        return phase == .eccentric ? phaseElapsed : 0
    }
    var currentBeatInPhase: Int {
        guard currentRep > 0 else { return 0 }
        if phase == .concentric {
            return min(Int(phaseElapsed / concSubBeat) + 1, concBeatsEffective)
        } else {
            return min(Int(phaseElapsed / eccSubBeat) + 1, eccBeatsEffective)
        }
    }
    var phaseBeats: Int { phase == .concentric ? concBeatsEffective : eccBeatsEffective }

    // MARK: - Controls
    func start() {
        resetProgress()
        guard validDurations else { return }
        currentRep = 1
        isRunning = true
        scheduleTimer()
    }

    func resume() {
        guard !isFinished, !isRunning else { return }
        isRunning = true
        scheduleTimer()
    }

    func pause() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    func reset() {
        pause()
        resetProgress()
    }

    // MARK: - Internals
    private var validDurations: Bool {
        (0.1...10.0).contains(concDuration) &&
        (0.1...10.0).contains(eccDuration)
    }

    private func resetProgress() {
        currentSet = 1
        currentRep = 0
        phase = .concentric
        phaseElapsed = 0
        isFinished = false
        phaseSwitchPending = false
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: tick, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tickForward() }
        }
        if let timer { RunLoop.current.add(timer, forMode: .common) }
    }

    private func tickForward() {
        guard isRunning else { return }

        let target = (phase == .concentric) ? concDuration : eccDuration
        phaseElapsed += tick

        // If we’ve reached or exceeded the end of this phase, snap to 100%,
        // then switch phase on the next runloop pass so the UI can render full completion.
        if phaseElapsed + eps >= target {
            phaseElapsed = target
            if !phaseSwitchPending {
                phaseSwitchPending = true
                DispatchQueue.main.async { [weak self] in
                    guard let self = self, self.isRunning else { self?.phaseSwitchPending = false; return }
                    self.phaseElapsed = 0
                    if self.phase == .concentric {
                        self.phase = .eccentric
                    } else {
                        self.advanceRepOrSet()
                    }
                    self.phaseSwitchPending = false
                }
            }
            return
        }
    }

    private func advanceRepOrSet() {
        if currentRep < repsPerSet {
            currentRep += 1
            phase = .concentric
        } else if currentSet < sets {
            currentSet += 1
            currentRep = 1
            phase = .concentric
        } else {
            finish()
        }
    }

    private func finish() {
        pause()
        isFinished = true
    }
}
