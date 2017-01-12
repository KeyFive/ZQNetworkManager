
Pod::Spec.new do |s|
  s.name             = 'ZQNetworkManager'
  s.version          = '0.1.0'
  s.summary          = 'A network manager'
  s.description      = <<-DESC
 use cache throttle network manager
                       DESC

  s.homepage         = 'https://github.com/KeyFive/ZQNetworkManager.git'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'zhiqiangcao' => '13554392739@163.com' }
  s.source           = { :git => 'https://github.com/KeyFive/ZQNetworkManager.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '7.0'

  s.source_files = 'ZQNetworkManager/ZQNetworkManager/**/*'
  
  # s.resource_bundles = {
  #   'ZQNetworkManager' => ['ZQNetworkManager/Assets/*.png']
  # }

  s.public_header_files = 'ZQNetworkManager/ZQNetworkManager/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'YYCache', '~>1.0.4'
  s.dependency 'YYModel', '~>1.0.4'
end
