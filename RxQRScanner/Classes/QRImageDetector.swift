import UIKit
import RxSwift
import RxCocoa


enum QRImageDetectResult {
    case success(String)
    case fail
    case internalError(String)
    case cancel
}

class QRImageDetector: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    let config: QRScanConfig
    let result = PublishSubject<QRImageDetectResult>()
    lazy var pickerVC: ImagePickerController = {
        let pickerVC = ImagePickerController()
        pickerVC.statusBarStyle = config.statusBarStyle
        pickerVC.sourceType = .photoLibrary
        pickerVC.modalPresentationStyle = .fullScreen
        if let navTintColor = config.navTintColor {
            pickerVC.navigationBar.tintColor = navTintColor
            let textAttributes = [NSAttributedString.Key.foregroundColor:navTintColor]
            pickerVC.navigationBar.titleTextAttributes = textAttributes
        }
        if let navBarTintColor = config.navBarTintColor {
            pickerVC.navigationBar.barTintColor = navBarTintColor
        }
        pickerVC.delegate = self
        return pickerVC
    }()

    init(config: QRScanConfig) {
        self.config = config
    }

    func popup(on: UIViewController) -> Observable<QRImageDetectResult> {
        on.present(pickerVC, animated: true, completion: nil)
        return self.result
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: { [weak self] in
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                self?.result.onNext(image.detectQR())
            } else {
                self?.result.onNext(QRImageDetectResult.fail)
            }
        })
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) { [weak self] in
            self?.result.onNext(.cancel)
        }
    }
}

extension UIImage {
    func detectQR() -> QRImageDetectResult {
        guard let detector = MTLCreateSystemDefaultDevice()
            .flatMap(CIContext.init)
            .flatMap({
                CIDetector(ofType: CIDetectorTypeQRCode, context: $0,
                           options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
            }) else {
                return .internalError("Cannot init CIDetector")
            }
        return CIImage(image: self)
            .flatMap(detector.features(in:))
            .flatMap(\.first)
            .flatMap({ $0 as? CIQRCodeFeature })
            .flatMap(\.messageString)
            .map(QRImageDetectResult.success) ?? .fail
    }
}
