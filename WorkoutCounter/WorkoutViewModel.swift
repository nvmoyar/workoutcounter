//
//  WorkoutViewModel.swift
//  WorkoutCounter
//
//  Created by Nohemy Pereira-Veiga Moyar on 18/6/25.
//

// [WorkoutViewModel.swift - Core Logic]
import Foundation
import Combine

class WorkoutViewModel: ObservableObject {
    @Published var sets: Int = 3
    @Published var repsPerSet: Int = 20
    @Published var interval: TimeInterval = 1.0

    @Published var currentSet: Int = 1
    @Published var currentRep: Int = 0
    @Published var isRunning: Bool = false

    private var timer: Timer?

    func start() {
        resetProgress()
        isRunning = true
        startTimer()
    }

    func pause() {
        timer?.invalidate()
        isRunning = false
    }

    func reset() {
        pause()
        resetProgress()
    }

    private func resetProgress() {
        currentSet = 1
        currentRep = 0
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            self.advanceRep()
        }
    }

    private func advanceRep() {
        guard isRunning else { return }

        if currentRep < repsPerSet {
            currentRep += 1
        } else {
            if currentSet < sets {
                currentSet += 1
                currentRep = 1
            } else {
                self.pause() // workout complete
            }
        }
    }
}
