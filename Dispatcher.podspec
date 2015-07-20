Pod::Spec.new do |s|
  s.name             = "Dispatcher"
  s.version          = "0.2.0"
  s.license          = 'MIT'
  s.summary          = "Facebook Flux Dispatcher rewritten in Swift"
  s.homepage         = "https://github.com/russbishop/Dispatcher"
  s.authors          = { "Mikkel Malmberg" => "mikkel@brnbw.com", "Russ Bishop" => "russ@plangrid.com" }
  s.source           = { :git => "https://github.com/russbishop/Dispatcher.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/xenadu02'

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'

  s.source_files = 'Dispatcher.swift'
  s.requires_arc = true
end
