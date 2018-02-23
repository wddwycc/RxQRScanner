import Foundation
import RxSwift


public enum QRScanResult {
    case fail
    case success(String)
    case cancel
}

public struct QRScanConfig {
    public var continuous: Bool
    public var scannerColor: UIColor
    public var navTintColor: UIColor?
    public var titleText: String
    public var cancelText: String
    public var albumText: String
    public var noFeatureOnImageText: String

    public static var instance: QRScanConfig {
        return QRScanConfig.init(
            continuous: false,
            scannerColor: UIColor.init(hex: 0x0CBB2A),
            navTintColor: nil,
            titleText: "Scan QR",
            cancelText: "Cancel",
            albumText: "Album",
            noFeatureOnImageText: "Cannot Find feature on image"
        )
    }
}

public final class QRScanner {
    public static func popup(on vc: UIViewController,
                             config: QRScanConfig = QRScanConfig.instance) -> Observable<QRScanResult> {
        let qrVC = QRScannerViewController.init(config: config)
        let navVC = NavigationController.init(rootViewController: qrVC)
        vc.present(navVC, animated: true, completion: nil)
        return qrVC.publisher.asObserver()
    }
}
