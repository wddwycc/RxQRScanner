//
//  ViewController.swift
//  RxQRScanner
//
//  Created by duan on 02/22/2018.
//  Copyright (c) 2018 monk-studio. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxQRScanner


class ViewController: UIViewController {

    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        let button = UIButton()
        button.setTitle("Start Scanner", for: .normal)
        button.setTitleColor(UIColor.blue, for: .normal)
        view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        button.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

        let label = UILabel()
        label.textColor = .gray
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.topAnchor.constraint(equalTo: button.bottomAnchor).isActive = true
        label.centerXAnchor.constraint(equalTo: button.centerXAnchor).isActive = true

        var config = QRScanConfig.instance
        config.navTintColor = UIColor.white
        config.navBarTintColor = UIColor.black
        button.rx.tap
            .flatMap { [unowned self] in QRScanner.popup(on: self, config: config) }
            .map({ (result) -> String? in
                if case let .success(str) = result { return str }
                return nil
            })
            .bind(to: label.rx.text)
            .disposed(by: disposeBag)
    }
}

