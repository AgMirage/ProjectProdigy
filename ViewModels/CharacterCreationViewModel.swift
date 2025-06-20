import Foundation
import SwiftUI

// MARK: - Form Data Enums
enum GradeLevel: String, CaseIterable, Identifiable {
    case highSchoolFreshman = "High School Freshman", highSchoolSophomore = "High School Sophomore", highSchoolJunior = "High School Junior", highSchoolSenior = "High School Senior", collegeFreshman = "College Freshman", collegeSophomore = "College Sophomore", collegeJunior = "College Junior", collegeSenior = "College Senior", collegeGraduate = "College Graduate Student", postGraduate = "Post-Graduate/Professional"
    var id: Self { self }

    var isCollegeLevel: Bool {
        switch self {
        case .collegeFreshman, .collegeSophomore, .collegeJunior, .collegeSenior, .collegeGraduate, .postGraduate:
            return true
        default:
            return false
        }
    }
}
enum StudyHours: String, CaseIterable, Identifiable {
    case hours0_5 = "0-5 hours/week", hours6_10 = "6-10 hours/week", hours11_15 = "11-15 hours/week", hours16_20 = "16-20 hours/week", hours20plus = "20+ hours/week"
    var id: Self { self }
}
enum Hobby: String, CaseIterable, Identifiable {
    case reading, gaming, sports, art, music, coding, volunteering, outdoors
    var id: Self { self }
}

// MARK: - Character Creation ViewModel
@MainActor
class CharacterCreationViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var username: String = ""
    @Published var availableAvatars: [Avatar] = []
    @Published var selectedAvatar: Avatar?
    
    @Published var gradeLevel: GradeLevel? {
        didSet {
            handleGradeLevelChange()
        }
    }
    @Published var studyHours: StudyHours?
    
    @Published var selectedHobbies = Set<Hobby>()
    
    let allSubjects: [Subject] = KnowledgeTreeFactory.createFullTree()
    @Published var selectedInitialBranches: [String: Set<String>] = [:]
    
    @Published var iqInput: String = ""

    init() { loadDefaultAvatars() }
    
    private func loadDefaultAvatars() {
        let tempPlayer = Player(username: "temp")
        self.availableAvatars = tempPlayer.unlockedAvatars
        self.selectedAvatar = self.availableAvatars.first
    }
    
    func toggleHobbySelection(_ hobby: Hobby) {
        if selectedHobbies.contains(hobby) { selectedHobbies.remove(hobby) }
        else { selectedHobbies.insert(hobby) }
    }
    
    func toggleBranchSelection(subjectName: String, branchName: String) {
        if selectedInitialBranches[subjectName]?.contains(branchName) == true {
            // Deselecting
            selectedInitialBranches[subjectName]?.remove(branchName)
            // Note: Does not deselect dependents, user has to do it manually.
        } else {
            // Selecting
            if selectedInitialBranches[subjectName] == nil {
                selectedInitialBranches[subjectName] = []
            }
            selectedInitialBranches[subjectName]?.insert(branchName)
            selectPrerequisites(for: branchName)
        }
    }
    
    private func selectPrerequisites(for branchName: String) {
        // --- EDITED LINE: Replaced 'subject' with '_' ---
        guard let (_, branch) = findSubjectAndBranch(for: branchName) else { return }
        
        for prereqName in branch.prerequisiteBranchNames {
            if let (prereqSubject, _) = findSubjectAndBranch(for: prereqName) {
                if selectedInitialBranches[prereqSubject.name] == nil {
                    selectedInitialBranches[prereqSubject.name] = []
                }
                if selectedInitialBranches[prereqSubject.name]?.contains(prereqName) == false {
                    selectedInitialBranches[prereqSubject.name]?.insert(prereqName)
                    selectPrerequisites(for: prereqName) // Recursive call
                }
            }
        }
    }
    
    private func findSubjectAndBranch(for branchName: String) -> (Subject, KnowledgeBranch)? {
        for subject in allSubjects {
            if let branch = subject.branches.first(where: { $0.name == branchName }) {
                return (subject, branch)
            }
        }
        return nil
    }

    private func handleGradeLevelChange() {
        guard let level = gradeLevel else { return }
        if level.isCollegeLevel {
            autoSelectFoundationalSkills()
        } else {
            // Clear selections if they go back to High School
            selectedInitialBranches.removeAll()
        }
    }
    
    private func autoSelectFoundationalSkills() {
        let foundationalSkills: [String: [String]] = [
            "Mathematics": ["Algebra I", "Geometry", "Pre-Calculus"],
            "Chemistry": ["High School Chemistry"],
            "Biology": ["High School Biology"],
            "History": ["High School History"]
        ]
        
        for (subjectName, branchNames) in foundationalSkills {
            if selectedInitialBranches[subjectName] == nil {
                selectedInitialBranches[subjectName] = Set<String>()
            }
            for branchName in branchNames {
                selectedInitialBranches[subjectName]?.insert(branchName)
            }
        }
    }
    
    func createPlayer() -> Player {
        var newPlayer = Player(username: self.username)
        if let selectedAvatar { newPlayer.currentAvatar = selectedAvatar }
        
        newPlayer.initialSkills = self.selectedInitialBranches.mapValues { Array($0) }
        
        newPlayer.stats = calculateStartingStats()
        return newPlayer
    }
    
    private func calculateStartingStats() -> Stats {
        var s = Stats.default
        
        if let iq = Int(iqInput), iq > 0 { let b = (iq-100)/5; s.intelligence+=b; s.wisdom+=b/2 }
        let gradeBonus = (GradeLevel.allCases.firstIndex(of: gradeLevel ?? .highSchoolFreshman) ?? 0) / 2
        s.intelligence+=gradeBonus; s.wisdom+=gradeBonus
        let studyBonus = StudyHours.allCases.firstIndex(of: studyHours ?? .hours0_5) ?? 0
        s.stamina+=studyBonus; s.focus+=studyBonus
        
        for h in selectedHobbies { switch h { case .reading:s.wisdom+=2; case .gaming:s.focus+=1;s.dexterity+=1; case .sports,.outdoors:s.stamina+=2; case .art,.music:s.creativity+=2; case .coding:s.intelligence+=1;s.dexterity+=1; case .volunteering:s.wisdom+=1 } }
        
        for (_, branchNames) in selectedInitialBranches {
            for branchName in branchNames {
                if branchName.lowercased().contains("calculus") { s.intelligence += 2; s.wisdom += 1 }
                else if branchName.lowercased().contains("algebra") { s.intelligence += 1 }
                else if branchName.lowercased().contains("organic") { s.intelligence += 2; s.creativity += 1 }
                else if branchName.lowercased().contains("history") { s.wisdom += 1 }
                else if branchName.lowercased().contains("programming") { s.intelligence += 1; s.dexterity += 1 }
            }
        }
        
        s.intelligence=max(1,s.intelligence);s.wisdom=max(1,s.wisdom);s.dexterity=max(1,s.dexterity);s.creativity=max(1,s.creativity);s.stamina=max(1,s.stamina);s.focus=max(1,s.focus)
        return s
    }
}
