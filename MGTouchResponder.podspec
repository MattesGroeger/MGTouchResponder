Pod::Spec.new do |s|
  s.name         = "MGTouchResponder"
  s.version      = "0.0.1"
  s.summary      = "This library provides a high level structure of touches."
  s.homepage     = "https://github.com/MattesGroeger/MGTouchResponder"
  s.license      = 'MIT'
  s.author       = { "Mattes Groeger" => "info@mattes-groeger.de" }
  s.source       = { :git => "https://github.com/MattesGroeger/MGTouchResponder.git", :tag => "0.0.1" }
  s.source_files = 'MGTouchResponder/Classes/**/*.{h,m}'
  s.requires_arc = true
  s.dependency     'cocos2d', '~> 2.0.0'
end
