//
//  WorkoutPhase.swift
//  WorkoutCounter
//
//  Created by Nohemy Pereira-Veiga Moyar on 22/11/25.
//
// [WorkoutPhase.swift - Phase Enum]
import Foundation

/// Phases of a rep:
/// - concentric: lifting/shortening
/// - eccentric: lowering/lengthening
enum WorkoutPhase: String, Codable, CaseIterable, Equatable {
    case concentric = "Concentric"
    case eccentric  = "Eccentric"
}

extension WorkoutPhase {
    /// Optional: visual/coach cues you might show in the UI
    var coachCue: String { self == .concentric ? "1–2–3" : "1–2" }
}
