//
//  WorkoutPreset.swift
//  WorkoutCounter
//
//  Created by Nohemy Pereira-Veiga Moyar on 9/12/25.
//
// [WorkoutPreset.swift - NEW v1.0]
import Foundation

struct WorkoutPreset: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String

    var sets: Int
    var repsPerSet: Int
    var concDuration: Double
    var eccDuration: Double
    var concBeats: Int
    var eccBeats: Int

    var createdAt: Date

    init(id: UUID = UUID(),
         name: String,
         sets: Int,
         repsPerSet: Int,
         concDuration: Double,
         eccDuration: Double,
         concBeats: Int,
         eccBeats: Int,
         createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.sets = sets
        self.repsPerSet = repsPerSet
        self.concDuration = concDuration
        self.eccDuration = eccDuration
        self.concBeats = concBeats
        self.eccBeats = eccBeats
        self.createdAt = createdAt
    }
}

