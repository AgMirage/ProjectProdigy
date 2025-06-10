import SwiftUI

struct CharacterCreationView: View {
    
    @StateObject private var viewModel = CharacterCreationViewModel()
    var onCharacterCreated: (Player) -> Void
    @State private var showingAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    profileSection
                    academicsSection
                    hobbiesSection
                    skillsSection
                    createButtonSection
                }
                .padding()
            }
            .navigationTitle("Create Your Prodigy")
            .alert("Username Required", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please enter a username to create your character.")
            }
        }
    }
    
    // MARK: - View Sections
    
    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Profile")
                .font(.headline)
                .foregroundColor(.secondary)
            
            TextField("Enter Username", text: $viewModel.username)
                .textFieldStyle(.roundedBorder)

            Text("Choose Avatar").foregroundColor(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    // The 'id' now uses the 'imageName' because Avatar is already Hashable.
                    ForEach(viewModel.availableAvatars, id: \.imageName) { avatar in
                        Image(avatar.imageName)
                            .resizable().scaledToFit().frame(width: 80, height: 80).clipShape(Circle()).padding(4)
                            .overlay(Circle().stroke(Color.blue.opacity(viewModel.selectedAvatar?.imageName == avatar.imageName ? 1.0 : 0.0), lineWidth: 4))
                            .onTapGesture { viewModel.selectedAvatar = avatar }
                    }
                }.padding(.vertical, 5)
            }
        }
    }
    
    private var academicsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Academic & Lifestyle Background")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Picker("Current Grade Level", selection: $viewModel.gradeLevel) {
                Text("Select Grade Level...").tag(nil as GradeLevel?)
                ForEach(GradeLevel.allCases) { Text($0.rawValue).tag($0 as GradeLevel?) }
            }
            .pickerStyle(.menu)

            Picker("Average Study Hours", selection: $viewModel.studyHours) {
                Text("Select Study Hours...").tag(nil as StudyHours?)
                ForEach(StudyHours.allCases) { Text($0.rawValue).tag($0 as StudyHours?) }
            }
            .pickerStyle(.menu)

            TextField("Approximate IQ (Optional)", text: $viewModel.iqInput)
                .textFieldStyle(.roundedBorder)
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif
        }
    }
    
    private var hobbiesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Hobbies (Select multiple)")
                .font(.headline)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(Hobby.allCases) { hobby in
                    Button(action: { viewModel.toggleHobbySelection(hobby) }) {
                        Text(hobby.rawValue.capitalized).font(.caption).padding(8).frame(maxWidth: .infinity)
                            .background(viewModel.selectedHobbies.contains(hobby) ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(viewModel.selectedHobbies.contains(hobby) ? .white : .primary)
                            .cornerRadius(8)
                    }.buttonStyle(.plain)
                }
            }
        }
    }
    
    private var skillsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Known Skills (Select branches you have completed)")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ForEach(viewModel.allSubjects) { subject in
                VStack(alignment: .leading) {
                    Text(subject.name).font(.headline).padding(.top, 10)
                    ForEach(subject.branches) { branch in
                        Toggle(isOn: Binding(
                            get: { viewModel.selectedInitialBranches[subject.name]?.contains(branch.name) ?? false },
                            set: { _ in viewModel.toggleBranchSelection(subjectName: subject.name, branchName: branch.name) }
                        )) {
                            HStack {
                                Text(branch.name)
                                Text("(\(branch.level.rawValue))").font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var createButtonSection: some View {
        Button(action: createCharacter) {
            Text("Create Character")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .buttonStyle(.borderedProminent)
        .tint(.blue)
        .disabled(viewModel.gradeLevel == nil || viewModel.studyHours == nil)
        .padding(.top)
    }
    
    // MARK: - Functions
    
    private func createCharacter() {
        if viewModel.username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showingAlert = true
        } else {
            onCharacterCreated(viewModel.createPlayer())
        }
    }
}


// MARK: - Previews & Helper Extensions

struct CharacterCreationView_Previews: PreviewProvider {
    static var previews: some View {
        CharacterCreationView(onCharacterCreated: { _ in })
    }
}

extension String {
    func fromCamelCaseToSpacedTitle() -> String {
        guard !self.isEmpty else { return "" }
        var result = ""
        for character in self {
            if character.isUppercase { result.append(" ") }
            result.append(character)
        }
        return result.prefix(1).capitalized + result.dropFirst()
    }
}
