//
//  NavigationController.swift
//  RxQRScanner
//
//  Created by duan on 2019/07/23.
//

import UIKit


class NavigationController: UINavigationController {

    private var config: QRScanConfig = .instance

    init(rootViewController: UIViewController, config: QRScanConfig) {
        super.init(rootViewController: rootViewController)
        if let navTintColor = config.navTintColor {
            navigationBar.tintColor = navTintColor
            let textAttributes = [NSAttributedString.Key.foregroundColor:navTintColor]
            navigationBar.titleTextAttributes = textAttributes
        }
        if let navBarTintColor = config.navBarTintColor {
            navigationBar.barTintColor = navBarTintColor
        }
        navigationBar.barStyle = .black
        self.config = config
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { return config.statusBarStyle }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .portrait }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { return .portrait }
}
