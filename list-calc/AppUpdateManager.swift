import Foundation
import FirebaseRemoteConfig

class AppUpdateManager: ObservableObject {
    @Published var isUpdateRequired = false


    func checkVersion() {
        let remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings

        try? remoteConfig.setDefaults(from: ["force_update_version": "1.0.0"])

        remoteConfig.fetch { (status, error) in
            if status == .success {
                remoteConfig.activate { _, _ in
                    let requiredVersion = remoteConfig.configValue(forKey: "force_update_version").stringValue ?? "1.0.0"
                    
                    let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"

                    DispatchQueue.main.async {
                        if self.isVersion(currentVersion, lessThan: requiredVersion) {
                            self.isUpdateRequired = true
                        }
                    }
                }
            } else {
                print("Config fetch failed: \(error?.localizedDescription ?? "No error available.")")
            }
        }
    }
    
    // ドット区切りのバージョンを数値順で比較する。
    func isVersion(_ current: String, lessThan required: String) -> Bool {
        return current.compare(required, options: .numeric) == .orderedAscending
    }
}
