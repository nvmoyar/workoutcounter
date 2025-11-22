//
//  WorkoutViewModel.swift
//  WorkoutCounter
//
//  Created by Nohemy Pereira-Veiga Moyar on 18/6/25.
//

// [WorkoutViewModel.swift - Core Logic]
// [WorkoutViewModel.swift - Full File v1.3 (Phased Timer + Two Progress Bars, 0.1s)]
import Foundation
import Combine

@MainActor
final class WorkoutViewModel: ObservableObject {
    // MARK: - Configuration (editable from the UI)
    @Published var sets: Int = 3
    @Published var repsPerSet: Int = 25
    @Published var concDuration: Double = 3.0   // seconds, 0.1 ... 10.0
    @Published var eccDuration: Double  = 2.0   // seconds, 0.1 ... 10.0

    // MARK: - Runtime State (read-only to the View)
    @Published private(set) var currentSet: Int = 1
    @Published private(set) var currentRep: Int = 0     // stays 0 until Start
    @Published private(set) var phase: WorkoutPhase = .concentric
    @Published private(set) var phaseElapsed: Double = 0.0
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var isFinished: Bool = false

    // MARK: - Timer
    private var timer: Timer?
    private let tick: Double = 0.1     // 100ms resolution supports 0.1s phase steps
    private let eps: Double  = 1e-6    // tiny epsilon for float comparisons

    // MARK: - Derived
    var repDuration: Double { concDuration + eccDuration }

    /// Total time for the current phase
    var phaseTotal: Double {
        phase == .concentric ? concDuration : eccDuration
    }

    /// 0→1 across the *current* phase (for a generic single progress bar if you need it)
    var phaseProgress: Double {
        guard phaseTotal > 0 else { return 0 }
        return min(max(phaseElapsed / phaseTotal, 0), 1)
    }

    // MARK: - Dual Progress Bars (per-phase)
    /// Concentric bar fills 0→1 while in concentric, stays at 1 during eccentric, resets on next rep.
    var concentricProgress: Double {
        guard currentRep > 0 else { return 0 }
        if phase == .concentric {
            return concDuration > 0 ? min(phaseElapsed / concDuration, 1) : 0
        } else {
            return concDuration > 0 ? 1 : 0
        }
    }

    /// Eccentric bar is 0 during concentric and fills 0→1 while in eccentric, resets on next rep.
    var eccentricProgress: Double {
        guard currentRep > 0 else { return 0 }
        if phase == .eccentric {
            return eccDuration > 0 ? min(phaseElapsed / eccDuration, 1) : 0
        } else {
            return 0
        }
    }

    /// Nicely formatted elapsed values for labels beside each bar
    var concElapsedDisplay: Double {
        guard currentRep > 0 else { return 0 }
        return phase == .concentric ? phaseElapsed : concDuration
    }

    var eccElapsedDisplay: Double {
        guard currentRep > 0 else { return 0 }
        return phase == .eccentric ? phaseElapsed : 0
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

    // MARK: - Internal helpers
    private var validDurations: Bool {
        concDuration >= 0.1 && concDuration <= 10.0 &&
        eccDuration  >= 0.1 && eccDuration  <= 10.0
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
        // Use .common so UI interactions don’t pause the timer.
        timer = Timer.scheduledTimer(withTimeInterval: tick, repeats: true) { [weak self] _ in
            // Ensure we hop back to the main actor for state changes.
            Task { @MainActor in
                self?.tickForward()
            }
        }
        if let timer {
            RunLoop.current.add(timer, forMode: .common)
        }
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
