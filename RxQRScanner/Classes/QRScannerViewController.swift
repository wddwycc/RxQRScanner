import UIKit
import RxSwift
import RxCocoa
import AVFoundation


class QRScannerViewController: UIViewController, CallbackObservable {
    typealias Result = QRScanResult
    var result = PublishSubject<Result>()
    private let disposeBag = DisposeBag()

    private let config: QRScanConfig
    private let animView: QRScannerAnimationView
    private lazy var qrImageDetector: QRImageDetector = QRImageDetector.init(config: self.config)
    var delegate: DelegateProxy<AnyObject, Any>?
    private var session: AVCaptureSession?

    init(config: QRScanConfig) {
        self.config = config
        animView = QRScannerAnimationView.init(frame: CGRect.zero, color: config.scannerColor)
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
        animView.alpha = 0

        Observable
            .merge([
                NotificationCenter.default.rx.notification(.UIApplicationDidBecomeActive).map { _ in true },
                NotificationCenter.default.rx.notification(.UIApplicationDidEnterBackground).map { _ in false },
            ])
            .filter { [weak self] _ in self?.view.window != nil }
            .subscribe(onNext: { [weak self] on in
                self?.toggleScan(on: on)
            })
            .disposed(by: disposeBag)

        cancelButton.rx.tap
            .map { _ in QRScanResult.cancel }
            .subscribe(onNext: { [weak self] (rv) in
                self?.result.onNext(rv)
                self?.result.onCompleted()
                self?.navigationController?.dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)

        albumButton.rx.tap
            .do(onNext: { [unowned self] _ in self.toggleScan(on: false) })
            .flatMap { [unowned self] _ -> Observable<QRImageDetectResult> in
                return self.qrImageDetector.popup(on: self)
            }
            .do(onNext: { [unowned self] result in
                if case .success(_) = result { return }
                self.toggleScan(on: true)
            })
            .subscribe(onNext: { [weak self] (result) in
                switch result {
                case .success(let str):
                    self?.result.onNext(.success(str))
                    self?.result.onCompleted()
                    self?.navigationController?.dismiss(animated: true, completion: nil)
                case .fail:
                    self?.navigationItem.prompt = self?.config.noFeatureOnImageText
                default: break
                }
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
        self.session = session
        toggleScan(on: true)
    }

    private func toggleScan(on: Bool) {
        if on {
            self.session?.startRunning()
        } else {
            self.session?.stopRunning()
        }
        UIView.animate(withDuration: 0.2) {
            if self.session == nil {
                self.animView.alpha = 0
            } else {
                self.animView.alpha = on ? 1 : 0
            }
        }
    }
}

// todo: replace with Rx Style
extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate, UINavigationControllerDelegate {
    public func metadataOutput(_ output: AVCaptureMetadataOutput,
                               didOutput metadataObjects: [AVMetadataObject],
                               from connection: AVCaptureConnection) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject else { return }
        guard let str = object.stringValue else { return }
        session?.stopRunning()
        toggleScan(on: false)
        result.onNext(.success(str))
        result.onCompleted()
    }
}
