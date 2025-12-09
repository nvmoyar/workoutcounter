//
//  WorkoutViewModel.swift
//  WorkoutCounter
//
//  Created by Nohemy Pereira-Veiga Moyar on 18/6/25.
//

// [WorkoutViewModel.swift - Core Logic]
// [WorkoutViewModel.swift - Full File v1.3 (Phased Timer + Two Progress Bars, 0.1s)]
// [WorkoutViewModel.swift - Full File v1.4 (Beats: 2/3, Step Progress, 0.1s)]

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

    /// Number of discrete beats (jumps) per phase. Allowed: 2 or 3
    @Published var concBeats: Int = 3
    @Published var eccBeats:  Int = 3

    // MARK: - Runtime State
    @Published private(set) var currentSet: Int = 1
    @Published private(set) var currentRep: Int = 0
    @Published private(set) var phase: WorkoutPhase = .concentric
    @Published private(set) var phaseElapsed: Double = 0.0
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var isFinished: Bool = false

    // MARK: - Timer
    private var timer: Timer?
    private let tick: Double = 0.1      // 100ms tick to support 0.1s resolution
    private let eps: Double  = 1e-6

    // MARK: - Derived
    var repDuration: Double { concDuration + eccDuration }

    /// Safety clamp (only 2 or 3 supported)
    private var concBeatsClamped: Int { min(max(concBeats, 2), 3) }
    private var eccBeatsClamped:  Int { min(max(eccBeats,  2), 3) }

    /// Sub-beat durations per phase
    private var concSubBeat: Double { concDuration / Double(concBeatsClamped) }
    private var eccSubBeat:  Double { eccDuration  / Double(eccBeatsClamped) }

    /// Total for the current phase
    var phaseTotal: Double {
        phase == .concentric ? concDuration : eccDuration
    }

    // MARK: - Step Progress (JUMPS at beat boundaries)

    /// Concentric bar: jumps in 2 or 3 steps while in concentric;
    /// shows 1.0 during eccentric (concentric already finished this rep).
    var concentricStepProgress: Double {
        guard currentRep > 0 else { return 0 }
        if phase == .concentric {
            let completedBeats = min(Int(floor((phaseElapsed + eps) / concSubBeat)), concBeatsClamped)
            return Double(completedBeats) / Double(concBeatsClamped)
        } else {
            return 1.0
        }
    }

    /// Eccentric bar: 0 during concentric; jumps in 2 or 3 steps while in eccentric.
    var eccentricStepProgress: Double {
        guard currentRep > 0 else { return 0 }
        if phase == .eccentric {
            let completedBeats = min(Int(floor((phaseElapsed + eps) / eccSubBeat)), eccBeatsClamped)
            return Double(completedBeats) / Double(eccBeatsClamped)
        } else {
            return 0.0
        }
    }

    /// Display helpers for labels beside each bar
    var concElapsedDisplay: Double {
        guard currentRep > 0 else { return 0 }
        return phase == .concentric ? phaseElapsed : concDuration
    }
    var eccElapsedDisplay: Double {
        guard currentRep > 0 else { return 0 }
        return phase == .eccentric ? phaseElapsed : 0
    }

    /// Current beat number within the active phase (1-based)
    var currentBeatInPhase: Int {
        guard currentRep > 0 else { return 0 }
        if phase == .concentric {
            return min(Int(phaseElapsed / concSubBeat) + 1, concBeatsClamped)
        } else {
            return min(Int(phaseElapsed / eccSubBeat) + 1, eccBeatsClamped)
        }
    }

    /// Total beats for the active phase
    var phaseBeats: Int {
        phase == .concentric ? concBeatsClamped : eccBeatsClamped
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

    // MARK: - Internal
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
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: tick, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickForward()
            }
        }
        if let timer { RunLoop.current.add(timer, forMode: .common) }
    }

    private func tickForward() {
        guard isRunning else { return }

        let target = (phase == .concentric) ? concDuration : eccDuration
        phaseElapsed += tick

        if phaseElapsed + eps >= target {
            phaseElapsed = 0
            if phase == .concentric {
                phase = .eccentric
            } else {
                advanceRepOrSet()
            }
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
