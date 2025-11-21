//
//  WorkoutView.swift
//  WorkoutCounter
//
//  Created by Nohemy Pereira-Veiga Moyar on 18/6/25.
//

// [WorkoutView.swift - UI Layout]
import SwiftUI

struct WorkoutView: View {
    @StateObject private var viewModel = WorkoutViewModel()

    var body: some View {
        VStack(spacing: 30) {
            // INPUTS
            Stepper("Number of Sets: \(viewModel.sets)", value: $viewModel.sets, in: 1...10)
            Stepper("Number of Reps: \(viewModel.repsPerSet)", value: $viewModel.repsPerSet, in: 1...100)
            //Stepper("Time Interval: \(Int(viewModel.interval))s", value: $viewModel.interval, in: 1...10)
            // [WorkoutView.swift - Time Interval Input]
            Stepper(
                value: $viewModel.interval,
                in: 0.1...10.0,
                step: 0.1
            ) {
                Text(String(format: "Time Interval: %.1fs", viewModel.interval))
            }


            // COUNTER DISPLAY
            Text("Set \(viewModel.currentSet) / \(viewModel.sets)")
                .font(.title)
            Text("Rep \(viewModel.currentRep) / \(viewModel.repsPerSet)")
                .font(.largeTitle)
                .bold()

            // CONTROLS
            HStack(spacing: 20) {
                Button("▶️ Play") {
                    viewModel.start()
                }
                .buttonStyle(.borderedProminent)

                Button("⏸ Pause") {
                    viewModel.pause()
                }
                .buttonStyle(.bordered)

                Button("🔄 Reset") {
                    viewModel.reset()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}
