
Pod::Spec.new do |s|

  	s.name         = 'DLRouter'
    s.version      = '0.1.0'
    s.summary      = 'iOS 路由解析'
    s.homepage     = 'https://github.com/ZengyiMa/DLRouter'
    s.license      = 'MIT'
    s.authors      = {'MaZengyi' => 'semazengyi@gmail.com'}
    s.platform     = :ios, '6.0'
    s.source       = {:git => 'https://github.com/ZengyiMa/DLRouter.git', :tag => s.version}
    s.source_files = 'DLRouter/DLRouter/*.{h,m}'
    s.requires_arc = true

end
