import UIKit


class QRScannerAnimationView: UIView {
    private let contentView = UIView()
    private let aboveGridImageView: UIImageView = {
        let imageView = UIImageView(image: .bundleImage(named: "grid.png"))
        imageView.contentMode = .center
        imageView.alpha = 0.3
        return imageView
    }()
    private let belowGridImageView: UIImageView = {
        let imageView = UIImageView(image: .bundleImage(named: "grid.png"))
        imageView.contentMode = .center
        imageView.alpha = 0.3
        return imageView
    }()
    private lazy var stickLayer: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = self.color.cgColor
        layer.cornerRadius = 1.5
        layer.shadowOpacity = 0.6
        layer.shadowRadius = 5
        layer.shadowOffset = CGSize.zero
        layer.shadowColor = self.color.cgColor
        layer.rasterizationScale = UIScreen.main.scale
        layer.shouldRasterize = true
        return layer
    }()
    private lazy var aboveGradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [UIColor.clear.cgColor,
                        self.color.withAlphaComponent(0.4).cgColor]
        return layer
    }()
    private lazy var belowGradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [self.color.withAlphaComponent(0.4).cgColor,
                        UIColor.clear.cgColor]
        layer.opacity = 0.5
        return layer
    }()
    private let aboveGradientLayerMask: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [UIColor.black.cgColor, UIColor.black.cgColor]
        return layer
    }()
    private let belowGradientLayerMask: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [UIColor.black.cgColor, UIColor.black.cgColor]
        return layer
    }()

    private let color: UIColor

    init(frame: CGRect, color: UIColor) {
        self.color = color
        super.init(frame: frame)
        self.addSubview(contentView)
        contentView.addSubview(aboveGridImageView)
        contentView.addSubview(belowGridImageView)
        self.layer.addSublayer(stickLayer)
        contentView.layer.addSublayer(aboveGradientLayer)
        contentView.layer.addSublayer(belowGradientLayer)
        aboveGridImageView.layer.mask = aboveGradientLayerMask
        belowGridImageView.layer.mask = belowGradientLayerMask

        contentView.layer.cornerRadius = 5
        contentView.layer.masksToBounds = true
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        setupComponentsLayout()
    }

    func toggleAnim(on: Bool) {
        if on { start() } else { stop() }
    }

    private func start() {
        setComponents(hidden: false) { [weak self] in
            guard let self_ = self else { return }
            let moveAnim = CABasicAnimation(keyPath: "transform")
            moveAnim.duration = 1.2
            moveAnim.autoreverses = true
            moveAnim.repeatCount = MAXFLOAT
            moveAnim.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0, 0.6, 1)
            moveAnim.fromValue = NSValue(caTransform3D: CATransform3DIdentity)
            moveAnim.toValue = NSValue(caTransform3D: CATransform3DMakeTranslation(0, self_.bounds.height, 0))

            [self_.stickLayer, self_.aboveGradientLayer, self_.belowGradientLayer, self_.aboveGradientLayerMask, self_.belowGradientLayerMask]
                .forEach { (layer) in
                layer.add(moveAnim, forKey: "move")
            }

            let topAlphaAnim = CAKeyframeAnimation(keyPath: "opacity")
            topAlphaAnim.duration = 2.4
            topAlphaAnim.repeatCount = MAXFLOAT
            topAlphaAnim.values = [1, 1, 0, 0 ,1]
            topAlphaAnim.keyTimes = [0, 0.35, 0.7, 0.999, 1]
            self_.aboveGradientLayer.add(topAlphaAnim, forKey: "top")

            let BottomAlphaAnim = CAKeyframeAnimation(keyPath: "opacity")
            BottomAlphaAnim.duration = 2.4
            BottomAlphaAnim.repeatCount = MAXFLOAT
            BottomAlphaAnim.values = [0.5, 0, 0, 1, 1, 0.5]
            BottomAlphaAnim.keyTimes = [0, 0.15, 0.4999, 0.5, 0.85, 1]
            self_.belowGradientLayer.add(BottomAlphaAnim, forKey: "bottom")

            self_.aboveGradientLayerMask.add(topAlphaAnim, forKey: "top")
            self_.belowGradientLayerMask.add(BottomAlphaAnim, forKey: "bottom")
        }
    }

    private func stop(completion: (() -> ())? = nil) {
        let layerWithAnimation = [stickLayer, aboveGradientLayer,
                                  belowGradientLayer, aboveGradientLayerMask,
                                  belowGradientLayerMask]
        setComponents(hidden: true) {
            layerWithAnimation.forEach({ (layer) in
                layer.removeAllAnimations()
            })
            completion?()
        }
    }

    private func setComponents(hidden: Bool, completion: (() -> ())? = nil) {
        UIView.animate(withDuration: 0.1, animations: {
            [self.stickLayer, self.contentView.layer].forEach { (layer) in
                layer.opacity = hidden ? 0 : 1
            }
        }) { _ in completion?() }
    }

    private func animateToFrame(frame: CGRect) {
        stop { [weak self] in
            self?.frame = frame
            self?.setupComponentsLayout()
            self?.start()
        }
    }

    private func setupComponentsLayout() {
        aboveGridImageView.frame = bounds
        belowGridImageView.frame = bounds
        contentView.frame = bounds
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        stickLayer.frame = CGRect(x: -4, y: 0, width: bounds.width + 8, height: 3)
        CATransaction.commit()
        let gradientHeight: CGFloat = bounds.height
        aboveGradientLayer.frame = CGRect(x: 0, y: -gradientHeight, width: bounds.width, height: gradientHeight)
        belowGradientLayer.frame = CGRect(x: 0, y: 0, width: bounds.width, height: gradientHeight)
        aboveGradientLayerMask.frame = aboveGradientLayer.frame
        belowGradientLayerMask.frame = belowGradientLayer.frame
    }
}
