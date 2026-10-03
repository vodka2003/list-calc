import SwiftUI
import SwiftData
import GoogleMobileAds
import FirebaseCore

@main
struct list_calcApp: App {
    @StateObject var adManager = AppAdManager()
    @StateObject var updateManager = AppUpdateManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        FirebaseApp.configure()
        MobileAds.shared.start { status in
            print("AdMob initialized with status: \(status.adapterStatusesByClassName)")
        }
    }

    var body: some Scene {
            WindowGroup {
                ContentView()
                    .preferredColorScheme(.light)
                    .environmentObject(adManager)
                    .alert("新しいバージョンがあります", isPresented: $updateManager.isUpdateRequired) {
                        Button("あとで", role: .cancel) { }
                        Button("アップデートする") {
                            let appID = "6758515306"
                            if let url = URL(string: "https://apps.apple.com/app/id\(appID)") {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                    .task {
                                    updateManager.checkVersion()
                                }
            }
            .modelContainer(sharedModelContainer)
        }
    }
