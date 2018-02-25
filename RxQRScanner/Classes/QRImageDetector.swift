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
    lazy var pickerVC: UIImagePickerController = {
        let pickerVC = UIImagePickerController()
        pickerVC.sourceType = .photoLibrary
        if let navTintColor = self.config.navTintColor {
            pickerVC.navigationBar.tintColor = navTintColor
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

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: { [weak self] in
            if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
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
        guard let eaglContext = EAGLContext(api: EAGLRenderingAPI.openGLES2) else {
            return .internalError("Cannot init CIContext")
        }
        let context = CIContext(eaglContext: eaglContext)
        guard let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context,
                                        options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]) else {
            return .internalError("Cannot init CIDetector")
        }
        guard let ciImage = CIImage(image: self) else {
            return .internalError("Cannot Convert UIImage to CIImage")
        }
        guard let feature = detector.features(in: ciImage).first as? CIQRCodeFeature, let str = feature.messageString else {
            return .fail
        }
        return .success(str)
    }
}
