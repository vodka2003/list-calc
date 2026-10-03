import Foundation
import SwiftUI
import GoogleMobileAds
import UIKit

/// リワード広告の表示と「バナーを12時間非表示」の管理
final class AppAdManager: NSObject, ObservableObject {
    private static let bannerHiddenUntilKey = "BannerHiddenUntil"
    private static let bannerHideDuration: TimeInterval = 12 * 60 * 60
    
    private let rewardedAdUnitID = "ca-app-pub-5141104646157619/9748877673"
    
    private var rewardedAd: RewardedAd?
    @Published var isRewardedAdLoading = false
    @Published var isRewardedAdReady = false
    
    var shouldShowBanner: Bool {
        let until = UserDefaults.standard.double(forKey: Self.bannerHiddenUntilKey)
        if until <= 0 { return true }
        return Date().timeIntervalSince1970 >= until
    }
    
    override init() {
        super.init()
    }
    
    func loadRewardedAd() {
     print("📣 loadRewardedAd が呼ばれました！")
     guard !isRewardedAdLoading else { print("⚠️ すでに読み込み中です")
     return }
     if isRewardedAdReady {
     print("✅ すでに広告の準備ができています")
     return
     }
     isRewardedAdLoading = true
     isRewardedAdReady = false
     
     DispatchQueue.main.async { [weak self] in
     guard let self = self else { return }
     
     RewardedAd.load(with: self.rewardedAdUnitID, request: Request(), completionHandler: { [weak self] ad, error in
     
     DispatchQueue.main.async {
     self?.isRewardedAdLoading = false
     if let error = error {
     print("リワード広告の読み込みに失敗: \(error.localizedDescription)")
     return
     }
     print("リワード広告の読み込みに成功しました！")
     self?.rewardedAd = ad
     self?.rewardedAd?.fullScreenContentDelegate = self
     self?.isRewardedAdReady = true
     }
     })
     }
     }
    

    /// リワード広告を表示する。視聴完了時にバナーを12時間非表示にする
    func showRewardedAd() {
            guard let ad = rewardedAd else {
                print("広告の準備ができていません")
                return
            }
            
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = scene.windows.first else {
                return
            }
            
            // 現在表示中のViewControllerから広告を提示する。
            var topController = window.rootViewController
            
            while let presented = topController?.presentedViewController {
                topController = presented
            }
            
            guard let finalController = topController else {
                print("表示すべき画面が見つかりませんでした")
                return
            }

            ad.present(from: finalController) { [weak self] in
                self?.grantBannerHideReward()
            }
        }

    /// 報酬付与後、バナーを12時間非表示にする
    private func grantBannerHideReward() {
        let until = Date().timeIntervalSince1970 + Self.bannerHideDuration
        UserDefaults.standard.set(until, forKey: Self.bannerHiddenUntilKey)
        rewardedAd = nil
        isRewardedAdReady = false
        objectWillChange.send()
    }

    func getRemainingTimeText() -> String? {
            let until = UserDefaults.standard.double(forKey: Self.bannerHiddenUntilKey)
            let remaining = until - Date().timeIntervalSince1970
            
            if remaining <= 0 { return nil }
            
            let hours = Int(remaining) / 3600
            let minutes = (Int(remaining) % 3600) / 60
            return "残り \(hours)時間 \(minutes)分"
        }
    
    private static var rootViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController
    }
}

// MARK: - FullScreenContentDelegate
extension AppAdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        rewardedAd = nil
        DispatchQueue.main.async { [weak self] in
            self?.isRewardedAdReady = false
        }
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        rewardedAd = nil
        DispatchQueue.main.async { [weak self] in
            self?.isRewardedAdReady = false
        }
    }
}
