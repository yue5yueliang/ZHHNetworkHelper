#
# Be sure to run `pod lib lint ZHHNetworkHelper.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ZHHNetworkHelper'
  s.version          = '0.0.1'
  s.summary          = '基于AFNetworking封装的网络请求缓存工具类'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
这个一个基于AFNetworking 4.x 与YYCache，进行封装网络请求缓存工具类，对求失败多状态进的回调，和统一网络监听。
                       DESC

  s.homepage         = 'https://github.com/yue5yueliang/ZHHNetworkHelper'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '桃色三岁' => '136769890@qq.com' }
  s.source           = { :git => 'https://github.com/yue5yueliang/ZHHNetworkHelper.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'

  s.source_files = 'ZHHNetworkHelper/Classes/**/*'
  
  # s.resource_bundles = {
  #   'ZHHNetworkHelper' => ['ZHHNetworkHelper/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'AFNetworking'
  s.dependency 'YYCache'
end
