import SwiftUI

// A helper for applying modifiers conditionally.
fileprivate extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

/// This debugger tests if attaching sheet modifiers for certain views causes the toolbar to disappear.
struct ToolbarDestinationDebugger: View {
    
    // We need to create dummy view models for the destination views to be initialized.
    @StateObject private var mainViewModel: MainViewModel
    @StateObject private var missionsViewModel: MissionsViewModel

    // Toggles to control which sheet modifiers are currently attached to the view.
    @State private var attachSimpleSheet = false
    @State private var attachDungeonsSheet = false
    @State private var attachBossSheet = false

    // State to control the actual presentation of the sheets (we won't use these in the test).
    @State private var showSimple = false
    @State private var showDungeons = false
    @State private var showBoss = false
    
    init() {
        let player = Player(username: "DebugPlayer")
        let mainVM = MainViewModel(player: player)
        _mainViewModel = StateObject(wrappedValue: mainVM)
        _missionsViewModel = StateObject(wrappedValue: MissionsViewModel(mainViewModel: mainVM))
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 15) {
                Text("Toolbar Crash Debugger")
                    .font(.title)
                
                Text("The toolbar above should initially be visible with a 'Test Button'. Flip the switches below one at a time. If the toolbar disappears when you enable one, that view is the cause of the crash.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom)

                // --- CONTROLS ---
                Toggle("1. Attach Simple Sheet Modifier", isOn: $attachSimpleSheet)
                Toggle("2. Attach DungeonsView Sheet Modifier", isOn: $attachDungeonsSheet)
                Toggle("3. Attach BossBattleView Sheet Modifier", isOn: $attachBossSheet)
                
                Spacer()
                
                Text("Note: We are only testing if attaching the modifier causes a crash. The buttons in the toolbar are not meant to present these sheets during this test.")
                    .font(.caption)
            }
            .padding()
            .navigationTitle("Debugger")
            .toolbar {
                // A very simple toolbar that should always be stable.
                ToolbarItem(placement: .primaryAction) {
                    Button("Test Button") {}
                        .buttonStyle(.bordered)
                }
            }
            // Conditionally attach sheet modifiers based on the toggles.
            .if(attachSimpleSheet) { view in
                view.sheet(isPresented: $showSimple) { Text("This is a simple, safe sheet.") }
            }
            .if(attachDungeonsSheet) { view in
                view.sheet(isPresented: $showDungeons) {
                    DungeonsView(missionsViewModel: missionsViewModel, mainViewModel: mainViewModel)
                }
            }
            .if(attachBossSheet) { view in
                view.sheet(isPresented: $showBoss) {
                    BossBattleView(mainViewModel: mainViewModel)
                }
            }
        }
        .frame(width: 500, height: 400)
    }
}

struct ToolbarDestinationDebugger_Previews: PreviewProvider {
    static var previews: some View {
        ToolbarDestinationDebugger()
    }
}
