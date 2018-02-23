//
//  ViewController.swift
//  RxQRScanner
//
//  Created by duan on 02/22/2018.
//  Copyright (c) 2018 monk-studio. All rights reserved.
//

import UIKit
import RxSwift
import RxQRScanner


class ViewController: UIViewController {

    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        var config = QRScanConfig.instance
        config.navTintColor = UIColor.gray
        QRScanner.popup(on: self, config: config)
            .subscribe(onNext: { (result) in
                print(result)
            })
            .disposed(by: disposeBag)
    }
}

