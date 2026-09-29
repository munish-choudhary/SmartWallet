#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint wallet_core_ffi.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'wallet_core_ffi'
  s.version          = '0.0.1'
  s.summary          = 'FFI bindings to Trust Wallet Core (internal, no native implementation yet).'
  s.description      = <<-DESC
Internal package consumed only by SmartWallet's core/vault. Currently a stub:
no Trust Wallet Core binary is linked. See README.md for what's left.
                       DESC
  s.homepage         = 'https://example.com'
  s.license          = { :type => 'Proprietary' }
  s.author           = { 'SmartWallet' => 'noreply@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
