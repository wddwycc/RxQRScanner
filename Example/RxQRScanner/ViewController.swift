//
//  ViewController.swift
//  RxQRScanner
//
//  Created by duan on 02/22/2018.
//  Copyright (c) 2018 monk-studio. All rights reserved.
//

import UIKit
import TinyConstraints
import RxSwift
import RxCocoa
import RxQRScanner


class ViewController: UIViewController {

    let button = UIButton()
    let label = UILabel()
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        button.setTitle("Start Scanner", for: .normal)
        button.setTitleColor(UIColor.blue, for: .normal)
        view.addSubview(button)
        button.center(in: view)
        label.textColor = .gray
        view.addSubview(label)
        label.topToBottom(of: button)
        label.centerX(to: button)

button.rx.tap
    .flatMap { [unowned self] in QRScanner.popup(on: self) }
    .map({ (result) -> String? in
        if case let .success(str) = result { return str }
        return nil
    })
    .bind(to: label.rx.text)
    .disposed(by: disposeBag)
    }
}

