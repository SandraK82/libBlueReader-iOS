#
# Be sure to run `pod lib lint libBlueReader.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'libBlueReader'
  s.version          = '0.2.0'
  s.summary          = 'libBlueReader is the companion library to the open-source blueReader Hardware, buyable at bluereader.de'

  s.description      = <<-DESC
The blueReader NFC-to-BLE-Adapter is a ready to buy or diy Hardware for reading and writing nfc-tags via bluetooth enabled Devices. This library implements the interfaces for iOS to find a blueReader Bluetooth device, configure the device, and read/ write Tags
                       DESC

  s.homepage         = 'http://bluereader.de'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Sandra Keßler' => 'sk@softwarehaus-kassel.de' }
  s.source           = { :git => 'https://github.com/SandraK82/libBlueReader-iOS.git', :tag => s.version.to_s }
  s.social_media_url = 'http://unendlichkeit.net/wordpress/'

  s.platform = :ios
  s.ios.deployment_target = '8.0'

  s.source_files = 'libBlueReader/Classes/**/*'

  s.public_header_files = 'Pod/Classes/public/*.h'

end
