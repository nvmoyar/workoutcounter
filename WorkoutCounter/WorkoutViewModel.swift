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
// [WorkoutViewModel.swift - Full File v1.6.2 (Sync beats & bars)]
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
    private var phaseSwitchPending = false

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

    // MARK: - Unified beat math
    private func completedBeats(elapsed: Double, subBeat: Double, totalBeats: Int) -> Int {
        guard totalBeats > 0 else { return 0 }
        let sb = max(subBeat, eps)
        return min(Int((elapsed + eps) / sb), totalBeats)
    }

    // MARK: - Step Progress (JUMPS at beat boundaries)
    /// Concentric bar: jumps in [beats] steps while concentric; shows 1.0 during eccentric.
    var concentricStepProgress: Double {
        guard currentRep > 0 else { return 0 }
        if phase == .concentric {
            let cb = completedBeats(elapsed: phaseElapsed, subBeat: concSubBeat, totalBeats: concBeatsEffective)
            return Double(cb) / Double(concBeatsEffective)
        } else {
            return 1.0
        }
    }

    /// Eccentric bar: 0 during concentric; jumps in [beats] steps while eccentric.
    var eccentricStepProgress: Double {
        guard currentRep > 0 else { return 0 }
        if phase == .eccentric {
            let cb = completedBeats(elapsed: phaseElapsed, subBeat: eccSubBeat, totalBeats: eccBeatsEffective)
            return Double(cb) / Double(eccBeatsEffective)
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

    /// Beat number (1-based) for the *active* phase, used in the coach cue
    var currentBeatInPhase: Int {
        guard currentRep > 0 else { return 0 }
        if phase == .concentric {
            let cb = completedBeats(elapsed: phaseElapsed, subBeat: concSubBeat, totalBeats: concBeatsEffective)
            return min(cb + 1, concBeatsEffective)
        } else {
            let cb = completedBeats(elapsed: phaseElapsed, subBeat: eccSubBeat, totalBeats: eccBeatsEffective)
            return min(cb + 1, eccBeatsEffective)
        }
    }

    var phaseBeats: Int { phase == .concentric ? concBeatsEffective : eccBeatsEffective }

    /// Beat number to highlight under each bar (0 = no highlight when phase inactive)
    var activeBeatConcentric: Int {
        guard currentRep > 0, phase == .concentric else { return 0 }
        let cb = completedBeats(elapsed: phaseElapsed, subBeat: concSubBeat, totalBeats: concBeatsEffective)
        return min(cb + 1, concBeatsEffective)
    }

    var activeBeatEccentric: Int {
        guard currentRep > 0, phase == .eccentric else { return 0 }
        let cb = completedBeats(elapsed: phaseElapsed, subBeat: eccSubBeat, totalBeats: eccBeatsEffective)
        return min(cb + 1, eccBeatsEffective)
    }

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

        // Snap to full completion at boundary, then flip phase on next loop
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
    
    // [WorkoutViewModel.swift - CHANGED v1.7 (add apply/make preset helpers)]
    // MARK: - Preset helpers
        func apply(preset: WorkoutPreset) {
            // It’s safer to pause before applying
            pause()
            sets = preset.sets
            repsPerSet = preset.repsPerSet
            concDuration = preset.concDuration
            eccDuration  = preset.eccDuration
            concBeats = preset.concBeats
            eccBeats  = preset.eccBeats
            // Do not alter visual toggles; they are user UI prefs
            reset() // reset progress counters after applying
        }

        func makePreset(named name: String) -> WorkoutPreset {
            WorkoutPreset(
                name: name,
                sets: sets,
                repsPerSet: repsPerSet,
                concDuration: concDuration,
                eccDuration: eccDuration,
                concBeats: concBeats,
                eccBeats: eccBeats
            )
        }
    
}



