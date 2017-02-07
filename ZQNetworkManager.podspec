#
# Be sure to run `pod lib lint ZQNetworkManager.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ZQNetworkManager'
  s.version          = '1.0.0'
  s.summary          = 'A network mangaer'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  a cache trollet network manager
                       DESC

  s.homepage         = 'https://github.com/KeyFive/ZQNetworkManager.git'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'zhiqiangcao' => '13554392739@163.com' }
  s.source           = { :git => 'https://github.com/KeyFive/ZQNetworkManager.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '7.0'

  s.source_files = 'ZQNetworkManager/ZQNetworkManager/**/*.{h,m}'
  
  # s.resource_bundles = {
  #   'ZQNetworkManager' => ['ZQNetworkManager/Assets/*.png']
  # }

  s.public_header_files = 'ZQNetworkManager/ZQNetworkManager/ZQNetworkManager.h'
  s.frameworks = 'UIKit'
  s.dependency 'YYCache', '~>1.0.4'
  s.dependency 'YYModel', '~>1.0.4'
  s.dependency 'AFNetworking', '~>3.1.0'
  s.dependency 'YYCategories', '~>1.0.4'
end
