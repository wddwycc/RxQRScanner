import UIKit
import RxSwift
import RxCocoa
import AVFoundation


public class QRScannerViewController: UIViewController {
    let publisher = PublishSubject<QRScanResult>()
    let config: QRScanConfig
    let disposeBag = DisposeBag()

    private var animView: QRScannerAnimationView

    var session: AVCaptureSession?
    private lazy var ciContext: CIContext? = {
        guard let eaglContext = EAGLContext(api: EAGLRenderingAPI.openGLES2) else { return nil }
        return CIContext(eaglContext: eaglContext)
    }()

    init(config: QRScanConfig) {
        self.config = config
        animView = QRScannerAnimationView.init(frame: CGRect.zero, highlightColor: config.scannerColor)
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.gray
        title = config.titleText
        let cancelButton = UIBarButtonItem.init(title: config.cancelText, style: .plain, target: nil, action: nil)
        let albumButton = UIBarButtonItem.init(title: config.albumText, style: .plain, target: nil, action: nil)
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = albumButton

        animView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animView)
        NSLayoutConstraint.activate([
            animView.widthAnchor.constraint(equalToConstant: 240),
            animView.heightAnchor.constraint(equalToConstant: 240),
            animView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            animView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        animView.isHidden = true

        Observable
            .merge([
                NotificationCenter.default.rx.notification(.UIApplicationDidBecomeActive).map { _ in true },
                NotificationCenter.default.rx.notification(.UIApplicationDidEnterBackground).map { _ in false },
            ])
            .subscribe(onNext: { [weak self] on in
                self?.animView.toggleAnim(on: on)
                if on { self?.session?.startRunning() } else { self?.session?.stopRunning() }
            })
            .disposed(by: disposeBag)

        cancelButton.rx.tap
            .map { _ in QRScanResult.cancel }
            .subscribe(onNext: { [weak self] (rv) in
                self?.publisher.onNext(rv)
                self?.publisher.onCompleted()
                self?.navigationController?.dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)

        albumButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let self_ = self else { return }
                let pickerVC = imagePicker(config: self_.config)
                pickerVC.delegate = self
                self_.present(pickerVC, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)

        let status = AVCaptureDevice.authorizationStatus(for: .video)
        AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
            case .restricted:
                break
            case .authorized:
                try? initCamera()
            case .denied:
                break
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video, completionHandler: { [weak self] (success) in
                    DispatchQueue.main.async {
                        try? self?.initCamera()
                    }
                })
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animView.toggleAnim(on: true)
    }

    private func initCamera() throws {
        // device has no camera
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        let input = try AVCaptureDeviceInput.init(device: device)
        let session = AVCaptureSession()
        session.canSetSessionPreset(.high)
        session.addInput(input)

        let captureMetadataOutput = AVCaptureMetadataOutput()
        session.addOutput(captureMetadataOutput)

        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        captureMetadataOutput.rectOfInterest = CGRect(x: 0.15, y: 0.15, width: 0.7, height: 0.7)
        captureMetadataOutput.metadataObjectTypes = [
            .upce,
            .code39,
            .code39Mod43,
            .ean13,
            .ean8,
            .code93,
            .code128,
            .pdf417,
            .qr,
            .aztec,
            .interleaved2of5,
            .itf14,
            .dataMatrix,
        ]

        let cameraLayer = AVCaptureVideoPreviewLayer(session: session)
        cameraLayer.videoGravity = .resizeAspectFill
        cameraLayer.frame = view.layer.bounds
        view.layer.insertSublayer(cameraLayer, below: animView.layer)
        view.layoutIfNeeded()
        session.startRunning()
        animView.isHidden = false
        self.session = session
    }

    private func dismissWith(str: String) {
        publisher.onNext(.success(str))
        publisher.onCompleted()
        dismiss(animated: true, completion: nil)
    }
}

extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate, UINavigationControllerDelegate {
    public func metadataOutput(_ output: AVCaptureMetadataOutput,
                               didOutput metadataObjects: [AVMetadataObject],
                               from connection: AVCaptureConnection) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject else { return }
        guard let str = object.stringValue else { return }
        session?.stopRunning()
        dismissWith(str: str)
    }
}

extension QRScannerViewController: UIImagePickerControllerDelegate {
    @objc public func imagePickerController(_ picker: UIImagePickerController,
                                            didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            return
        }
        picker.dismiss(animated: true) { [weak self] in
            self?.validate(image: image)
        }
    }
    

    func validate(image: UIImage) {
        guard let ciContext = self.ciContext else {
            print("Cannot init CIContext")
            return
        }
        guard let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: ciContext, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]) else {
            print("Cannot init CIDetector")
            return
        }
        guard let ciImage = CIImage(image: image) else {
            navigationItem.prompt = "Cannot Convert UIImage to CIImage"
            return
        }
        guard let feature = detector.features(in: ciImage).first as? CIQRCodeFeature, let str = feature.messageString else {
            navigationItem.prompt = config.noFeatureOnImageText
            return
        }
        dismissWith(str: str)
    }
}
