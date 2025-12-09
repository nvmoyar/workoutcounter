//
//  PresetStore.swift
//  WorkoutCounter
//
//  Created by Nohemy Pereira-Veiga Moyar on 9/12/25.
// [PresetStore.swift - NEW v1.0]
import Foundation
import Combine

@MainActor
final class PresetStore: ObservableObject {
    @Published private(set) var presets: [WorkoutPreset] = []
    @Published var selectedID: UUID?

    private let storageKey = "workout_presets_v1"

    init() {
        load()
        if presets.isEmpty {
            presets = Self.defaultPresets
            selectedID = presets.first?.id
            save()
        }
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            let decoded = try JSONDecoder().decode([WorkoutPreset].self, from: data)
            presets = decoded
            // try to keep a previous selection if possible
            if selectedID == nil { selectedID = presets.first?.id }
        } catch {
            // If corrupted, reset to defaults
            presets = Self.defaultPresets
            selectedID = presets.first?.id
            save()
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(presets)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            // no-op for now
        }
    }

    func add(_ preset: WorkoutPreset) {
        presets.append(preset)
        selectedID = preset.id
        save()
    }

    func update(id: UUID, with updated: WorkoutPreset) {
        guard let i = presets.firstIndex(where: { $0.id == id }) else { return }
        // Preserve name & id from the original unless changed in `updated`
        presets[i] = updated
        save()
    }

    func delete(id: UUID) {
        presets.removeAll { $0.id == id }
        if !presets.isEmpty {
            selectedID = presets.first?.id
        } else {
            selectedID = nil
        }
        save()
    }

    func preset(id: UUID?) -> WorkoutPreset? {
        guard let id else { return nil }
        return presets.first(where: { $0.id == id })
    }

    static let defaultPresets: [WorkoutPreset] = [
        WorkoutPreset(name: "Tempo 3-2 (Standard)",
                      sets: 3, repsPerSet: 12,
                      concDuration: 3.0, eccDuration: 2.0,
                      concBeats: 3, eccBeats: 2),
        WorkoutPreset(name: "Speed 1-1 (HIIT)",
                      sets: 4, repsPerSet: 15,
                      concDuration: 1.0, eccDuration: 1.0,
                      concBeats: 1, eccBeats: 1),
        WorkoutPreset(name: "Slow 3-3 (TUT)",
                      sets: 4, repsPerSet: 10,
                      concDuration: 3.0, eccDuration: 3.0,
                      concBeats: 3, eccBeats: 3)
    ]
}

