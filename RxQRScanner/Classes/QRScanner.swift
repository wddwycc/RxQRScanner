import Foundation
import RxSwift


public enum QRScanResult {
    case success(String)
    case cancel
}

public struct QRScanConfig {
    public var scannerColor: UIColor
    public var cameraViewBackgroundColor: UIColor?
    public var navTintColor: UIColor?
    public var navBarTintColor: UIColor?
    public var titleText: String
    public var cancelText: String
    public var albumText: String
    public var noFeatureOnImageText: String
    public var statusBarStyle: UIStatusBarStyle

    public static var instance: QRScanConfig {
        return QRScanConfig(
            scannerColor: UIColor(hex: 0x0CBB2A),
            cameraViewBackgroundColor: nil,
            navTintColor: nil,
            navBarTintColor: nil,
            titleText: "Scan QR",
            cancelText: "Cancel",
            albumText: "Album",
            noFeatureOnImageText: "Cannot Find feature on image",
            statusBarStyle: .default
        )
    }
}

public final class QRScanner {
    public static func popup(
        on vc: UIViewController,
        config: QRScanConfig = QRScanConfig.instance
    ) -> Observable<QRScanResult> {
        let qrVC = QRScannerViewController(config: config)
        let navVC = NavigationController(rootViewController: qrVC, config: config)
        navVC.modalPresentationStyle = .fullScreen
        vc.present(navVC, animated: true, completion: nil)
        return qrVC.result
    }
}
