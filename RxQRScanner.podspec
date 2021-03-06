#
# Be sure to run `pod lib lint RxQRScanner.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'RxQRScanner'
  s.version          = '2.2.0'
  s.swift_version    = '5.0'
  s.summary          = 'QRScanner in RxSwift way'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Popup QRScanner like a boss
                       DESC

  s.homepage         = 'https://github.com/wddwycc/RxQRScanner'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'wddwycc' => 'wddwyss@gmail.com' }
  s.source           = { :git => 'https://github.com/wddwycc/RxQRScanner.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/wddwycc'

  s.ios.deployment_target = '9.0'

  s.source_files = 'RxQRScanner/Classes/**/*'
  
  s.resource_bundles = {
    'RxQRScanner' => ['RxQRScanner/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'RxSwift', '~> 5.0'
  s.dependency 'RxCocoa', '~> 5.0'
end
