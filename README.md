# RxQRScanner

[![Version](https://img.shields.io/cocoapods/v/RxQRScanner.svg?style=flat)](http://cocoapods.org/pods/RxQRScanner)
[![License](https://img.shields.io/cocoapods/l/RxQRScanner.svg?style=flat)](http://cocoapods.org/pods/RxQRScanner)
[![Platform](https://img.shields.io/cocoapods/p/RxQRScanner.svg?style=flat)](http://cocoapods.org/pods/RxQRScanner)


**Popup QRScanner like a boss**

```swift
import RxQRScanner

button.rx.tap
    .flatMap { [unowned self] in QRScanner.popup(on: self) }
    .map({ (result) -> String? in
        if case let .success(str) = result { return str }
        return nil
    })
    .bind(to: label.rx.text)
    .disposed(by: disposeBag)
```

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

* iOS >= 9.0
* Swift 5

## Installation

RxQRScanner is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'RxQRScanner', '~> 2.0'
```

## Author

wddwycc, wddwyss@gmail.com

## License

RxQRScanner is available under the MIT license. See the LICENSE file for more info.
