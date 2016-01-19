Pod::Spec.new do |s|
  s.name             = "PLXImageManager"
  s.version          = "4.0.1"
  s.summary          = "Image manager/downloader for iOS"
  s.homepage         = "https://github.com/Polidea/PLXImageManager"
  s.license          = 'BSD'
  s.author           = { "Antoni Kedracki" => "antoni.kedracki@polidea.com" }
  s.source           = { :git => "https://github.com/Polidea/PLXImageManager.git", :tag => s.version.to_s }
  s.platform     = :ios, '7.0'
  s.requires_arc = true
  s.source_files = 'Pod/Classes/**/*'
end
