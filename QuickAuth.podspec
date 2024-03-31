#
# Be sure to run `pod lib lint CertificatePinner.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'QuickAuth'
  s.version          = '1.0.3'
  s.summary          = 'QuickAuth is simple OAuth2 authentication library designed for Swift applications.'
  s.description      = <<-DESC
  QuickAuth is simple OAuth2 authentication library designed for Swift applications. It handles all authorized and non-authorized network requests, leveraging access and refresh tokens for authentication. QuickAuth emphasizes security by avoiding the storage of sensitive information on the library side, instead delegating this responsibility to the client application. Importantly, QuickAuth is built on the Combine framework, offering a modern approach to asynchronous programming in Swift.
                       DESC

  s.homepage         = 'https://github.com/micho233/quickauth'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Mirsad Arslanovic' => 'mirsad.arslanovic@gmail.com' }
  s.source           = { :git => 'https://github.com/micho233/quickauth.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/Hepek233'

  s.cocoapods_version = '>= 1.13.0'

  s.swift_versions = ['5']

  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = "10.15"
  s.watchos.deployment_target = '7.0'
  s.tvos.deployment_target = '13.0'

  s.source_files = 'Sources/**/*'
  
  s.resource_bundles = {'Alamofire' => ['Sources/PrivacyInfo.xcprivacy']}
end
