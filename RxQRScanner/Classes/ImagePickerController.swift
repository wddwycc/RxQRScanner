//
//  ImagePickerController.swift
//  RxQRScanner
//
//  Created by duan on 2019/07/23.
//

import UIKit


class ImagePickerController: UIImagePickerController {
    var statusBarStyle: UIStatusBarStyle = .default {
        didSet { setNeedsStatusBarAppearanceUpdate() }
    }
    override var preferredStatusBarStyle: UIStatusBarStyle { return statusBarStyle }
}
