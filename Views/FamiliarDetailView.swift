//
//  FamiliarDetailView.swift
//  ProjectProdigy
//
//  Created by Kaia Quinn on 7/1/25.
//

import SwiftUI

struct FamiliarDetailView: View {
 @EnvironmentObject var mainViewModel: MainViewModel
 @State var familiar: Familiar
 
 // The currently selected appearance (defaults to the active one)
 @State private var selectedAppearanceStage: Int
 
 init(familiar: Familiar) {
 _familiar = State(initialValue: familiar)
 _selectedAppearanceStage = State(initialValue: familiar.level)
 }
 
 // Define a simple grid layout for skins
 private let columns: [GridItem] = [
 GridItem(.flexible()),
 GridItem(.flexible()),
 GridItem(.flexible())
 ]
 
 var body: some View {
 Form {
 Section(header: Text("Appearance")) {
 VStack {
 // --- EVOLUTION STAGE PREVIEW ---
 Image(familiar.imageNamePrefix + "_stage_\(selectedAppearanceStage)")
 .resizable()
 .scaledToFit()
 .frame(height: 150)
 
 // --- EVOLUTION STAGE PICKER ---
 HStack {
 ForEach(1...4, id: \.self) { stage in
 ZStack {
 if familiar.level >= stage {
 // Unlocked Stage
 Image(familiar.imageNamePrefix + "_stage_\(stage)")
 .resizable().scaledToFit().frame(width: 50, height: 50)
 .padding(5)
 .background(selectedAppearanceStage == stage ? Color.blue.opacity(0.3) : Color.clear)
 .cornerRadius(8)
 .onTapGesture {
 selectedAppearanceStage = stage
 }
 } else {
 // Locked Stage
 Image(systemName: "questionmark.diamond.fill")
 .font(.largeTitle)
 .foregroundColor(.secondary.opacity(0.5))
 .frame(width: 50, height: 50)
 .padding(5)
 .background(Color.secondary.opacity(0.1))
 .cornerRadius(8)
 }
 }
 }
 }
 .frame(maxWidth: .infinity)
 }
 .padding(.vertical)
 }
 
 // --- XP PROGRESS ---
 Section(header: Text("Level & Progress")) {
 VStack(alignment: .leading, spacing: 5) {
 Text("Level \(familiar.level)")
 .font(.headline)
 ProgressView(value: familiar.xp, total: 1000) // Assuming 1000 XP per level for now
 Text("\(Int(familiar.xp)) / 1000 XP")
 .font(.caption)
 .foregroundColor(.secondary)
 }
 .padding(.vertical)
 }
 
 // --- SKINS CUSTOMIZATION ---
 Section(header: Text("Customize")) {
 let skins = mainViewModel.player.unlockedFamiliarSkins.first(where: { $0.key == familiar.name })?.value ?? []
 
 if skins.isEmpty {
 Text("No skins unlocked for this familiar yet. Find them in the Fountain of Knowledge!")
 .font(.caption)
 .foregroundColor(.secondary)
 .padding()
 } else {
 LazyVGrid(columns: columns, spacing: 15) {
 ForEach(skins, id: \.self) { skinName in
 Button(action: {
 // Logic to apply the skin would go here.
 // For now, it's just a placeholder.
 print("Applied skin: \(skinName)")
 }) {
 Image(skinName)
 .resizable()
 .scaledToFit()
 .frame(width: 60, height: 60)
 .cornerRadius(8)
 }
 }
 }
 }
 }
 }
 .padding() // ADDED PADDING HERE
 .navigationTitle(familiar.name)
 }
}

struct FamiliarDetailView_Previews: PreviewProvider {
 static var previews: some View {
 let player = Player(username: "Preview")
 let mainVM = MainViewModel(player: player)
 mainVM.player.unlockedFamiliarSkins["Codex"] = ["skin_codex_magma"]
 
 // Ensure the familiar has a higher level for previewing stages
 var previewFamiliar = mainVM.player.activeFamiliar
 previewFamiliar.level = 3
 
 return NavigationStack {
 FamiliarDetailView(familiar: previewFamiliar)
 .environmentObject(mainVM)
 }
 }
}
