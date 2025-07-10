import Foundation

// MARK: - Knowledge Tree Models
enum SubjectCategory: String, Codable, Hashable {
    case stem = "STEM"
    case humanities = "Humanities"
    case language = "Language"
    case socialScience = "Social Science"
}

enum BranchLevel: String, Codable, Hashable, CaseIterable {
    case highSchool = "High School"
    case college = "College"
}

/// Represents a single, unlockable topic within a branch.
struct KnowledgeTopic: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var xpRequired: Double // XP required *within the parent branch*
    var missionsRequired: Int // Missions required *within the parent branch*
    var timeRequired: TimeInterval // Time required *within the parent branch*
    var isUnlocked: Bool

    init(id: UUID = UUID(), name: String, description: String, xpRequired: Double, missionsRequired: Int, timeRequired: TimeInterval, isUnlocked: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.xpRequired = xpRequired
        self.missionsRequired = missionsRequired
        self.timeRequired = timeRequired
        self.isUnlocked = isUnlocked
    }
}

/// Represents a main branch or course unit within a subject.
struct KnowledgeBranch: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var level: BranchLevel
    
    // --- Prerequisite Properties ---
    /// Names of branches that must be completed before this one can be unlocked.
    var prerequisiteBranchNames: [String]
    /// The percentage of topics that must be unlocked in each prerequisite branch.
    var prerequisiteCompletion: Double
    /// The total XP required from all prerequisite branches combined.
    var totalXpRequired: Double
    /// The total missions required from all prerequisite branches combined.
    var totalMissionsRequired: Int
    /// The total time required from all prerequisite branches combined.
    var totalTimeRequired: TimeInterval
    /// Optional stat requirements (e.g., ["Intelligence": 15]).
    var requiredStats: [String: Int]?
    
    var topics: [KnowledgeTopic]
    var isUnlocked: Bool
    var isAutoUnlocked: Bool = false
    
    // --- Player Progress Tracking ---
    var currentXP: Double
    var totalTimeSpent: TimeInterval
    var missionsCompleted: Int

    // --- NEW: Remastering ---
    /// A count of how many times this branch has been remastered.
    var remasterCount: Int

    var isMastered: Bool {
        guard isUnlocked else { return false }
        return !topics.isEmpty && topics.allSatisfy { $0.isUnlocked }
    }
    
    // --- REMOVED: This property was inaccurate and has been replaced by a new calculation in the ViewModel. ---
    // var progress: Double { ... }

    init(id: UUID = UUID(), name: String, description: String, level: BranchLevel,
         prerequisiteBranchNames: [String] = [], prerequisiteCompletion: Double = 0.0,
         totalXpRequired: Double = 0.0, totalMissionsRequired: Int = 0, totalTimeRequired: TimeInterval = 0.0,
         requiredStats: [String : Int]? = nil, topics: [KnowledgeTopic],
         isUnlocked: Bool = false, isAutoUnlocked: Bool = false, currentXP: Double = 0.0, totalTimeSpent: TimeInterval = 0.0, missionsCompleted: Int = 0,
         remasterCount: Int = 0) {
        
        self.id = id
        self.name = name
        self.description = description
        self.level = level
        self.prerequisiteBranchNames = prerequisiteBranchNames
        self.prerequisiteCompletion = prerequisiteCompletion
        self.totalXpRequired = totalXpRequired
        self.totalMissionsRequired = totalMissionsRequired
        self.totalTimeRequired = totalTimeRequired
        self.requiredStats = requiredStats
        self.topics = topics
        self.isUnlocked = isUnlocked
        self.isAutoUnlocked = isAutoUnlocked
        self.currentXP = currentXP
        self.totalTimeSpent = totalTimeSpent
        self.missionsCompleted = missionsCompleted
        self.remasterCount = remasterCount
    }
}


/// Represents a major subject area.
struct Subject: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var iconName: String
    var category: SubjectCategory
    var branches: [KnowledgeBranch]

    init(id: UUID = UUID(), name: String, iconName: String, category: SubjectCategory, branches: [KnowledgeBranch]) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.category = category
        self.branches = branches
    }
}

// MARK: - Knowledge Tree Factory
/// A static factory to generate the complete knowledge tree with all specified unlock requirements.
struct KnowledgeTreeFactory {
    
    static func createFullTree() -> [Subject] {
        return [
            createMathSubject(),
            createChemistrySubject(),
            createBiologySubject(),
            createPhysicsSubject(),
            createHistorySubject(),
            createComputerScienceSubject(),
            createLanguageSubject(),
            createEconomicsSubject(),
            createPhilosophySubject(),
            createPsychologySubject()
        ]
    }
    
    // MARK: - Subject Creation Methods
    
    private static func createMathSubject() -> Subject {
        return Subject(name: "Mathematics", iconName: "function", category: .stem, branches: [
            // --- High School Math ---
            KnowledgeBranch(name: "Algebra I", description: "Core concepts of algebraic manipulation, equations, and functions.", level: .highSchool, topics: [
                KnowledgeTopic(name: "Variables & Expressions", description: "...", xpRequired: 100, missionsRequired: 2, timeRequired: 1800),
                KnowledgeTopic(name: "Equations & Inequalities", description: "...", xpRequired: 150, missionsRequired: 3, timeRequired: 2700),
                KnowledgeTopic(name: "Linear Functions", description: "...", xpRequired: 200, missionsRequired: 4, timeRequired: 3600)
            ]),
            KnowledgeBranch(name: "Geometry", description: "The study of shapes, angles, and space.", level: .highSchool, prerequisiteBranchNames: ["Algebra I"], prerequisiteCompletion: 0.75, totalXpRequired: 800, totalMissionsRequired: 10, totalTimeRequired: 18000, topics: [
                KnowledgeTopic(name: "Basic Shapes & Angles", description: "...", xpRequired: 250, missionsRequired: 4, timeRequired: 4500),
                KnowledgeTopic(name: "Proofs & Theorems (Intro)", description: "...", xpRequired: 300, missionsRequired: 5, timeRequired: 5400),
                KnowledgeTopic(name: "Area & Volume", description: "...", xpRequired: 350, missionsRequired: 6, timeRequired: 6300)
            ]),
            KnowledgeBranch(name: "Pre-Calculus", description: "Advanced functions, trigonometry, and series.", level: .highSchool, prerequisiteBranchNames: ["Geometry"], prerequisiteCompletion: 0.75, totalXpRequired: 1200, totalMissionsRequired: 15, totalTimeRequired: 28800, topics: [
                KnowledgeTopic(name: "Functions & Graphs", description: "...", xpRequired: 400, missionsRequired: 6, timeRequired: 7200),
                KnowledgeTopic(name: "Trigonometry", description: "...", xpRequired: 450, missionsRequired: 7, timeRequired: 8100),
                KnowledgeTopic(name: "Sequences & Series", description: "...", xpRequired: 500, missionsRequired: 8, timeRequired: 9000)
            ]),

            // --- College Math ---
            KnowledgeBranch(name: "Calculus I", description: "Introduction to limits, derivatives, and integrals.", level: .college, prerequisiteBranchNames: ["Pre-Calculus"], prerequisiteCompletion: 0.80, totalXpRequired: 3000, totalMissionsRequired: 30, totalTimeRequired: 54000, topics: [
                KnowledgeTopic(name: "Limits & Continuity", description: "...", xpRequired: 400, missionsRequired: 5, timeRequired: 7200),
                KnowledgeTopic(name: "Basic Derivative Rules", description: "...", xpRequired: 600, missionsRequired: 8, timeRequired: 10800),
                KnowledgeTopic(name: "Chain Rule & Implicit Differentiation", description: "...", xpRequired: 800, missionsRequired: 10, timeRequired: 14400),
                KnowledgeTopic(name: "Optimization & Related Rates", description: "...", xpRequired: 1000, missionsRequired: 12, timeRequired: 18000),
                KnowledgeTopic(name: "Antiderivatives & Basic Integrals", description: "...", xpRequired: 1200, missionsRequired: 15, timeRequired: 21600)
            ]),
            KnowledgeBranch(name: "Calculus II", description: "Advanced integration techniques and infinite series.", level: .college, prerequisiteBranchNames: ["Calculus I"], prerequisiteCompletion: 0.90, totalXpRequired: 4000, totalMissionsRequired: 35, totalTimeRequired: 72000, topics: [
                KnowledgeTopic(name: "Integration Techniques", description: "...", xpRequired: 1000, missionsRequired: 12, timeRequired: 18000),
                KnowledgeTopic(name: "Sequences & Series (Advanced)", description: "...", xpRequired: 1200, missionsRequired: 15, timeRequired: 21600)
            ]),
            KnowledgeBranch(name: "Linear Algebra", description: "The study of vectors, matrices, and linear transformations.", level: .college, prerequisiteBranchNames: ["Calculus I"], prerequisiteCompletion: 0.80, totalXpRequired: 4500, totalMissionsRequired: 40, totalTimeRequired: 79200, topics: [
                KnowledgeTopic(name: "Vectors & Matrices", description: "...", xpRequired: 1100, missionsRequired: 13, timeRequired: 19800),
                KnowledgeTopic(name: "Eigenvalues & Eigenvectors", description: "...", xpRequired: 1300, missionsRequired: 16, timeRequired: 23400)
            ]),
            KnowledgeBranch(name: "Differential Equations", description: "Modeling change with equations involving derivatives.", level: .college, prerequisiteBranchNames: ["Calculus II", "Linear Algebra"], prerequisiteCompletion: 0.90, totalXpRequired: 5000, totalMissionsRequired: 45, totalTimeRequired: 90000, topics: [
                KnowledgeTopic(name: "First Order ODEs", description: "...", xpRequired: 1200, missionsRequired: 15, timeRequired: 21600),
                KnowledgeTopic(name: "Higher Order & Systems", description: "...", xpRequired: 1400, missionsRequired: 18, timeRequired: 25200)
            ]),
            KnowledgeBranch(name: "Real Analysis I", description: "The rigorous, theoretical foundation of calculus.", level: .college, prerequisiteBranchNames: ["Calculus II"], prerequisiteCompletion: 0.90, totalXpRequired: 8000, totalMissionsRequired: 60, totalTimeRequired: 144000, requiredStats: ["Intelligence": 18], topics: [
                KnowledgeTopic(name: "Metric Spaces & Topology", description: "...", xpRequired: 1500, missionsRequired: 20, timeRequired: 28800),
                KnowledgeTopic(name: "Continuity & Differentiation in Rn", description: "...", xpRequired: 1800, missionsRequired: 25, timeRequired: 32400)
            ])
        ])
    }
    
    private static func createChemistrySubject() -> Subject {
        return Subject(name: "Chemistry", iconName: "testtube.2", category: .stem, branches: [
            // --- High School Chemistry ---
            KnowledgeBranch(name: "High School Chemistry", description: "The building blocks of matter and their interactions.", level: .highSchool, topics: [
                KnowledgeTopic(name: "Basic Concepts & Matter", description: "...", xpRequired: 120, missionsRequired: 2, timeRequired: 2160),
                KnowledgeTopic(name: "Atomic Structure & Periodicity", description: "...", xpRequired: 180, missionsRequired: 3, timeRequired: 3240),
                KnowledgeTopic(name: "Chemical Bonding", description: "...", xpRequired: 250, missionsRequired: 4, timeRequired: 4500),
                KnowledgeTopic(name: "Stoichiometry & Reactions", description: "...", xpRequired: 300, missionsRequired: 5, timeRequired: 5400),
                KnowledgeTopic(name: "Acids & Bases (Intro)", description: "...", xpRequired: 350, missionsRequired: 6, timeRequired: 6300)
            ]),

            // --- College Chemistry ---
            KnowledgeBranch(name: "General Chemistry I", description: "Atomic structure, bonding, and states of matter.", level: .college, prerequisiteBranchNames: ["High School Chemistry", "Algebra I"], prerequisiteCompletion: 0.80, totalXpRequired: 3500, totalMissionsRequired: 30, totalTimeRequired: 64800, topics: [
                KnowledgeTopic(name: "Quantum Theory & Atomic Orbitals", description: "...", xpRequired: 500, missionsRequired: 6, timeRequired: 9000),
                KnowledgeTopic(name: "Molecular Geometry & Hybridization", description: "...", xpRequired: 700, missionsRequired: 9, timeRequired: 12600),
                KnowledgeTopic(name: "States of Matter & Intermolecular Forces", description: "...", xpRequired: 900, missionsRequired: 12, timeRequired: 16200)
            ]),
            KnowledgeBranch(name: "General Chemistry II", description: "Reactions, thermodynamics, and equilibrium.", level: .college, prerequisiteBranchNames: ["General Chemistry I"], prerequisiteCompletion: 0.90, totalXpRequired: 4000, totalMissionsRequired: 35, totalTimeRequired: 72000, topics: [
                KnowledgeTopic(name: "Thermochemistry & Thermodynamics (Intro)", description: "...", xpRequired: 1000, missionsRequired: 12, timeRequired: 18000),
                KnowledgeTopic(name: "Chemical Kinetics", description: "...", xpRequired: 1200, missionsRequired: 15, timeRequired: 21600),
                KnowledgeTopic(name: "Equilibrium & Acids/Bases (Advanced)", description: "...", xpRequired: 1400, missionsRequired: 18, timeRequired: 25200),
                KnowledgeTopic(name: "Electrochemistry", description: "...", xpRequired: 1600, missionsRequired: 20, timeRequired: 28800)
            ]),
            KnowledgeBranch(name: "Organic Chemistry I", description: "The study of carbon compounds, structure, and reactions.", level: .college, prerequisiteBranchNames: ["General Chemistry II"], prerequisiteCompletion: 0.90, totalXpRequired: 6000, totalMissionsRequired: 50, totalTimeRequired: 108000, topics: [
                KnowledgeTopic(name: "Nomenclature & Isomerism", description: "...", xpRequired: 1200, missionsRequired: 15, timeRequired: 21600),
                KnowledgeTopic(name: "Alkanes & Stereochemistry", description: "...", xpRequired: 1500, missionsRequired: 18, timeRequired: 27000),
                KnowledgeTopic(name: "Alkenes & Alkynes Reactions", description: "...", xpRequired: 1800, missionsRequired: 22, timeRequired: 32400),
                KnowledgeTopic(name: "Alkyl Halides & Substitution/Elimination Mechanisms", description: "...", xpRequired: 2000, missionsRequired: 25, timeRequired: 36000)
            ]),
             KnowledgeBranch(name: "Physical Chemistry I", description: "The application of physical principles to chemical systems.", level: .college, prerequisiteBranchNames: ["General Chemistry II", "Calculus II"], prerequisiteCompletion: 0.90, totalXpRequired: 7000, totalMissionsRequired: 55, totalTimeRequired: 126000, requiredStats: ["Intelligence": 15, "Wisdom": 12], topics: [
                KnowledgeTopic(name: "Laws of Thermodynamics", description: "...", xpRequired: 1500, missionsRequired: 20, timeRequired: 28800),
                KnowledgeTopic(name: "Chemical Potential & Phase Equilibria", description: "...", xpRequired: 1800, missionsRequired: 25, timeRequired: 32400)
            ]),
            KnowledgeBranch(name: "Analytical Chemistry", description: "The science of obtaining, processing, and communicating information about the composition and structure of matter.", level: .college, prerequisiteBranchNames: ["General Chemistry II", "Calculus I"], prerequisiteCompletion: 0.90, totalXpRequired: 6500, totalMissionsRequired: 50, totalTimeRequired: 115200, topics: [
                KnowledgeTopic(name: "Spectroscopy Techniques (UV-Vis, IR, NMR Intro)", description: "...", xpRequired: 1400, missionsRequired: 18, timeRequired: 25200)
            ])
        ])
    }

    private static func createBiologySubject() -> Subject {
        return Subject(name: "Biology", iconName: "leaf.fill", category: .stem, branches: [
            KnowledgeBranch(name: "High School Biology", description: "Foundations of life sciences.", level: .highSchool, topics: [
                KnowledgeTopic(name: "Cell Structure & Function", description: "...", xpRequired: 100, missionsRequired: 2, timeRequired: 1800),
                KnowledgeTopic(name: "Genetics (Mendelian)", description: "...", xpRequired: 150, missionsRequired: 3, timeRequired: 2700),
                KnowledgeTopic(name: "Evolution & Ecology (Intro)", description: "...", xpRequired: 200, missionsRequired: 4, timeRequired: 3600)
            ]),
            KnowledgeBranch(name: "General Biology I", description: "A deep dive into the molecular and cellular basis of life.", level: .college, prerequisiteBranchNames: ["High School Biology", "High School Chemistry"], prerequisiteCompletion: 0.80, totalXpRequired: 3000, totalMissionsRequired: 25, totalTimeRequired: 54000, topics: [
                KnowledgeTopic(name: "Macromolecules", description: "...", xpRequired: 400, missionsRequired: 5, timeRequired: 7200),
                KnowledgeTopic(name: "Metabolism & Respiration", description: "...", xpRequired: 600, missionsRequired: 8, timeRequired: 10800),
                KnowledgeTopic(name: "Photosynthesis", description: "...", xpRequired: 700, missionsRequired: 9, timeRequired: 12600)
            ]),
            KnowledgeBranch(name: "General Biology II", description: "Explores the diversity of life and ecological principles.", level: .college, prerequisiteBranchNames: ["General Biology I"], prerequisiteCompletion: 0.90, totalXpRequired: 3500, totalMissionsRequired: 30, totalTimeRequired: 61200, topics: [
                KnowledgeTopic(name: "Diversity of Life", description: "...", xpRequired: 900, missionsRequired: 10, timeRequired: 16200),
                KnowledgeTopic(name: "Ecosystem Dynamics", description: "...", xpRequired: 1100, missionsRequired: 13, timeRequired: 19800)
            ]),
            KnowledgeBranch(name: "Molecular Genetics", description: "The study of heredity and variation at the molecular level.", level: .college, prerequisiteBranchNames: ["General Biology I"], prerequisiteCompletion: 0.90, totalXpRequired: 4500, totalMissionsRequired: 40, totalTimeRequired: 79200, topics: [
                KnowledgeTopic(name: "DNA Replication & Repair", description: "...", xpRequired: 1200, missionsRequired: 15, timeRequired: 21600),
                KnowledgeTopic(name: "Gene Expression (Transcription & Translation)", description: "...", xpRequired: 1400, missionsRequired: 18, timeRequired: 25200)
            ]),
            KnowledgeBranch(name: "Biochemistry I", description: "The chemistry of life, focusing on proteins and enzymes.", level: .college, prerequisiteBranchNames: ["Organic Chemistry I", "General Biology I"], prerequisiteCompletion: 0.90, totalXpRequired: 5500, totalMissionsRequired: 45, totalTimeRequired: 100800, requiredStats: ["Intelligence": 15, "Wisdom": 12], topics: [
                KnowledgeTopic(name: "Amino Acids & Peptides", description: "...", xpRequired: 1500, missionsRequired: 20, timeRequired: 27000),
                KnowledgeTopic(name: "Enzymatic Catalysis", description: "...", xpRequired: 1800, missionsRequired: 25, timeRequired: 32400)
            ])
        ])
    }

    private static func createPhysicsSubject() -> Subject {
        return Subject(name: "Physics", iconName: "atom", category: .stem, branches: [
            KnowledgeBranch(name: "High School Physics", description: "Introduction to the laws of motion, energy, and electromagnetism.", level: .highSchool, topics: [
                KnowledgeTopic(name: "Motion & Forces (Newton's Laws)", description: "...", xpRequired: 100, missionsRequired: 2, timeRequired: 1800),
                KnowledgeTopic(name: "Work, Energy & Power", description: "...", xpRequired: 150, missionsRequired: 3, timeRequired: 2700),
                KnowledgeTopic(name: "Electricity & Magnetism (Intro)", description: "...", xpRequired: 200, missionsRequired: 4, timeRequired: 3600)
            ]),
            KnowledgeBranch(name: "Classical Mechanics", description: "The calculus-based study of motion and forces.", level: .college, prerequisiteBranchNames: ["High School Physics", "Calculus I"], prerequisiteCompletion: 0.80, totalXpRequired: 3500, totalMissionsRequired: 30, totalTimeRequired: 64800, topics: [
                KnowledgeTopic(name: "Kinematics & Dynamics", description: "...", xpRequired: 500, missionsRequired: 6, timeRequired: 9000),
                KnowledgeTopic(name: "Conservation Laws (Energy, Momentum)", description: "...", xpRequired: 700, missionsRequired: 9, timeRequired: 12600),
                KnowledgeTopic(name: "Rotational Motion", description: "...", xpRequired: 900, missionsRequired: 12, timeRequired: 16200)
            ]),
            KnowledgeBranch(name: "Electromagnetism", description: "The calculus-based study of electric and magnetic fields.", level: .college, prerequisiteBranchNames: ["Classical Mechanics", "Calculus II"], prerequisiteCompletion: 0.90, totalXpRequired: 4500, totalMissionsRequired: 40, totalTimeRequired: 79200, requiredStats: ["Intelligence": 15], topics: [
                KnowledgeTopic(name: "Electrostatics & Gauss's Law", description: "...", xpRequired: 1200, missionsRequired: 15, timeRequired: 21600),
                KnowledgeTopic(name: "Magnetism & Faraday's Law", description: "...", xpRequired: 1500, missionsRequired: 18, timeRequired: 27000),
                KnowledgeTopic(name: "Maxwell's Equations (Intro)", description: "...", xpRequired: 1800, missionsRequired: 22, timeRequired: 32400)
            ]),
            KnowledgeBranch(name: "Thermodynamics & Statistical Mechanics", description: "The physics of heat, work, and the behavior of large numbers of particles.", level: .college, prerequisiteBranchNames: ["Classical Mechanics", "Calculus II"], prerequisiteCompletion: 0.90, totalXpRequired: 5000, totalMissionsRequired: 45, totalTimeRequired: 90000, requiredStats: ["Wisdom": 12], topics: [
                KnowledgeTopic(name: "Heat & Work", description: "...", xpRequired: 1300, missionsRequired: 16, timeRequired: 23400)
            ])
        ])
    }

    private static func createHistorySubject() -> Subject {
        return Subject(name: "History", iconName: "building.columns.fill", category: .humanities, branches: [
             KnowledgeBranch(name: "High School History", description: "A survey of major global and national events.", level: .highSchool, topics: [
                KnowledgeTopic(name: "Ancient Civilizations", description: "...", xpRequired: 80, missionsRequired: 2, timeRequired: 1440),
                KnowledgeTopic(name: "Medieval & Early Modern History", description: "...", xpRequired: 120, missionsRequired: 3, timeRequired: 2160),
                KnowledgeTopic(name: "US History (Foundations)", description: "...", xpRequired: 150, missionsRequired: 3, timeRequired: 2700)
            ]),
            KnowledgeBranch(name: "World History I", description: "From pre-history to the early modern era.", level: .college, prerequisiteBranchNames: ["High School History"], prerequisiteCompletion: 0.80, totalXpRequired: 2000, totalMissionsRequired: 15, totalTimeRequired: 36000, topics: [
                KnowledgeTopic(name: "Rise of Civilizations", description: "...", xpRequired: 300, missionsRequired: 4, timeRequired: 5400),
                KnowledgeTopic(name: "Classical Empires (Greece, Rome, China)", description: "...", xpRequired: 400, missionsRequired: 6, timeRequired: 7200)
            ]),
            KnowledgeBranch(name: "World History II", description: "From 1500 CE to the present day.", level: .college, prerequisiteBranchNames: ["World History I"], prerequisiteCompletion: 0.90, totalXpRequired: 2500, totalMissionsRequired: 20, totalTimeRequired: 43200, topics: [
                KnowledgeTopic(name: "Age of Exploration & Renaissance", description: "...", xpRequired: 500, missionsRequired: 7, timeRequired: 9000),
                KnowledgeTopic(name: "Revolutions & Industrialization", description: "...", xpRequired: 600, missionsRequired: 9, timeRequired: 10800)
            ]),
            KnowledgeBranch(name: "American History", description: "From the post-Civil War era to modern times.", level: .college, prerequisiteBranchNames: ["High School History"], prerequisiteCompletion: 0.80, totalXpRequired: 2800, totalMissionsRequired: 22, totalTimeRequired: 50400, topics: [
                KnowledgeTopic(name: "Reconstruction to WWI", description: "...", xpRequired: 700, missionsRequired: 10, timeRequired: 12600),
                KnowledgeTopic(name: "The Great Depression & WWII", description: "...", xpRequired: 800, missionsRequired: 12, timeRequired: 14400)
            ])
        ])
    }

    private static func createComputerScienceSubject() -> Subject {
        return Subject(name: "Computer Science", iconName: "terminal.fill", category: .stem, branches: [
            KnowledgeBranch(name: "High School Computer Science", description: "Fundamentals of programming and web development.", level: .highSchool, topics: [
                KnowledgeTopic(name: "Computational Thinking Intro", description: "...", xpRequired: 100, missionsRequired: 2, timeRequired: 1800),
                KnowledgeTopic(name: "Basic Programming Concepts", description: "...", xpRequired: 150, missionsRequired: 3, timeRequired: 2700),
                KnowledgeTopic(name: "Web Fundamentals (HTML/CSS)", description: "...", xpRequired: 200, missionsRequired: 4, timeRequired: 3600)
            ]),
            KnowledgeBranch(name: "Introduction to Programming", description: "Core concepts of software development.", level: .college, prerequisiteBranchNames: ["High School Computer Science", "Algebra I"], prerequisiteCompletion: 0.80, totalXpRequired: 3000, totalMissionsRequired: 25, totalTimeRequired: 54000, topics: [
                KnowledgeTopic(name: "Variables, Data Types & Control Flow", description: "...", xpRequired: 400, missionsRequired: 5, timeRequired: 7200),
                KnowledgeTopic(name: "Functions & Object-Oriented Principles (Intro)", description: "...", xpRequired: 600, missionsRequired: 8, timeRequired: 10800)
            ]),
            KnowledgeBranch(name: "Data Structures & Algorithms I", description: "Organizing data and creating efficient procedures.", level: .college, prerequisiteBranchNames: ["Introduction to Programming"], prerequisiteCompletion: 0.90, totalXpRequired: 4500, totalMissionsRequired: 40, totalTimeRequired: 79200, topics: [
                KnowledgeTopic(name: "Arrays, Lists & Stacks/Queues", description: "...", xpRequired: 900, missionsRequired: 10, timeRequired: 16200),
                KnowledgeTopic(name: "Trees & Graphs (Intro)", description: "...", xpRequired: 1200, missionsRequired: 15, timeRequired: 21600),
                KnowledgeTopic(name: "Sorting & Searching Algorithms", description: "...", xpRequired: 1500, missionsRequired: 18, timeRequired: 27000)
            ]),
            KnowledgeBranch(name: "Discrete Mathematics", description: "The mathematical foundations of computer science.", level: .college, prerequisiteBranchNames: ["Algebra I", "Introduction to Programming"], prerequisiteCompletion: 0.80, totalXpRequired: 3500, totalMissionsRequired: 30, totalTimeRequired: 54000, topics: [
                KnowledgeTopic(name: "Logic & Proof Techniques", description: "...", xpRequired: 700, missionsRequired: 9, timeRequired: 12600),
                KnowledgeTopic(name: "Combinatorics & Probability (for CS)", description: "...", xpRequired: 900, missionsRequired: 12, timeRequired: 16200)
            ]),
            KnowledgeBranch(name: "Database Management Systems", description: "Designing and querying relational databases.", level: .college, prerequisiteBranchNames: ["Introduction to Programming"], prerequisiteCompletion: 0.90, totalXpRequired: 4000, totalMissionsRequired: 35, totalTimeRequired: 72000, topics: [
                KnowledgeTopic(name: "Relational Model & SQL", description: "...", xpRequired: 1000, missionsRequired: 12, timeRequired: 18000),
                KnowledgeTopic(name: "Database Design & Normalization", description: "...", xpRequired: 1300, missionsRequired: 16, timeRequired: 23400)
            ]),
            KnowledgeBranch(name: "Operating Systems", description: "The software that manages computer hardware and software resources.", level: .college, prerequisiteBranchNames: ["Data Structures & Algorithms I"], prerequisiteCompletion: 0.90, totalXpRequired: 5500, totalMissionsRequired: 45, totalTimeRequired: 100800, requiredStats: ["Intelligence": 15], topics: [
                KnowledgeTopic(name: "Process Management", description: "...", xpRequired: 1400, missionsRequired: 18, timeRequired: 25200),
                KnowledgeTopic(name: "Memory Management", description: "...", xpRequired: 1700, missionsRequired: 22, timeRequired: 30600)
            ])
        ])
    }
    
    private static func createLanguageSubject() -> Subject {
        return Subject(name: "Language (Spanish)", iconName: "character.book.closed.fill", category: .language, branches: [
            KnowledgeBranch(name: "Spanish I", description: "Beginner grammar and vocabulary.", level: .highSchool, topics: [
                KnowledgeTopic(name: "Greetings & Basic Phrases", description: "...", xpRequired: 80, missionsRequired: 2, timeRequired: 1440)
            ]),
            KnowledgeBranch(name: "Spanish II", description: "Intermediate grammar and conversation.", level: .highSchool, prerequisiteBranchNames: ["Spanish I"], prerequisiteCompletion: 1.0, totalXpRequired: 150, totalMissionsRequired: 3, totalTimeRequired: 2700, topics: [
                KnowledgeTopic(name: "Present & Past Tenses", description: "...", xpRequired: 150, missionsRequired: 3, timeRequired: 2700)
            ]),
            KnowledgeBranch(name: "Spanish III", description: "Advanced grammar and cultural studies.", level: .college, prerequisiteBranchNames: ["Spanish II"], prerequisiteCompletion: 0.80, totalXpRequired: 2500, totalMissionsRequired: 20, totalTimeRequired: 43200, topics: [
                KnowledgeTopic(name: "Complex Tenses & Moods (Subjunctive)", description: "...", xpRequired: 400, missionsRequired: 5, timeRequired: 7200),
                KnowledgeTopic(name: "Cultural Contexts (LatAm & Spain)", description: "...", xpRequired: 550, missionsRequired: 7, timeRequired: 9900)
            ]),
            KnowledgeBranch(name: "Spanish IV", description: "Advanced reading and writing in Spanish.", level: .college, prerequisiteBranchNames: ["Spanish III"], prerequisiteCompletion: 0.90, totalXpRequired: 3000, totalMissionsRequired: 25, totalTimeRequired: 54000, topics: [
                KnowledgeTopic(name: "Literary Analysis (Short Stories/Poetry)", description: "...", xpRequired: 600, missionsRequired: 8, timeRequired: 10800),
                KnowledgeTopic(name: "Formal Essay Writing", description: "...", xpRequired: 750, missionsRequired: 10, timeRequired: 13500)
            ]),
            KnowledgeBranch(name: "Spanish Conversation & Composition", description: "Developing fluency and advanced writing skills.", level: .college, prerequisiteBranchNames: ["Spanish IV"], prerequisiteCompletion: 0.90, totalXpRequired: 3500, totalMissionsRequired: 30, totalTimeRequired: 64800, requiredStats: ["Creativity": 10], topics: [
                KnowledgeTopic(name: "Oral Fluency Practice", description: "...", xpRequired: 800, missionsRequired: 12, timeRequired: 14400),
                KnowledgeTopic(name: "Advanced Composition", description: "...", xpRequired: 950, missionsRequired: 14, timeRequired: 17100)
            ])
        ])
    }

    private static func createEconomicsSubject() -> Subject {
        return Subject(name: "Economics", iconName: "chart.bar.xaxis", category: .socialScience, branches: [
            KnowledgeBranch(name: "High School Economics", description: "Basic principles of scarcity, choice, and markets.", level: .highSchool, topics: [
                KnowledgeTopic(name: "Basic Economic Principles", description: "...", xpRequired: 90, missionsRequired: 2, timeRequired: 1620),
                KnowledgeTopic(name: "Supply & Demand (Intro)", description: "...", xpRequired: 140, missionsRequired: 3, timeRequired: 2520)
            ]),
            KnowledgeBranch(name: "Microeconomics", description: "The behavior of individuals and firms in the economy.", level: .college, prerequisiteBranchNames: ["High School Economics", "Algebra I"], prerequisiteCompletion: 0.80, totalXpRequired: 2800, totalMissionsRequired: 20, totalTimeRequired: 50400, topics: [
                KnowledgeTopic(name: "Consumer Theory", description: "...", xpRequired: 500, missionsRequired: 6, timeRequired: 9000),
                KnowledgeTopic(name: "Producer Theory & Market Structures", description: "...", xpRequired: 650, missionsRequired: 8, timeRequired: 11700)
            ]),
            KnowledgeBranch(name: "Macroeconomics", description: "The study of the aggregate economy.", level: .college, prerequisiteBranchNames: ["Microeconomics"], prerequisiteCompletion: 0.90, totalXpRequired: 3200, totalMissionsRequired: 25, totalTimeRequired: 57600, topics: [
                KnowledgeTopic(name: "National Income Accounting (GDP, Inflation)", description: "...", xpRequired: 700, missionsRequired: 9, timeRequired: 12600),
                KnowledgeTopic(name: "Monetary & Fiscal Policy", description: "...", xpRequired: 850, missionsRequired: 11, timeRequired: 15300)
            ]),
            KnowledgeBranch(name: "Econometrics I", description: "Statistical methods for economic data.", level: .college, prerequisiteBranchNames: ["Macroeconomics", "Calculus I"], prerequisiteCompletion: 0.90, totalXpRequired: 4000, totalMissionsRequired: 30, totalTimeRequired: 72000, requiredStats: ["Intelligence": 12], topics: [
                KnowledgeTopic(name: "Linear Regression (Intro)", description: "...", xpRequired: 900, missionsRequired: 12, timeRequired: 16200),
                KnowledgeTopic(name: "Hypothesis Testing & Confidence Intervals", description: "...", xpRequired: 1100, missionsRequired: 14, timeRequired: 19800)
            ]),
            KnowledgeBranch(name: "International Economics", description: "The study of trade and finance between countries.", level: .college, prerequisiteBranchNames: ["Microeconomics", "Macroeconomics"], prerequisiteCompletion: 0.90, totalXpRequired: 3800, totalMissionsRequired: 30, totalTimeRequired: 68400, topics: [
                KnowledgeTopic(name: "Trade Theory", description: "...", xpRequired: 800, missionsRequired: 10, timeRequired: 14400),
                KnowledgeTopic(name: "International Finance", description: "...", xpRequired: 1000, missionsRequired: 12, timeRequired: 18000)
            ])
        ])
    }

    private static func createPhilosophySubject() -> Subject {
        return Subject(name: "Philosophy", iconName: "brain.head.profile", category: .humanities, branches: [
            KnowledgeBranch(name: "High School Philosophy", description: "Introduction to logic and ethical thought.", level: .highSchool, topics: [
                KnowledgeTopic(name: "Basic Logic & Argumentation", description: "...", xpRequired: 80, missionsRequired: 2, timeRequired: 1440),
                KnowledgeTopic(name: "Introduction to Ethics", description: "...", xpRequired: 120, missionsRequired: 3, timeRequired: 2160)
            ]),
            KnowledgeBranch(name: "Introduction to Philosophy", description: "Major questions of existence, knowledge, and values.", level: .college, prerequisiteBranchNames: ["High School Philosophy"], prerequisiteCompletion: 0.80, totalXpRequired: 2000, totalMissionsRequired: 15, totalTimeRequired: 36000, topics: [
                KnowledgeTopic(name: "Metaphysics (Reality & Existence)", description: "...", xpRequired: 350, missionsRequired: 5, timeRequired: 6300),
                KnowledgeTopic(name: "Epistemology (Theory of Knowledge)", description: "...", xpRequired: 450, missionsRequired: 6, timeRequired: 8100)
            ]),
            KnowledgeBranch(name: "Advanced Ethics", description: "In-depth study of moral theories and their applications.", level: .college, prerequisiteBranchNames: ["Introduction to Philosophy"], prerequisiteCompletion: 0.90, totalXpRequired: 2500, totalMissionsRequired: 20, totalTimeRequired: 43200, topics: [
                KnowledgeTopic(name: "Moral Theories (Utilitarianism, Deontology)", description: "...", xpRequired: 500, missionsRequired: 7, timeRequired: 9000),
                KnowledgeTopic(name: "Applied Ethics", description: "...", xpRequired: 650, missionsRequired: 9, timeRequired: 11700)
            ]),
            KnowledgeBranch(name: "Symbolic Logic", description: "Formal methods of evaluating arguments and reasoning.", level: .college, prerequisiteBranchNames: ["High School Philosophy"], prerequisiteCompletion: 0.90, totalXpRequired: 2800, totalMissionsRequired: 22, totalTimeRequired: 50400, requiredStats: ["Intelligence": 10], topics: [
                KnowledgeTopic(name: "Propositional Logic", description: "...", xpRequired: 700, missionsRequired: 10, timeRequired: 12600),
                KnowledgeTopic(name: "Quantificational Logic", description: "...", xpRequired: 850, missionsRequired: 12, timeRequired: 15300)
            ]),
            KnowledgeBranch(name: "Ancient Philosophy", description: "The foundations of Western thought from the Presocratics to Aristotle.", level: .college, prerequisiteBranchNames: ["Introduction to Philosophy", "High School History"], prerequisiteCompletion: 0.80, totalXpRequired: 3000, totalMissionsRequired: 25, totalTimeRequired: 54000, topics: [
                KnowledgeTopic(name: "Presocratics & Plato", description: "...", xpRequired: 600, missionsRequired: 8, timeRequired: 10800),
                KnowledgeTopic(name: "Aristotle & Hellenistic Philosophy", description: "...", xpRequired: 750, missionsRequired: 10, timeRequired: 13500)
            ])
        ])
    }

    private static func createPsychologySubject() -> Subject {
        return Subject(name: "Psychology", iconName: "eye.fill", category: .socialScience, branches: [
            KnowledgeBranch(name: "High School Psychology", description: "An introduction to the study of mind and behavior.", level: .highSchool, topics: [
                KnowledgeTopic(name: "Basic Brain Function & Behavior", description: "...", xpRequired: 90, missionsRequired: 2, timeRequired: 1620),
                KnowledgeTopic(name: "Memory & Learning (Intro)", description: "...", xpRequired: 140, missionsRequired: 3, timeRequired: 2520)
            ]),
            KnowledgeBranch(name: "Introduction to Psychology", description: "A survey of psychology's major topics and research methods.", level: .college, prerequisiteBranchNames: ["High School Psychology"], prerequisiteCompletion: 0.80, totalXpRequired: 2500, totalMissionsRequired: 20, totalTimeRequired: 43200, topics: [
                KnowledgeTopic(name: "Research Methods in Psychology", description: "...", xpRequired: 400, missionsRequired: 5, timeRequired: 7200),
                KnowledgeTopic(name: "Biological Bases of Behavior", description: "...", xpRequired: 600, missionsRequired: 8, timeRequired: 10800)
            ]),
            KnowledgeBranch(name: "Cognitive Psychology", description: "The study of mental processes such as attention, language use, memory, and problem-solving.", level: .college, prerequisiteBranchNames: ["Introduction to Psychology"], prerequisiteCompletion: 0.90, totalXpRequired: 3000, totalMissionsRequired: 25, totalTimeRequired: 54000, topics: [
                KnowledgeTopic(name: "Attention & Perception", description: "...", xpRequired: 700, missionsRequired: 9, timeRequired: 12600),
                KnowledgeTopic(name: "Problem Solving & Decision Making", description: "...", xpRequired: 850, missionsRequired: 11, timeRequired: 15300)
            ]),
            KnowledgeBranch(name: "Developmental Psychology", description: "The scientific study of how and why human beings change over the course of their life.", level: .college, prerequisiteBranchNames: ["Introduction to Psychology"], prerequisiteCompletion: 0.90, totalXpRequired: 3200, totalMissionsRequired: 28, totalTimeRequired: 57600, topics: [
                KnowledgeTopic(name: "Child Development", description: "...", xpRequired: 750, missionsRequired: 10, timeRequired: 13500),
                KnowledgeTopic(name: "Adolescent & Adult Development", description: "...", xpRequired: 900, missionsRequired: 12, timeRequired: 16200)
            ]),
            KnowledgeBranch(name: "Social Psychology", description: "How the thoughts, feelings, and behaviors of individuals are influenced by the actual, imagined, and implied presence of others.", level: .college, prerequisiteBranchNames: ["Introduction to Psychology"], prerequisiteCompletion: 0.90, totalXpRequired: 3400, totalMissionsRequired: 29, totalTimeRequired: 61200, topics: [
                KnowledgeTopic(name: "Attitudes & Persuasion", description: "...", xpRequired: 800, missionsRequired: 10, timeRequired: 14400),
                KnowledgeTopic(name: "Group Behavior & Conformity", description: "...", xpRequired: 950, missionsRequired: 12, timeRequired: 17100)
            ])
        ])
    }
}
