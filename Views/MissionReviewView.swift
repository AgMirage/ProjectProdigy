//
//  MissionReviewView.swift
//  ProjectProdigy
//
//  Created by Kaia Quinn on 6/21/25.
//


import SwiftUI

/// A view that allows the user to reflect on their performance after a mission.
struct MissionReviewView: View {
    
    let mission: Mission
    
    // Using a binding to control the presentation of the sheet.
    @Binding var missionToReview: Mission?
    
    // State for the review questions.
    @State private var focusRating: Int = 3
    @State private var understandingRating: Int = 3
    @State private var challengeText: String = ""
    
    /// A closure that will be called when the user submits their review.
    var onReviewSubmit: (Int, Int, String) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Post-Mission Reflection for \"\(mission.topicName)\"")) {
                    // Focus Rating
                    VStack(alignment: .leading, spacing: 5) {
                        Text("How well did you focus?")
                        Picker("Focus", selection: $focusRating) {
                            ForEach(1...5, id: \.self) { Text("\($0) star\($0 > 1 ? "s" : "")").tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.vertical, 5)
                    
                    // Understanding Rating
                    VStack(alignment: .leading, spacing: 5) {
                        Text("How well did you understand the material?")
                        Picker("Understanding", selection: $understandingRating) {
                            ForEach(1...5, id: \.self) { Text("\($0) star\($0 > 1 ? "s" : "")").tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.vertical, 5)
                    
                    // Open-ended feedback
                    VStack(alignment: .leading, spacing: 5) {
                        Text("What was the most challenging part? (Optional)")
                        TextEditor(text: $challengeText)
                            .frame(height: 100)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                    }
                    .padding(.vertical, 5)
                }
                
                Section {
                    Button("Submit Review") {
                        // Call the completion handler and dismiss the view.
                        onReviewSubmit(focusRating, understandingRating, challengeText)
                        missionToReview = nil
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Mission Review")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        missionToReview = nil
                    }
                }
            }
        }
    }
}
