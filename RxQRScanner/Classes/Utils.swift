import UIKit


extension UIColor {
    convenience init(hex: Int, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex & 0xFF0000) >> 16) / 255.0,
                  green: CGFloat((hex & 0x00FF00) >> 8) / 255.0,
                  blue: CGFloat(hex & 0x0000FF) / 255.0,
                  alpha: alpha)
    }
}

extension UIImage {
    class func bundleImage(named: String) -> UIImage? {
        let frameworkBundle = Bundle.init(for: QRScanner.self)
        guard
            let url = frameworkBundle.resourceURL?.appendingPathComponent("RxQRScanner.bundle"),
            let bundle = Bundle.init(url: url)
        else { return nil }
        return UIImage(named: named, in: bundle, compatibleWith: nil)
    }
}

class NavigationController: UINavigationController {
    var config: QRScanConfig?

    init(rootViewController: UIViewController, config: QRScanConfig) {
        self.config = config
        super.init(rootViewController: rootViewController)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let navTintColor = config?.navTintColor {
            navigationController?.navigationBar.tintColor = navTintColor
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .portrait }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { return .portrait }
}

func imagePicker(config: QRScanConfig) -> UIImagePickerController {
    let picker = UIImagePickerController()
    if let navTintColor = config.navTintColor {
        picker.navigationBar.tintColor = navTintColor
    }
    picker.sourceType = .photoLibrary
    return picker
}

