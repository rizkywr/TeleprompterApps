import SwiftUI

struct ContentView: View {
    @StateObject private var scriptStore = ScriptStore()
    @State private var activeScriptForStudio: Script? = nil
    
    var body: some View {
        HomeView(
            scriptStore: scriptStore,
            onRecordScript: { script in
                activeScriptForStudio = script
            }
        )
        .fullScreenCover(item: $activeScriptForStudio) { script in
            CameraStudioView(
                script: script,
                onTakeFinished: { newRecording in
                    scriptStore.addRecording(newRecording)
                }
            )
        }
    }
}
