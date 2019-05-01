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

    public static var instance: QRScanConfig {
        return QRScanConfig(
            scannerColor: UIColor(hex: 0x0CBB2A),
            cameraViewBackgroundColor: nil,
            navTintColor: nil,
            navBarTintColor: nil,
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
        let navVC = NavigationController.init(rootViewController: qrVC, config: config)
        vc.present(navVC, animated: true, completion: nil)
        return qrVC.result
    }
}
