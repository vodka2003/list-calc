import SwiftUI
import GoogleMobileAds
import UIKit

// MARK: - バナー表示View
struct AdBannerView: UIViewControllerRepresentable {
    let width: CGFloat
    @Binding var adHeight: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let bannerView = BannerView()
        bannerView.tag = 100
        bannerView.adUnitID = "ca-app-pub-5141104646157619/5353756532"
        bannerView.rootViewController = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController
        bannerView.delegate = context.coordinator

        viewController.view.addSubview(bannerView)
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            bannerView.topAnchor.constraint(equalTo: viewController.view.topAnchor)
        ])
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard let bannerView = uiViewController.view.viewWithTag(100) as? BannerView else { return }

        if width > 0 {
            let adSize = currentOrientationAnchoredAdaptiveBanner(width: width)
            bannerView.adSize = adSize
            DispatchQueue.main.async {
                            bannerView.load(Request())
                        }
        }
    }

    class Coordinator: NSObject, BannerViewDelegate {
        let parent: AdBannerView

        init(_ parent: AdBannerView) {
            self.parent = parent
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            DispatchQueue.main.async {
                self.parent.adHeight = bannerView.adSize.size.height
            }
        }
    }
}

