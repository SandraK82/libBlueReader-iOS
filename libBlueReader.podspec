#
# Be sure to run `pod lib lint libBlueReader.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "libBlueReader"
  s.version          = "0.0.5"
  s.summary          = "libBlueReader is the companion library to the open-source blueReader Hardware"
  s.description      = <<-DESC
The blueReader NFC-BLE-Adapter is a ready to buy or diy Hardware for reading and writing nfc-tags via a bluetooth enabled Device. This library implements the interfaces for iOS to find a blueReader Bluetooth device, configure the device, and read/ write Tags
                       DESC

  s.homepage         = "https://github.com/SandraK82/libBlueReader-iOS"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Sandra Keßler" => "sk@softwarehaus-kassel.de" }
  s.source           = { :git => "https://github.com/SandraK82/libBlueReader-iOS.git", :tag => s.version.to_s }

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'libBlueReader' => ['Pod/Assets/*.png']
  }

  s.ios.framework = 'CoreBluetooth'
  s.public_header_files = 'Pod/Classes/blueReader.h'
end
