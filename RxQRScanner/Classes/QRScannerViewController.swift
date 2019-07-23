import UIKit
import RxSwift
import RxCocoa
import AVFoundation


class QRScannerViewController: UIViewController, CallbackObservable {
    typealias Result = QRScanResult
    let result = PublishSubject<Result>()
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
        view.backgroundColor = config.cameraViewBackgroundColor ?? UIColor.black
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
                NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification).map { _ in true },
                NotificationCenter.default.rx.notification(UIApplication.didEnterBackgroundNotification).map { _ in false },
            ])
            .filter { [weak self] _ in self?.view.window != nil }
            .subscribe(onNext: { [weak self] on in
                self?.toggleScan(on: on)
                self?.animView.toggleAnim(on: on)
            })
            .disposed(by: disposeBag)

        cancelButton.rx.tap
            .subscribe(onNext: { [unowned self] _ in
                self.dismiss(with: .cancel)
            })
            .disposed(by: disposeBag)

        albumButton.rx.tap
            .do(onNext: { [unowned self] _ in self.toggleScan(on: false) })
            .flatMap { [unowned self] in self.qrImageDetector.popup(on: self) }
            .do(onNext: { [unowned self] result in
                if case .success(_) = result { return }
                self.toggleScan(on: true)
            })
            .subscribe(onNext: { [weak self] (result) in
                switch result {
                case .success(let str):
                    self?.dismiss(with: .success(str))
                case .fail:
                    self?.navigationItem.prompt = self?.config.noFeatureOnImageText
                default: break
                }
            })
            .disposed(by: disposeBag)

        rx.methodInvoked(#selector(viewDidAppear(_:)))
            .take(1)
            .flatMap { _ in videoAccess() }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (status) in
                switch status {
                case .authorized:
                    try? self?.initCamera()
                case .denied:
                    self?.showEmptyView()
                default:
                    break
                }
            })
            .disposed(by: disposeBag)

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

    private func showEmptyView() {
        let emptyView = QREmptyView.init(type: .denied)
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyView)
        NSLayoutConstraint.activate([
            emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyView.topAnchor.constraint(equalTo: view.topAnchor),
            emptyView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func dismiss(with result: QRScanResult) {
        let subject = self.result
        navigationController?.dismiss(animated: true, completion: {
            subject.onNext(result)
            subject.onCompleted()
        })
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
        dismiss(with: .success(str))
    }
}

fileprivate func videoAccess() -> Observable<AVAuthorizationStatus> {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    return Observable.create { (observer) -> Disposable in
        if case .notDetermined = status {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (success) in
                observer.onNext(success ? .authorized : .denied)
            })
        } else {
            observer.onNext(status)
        }
        return Disposables.create()
    }
}
