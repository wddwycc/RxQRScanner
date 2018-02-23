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
            .flatMap { QRScanner.popup(on: self) }
            .subscribe(onNext: { [weak self] (result) in
                switch result {
                case .success(let str):
                    self?.label.text = "Got \(str)"
                default: break
                }
            })
            .disposed(by: disposeBag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}

