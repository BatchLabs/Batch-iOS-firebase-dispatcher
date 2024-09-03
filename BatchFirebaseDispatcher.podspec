Pod::Spec.new do |s|
  s.name             = 'BatchFirebaseDispatcher'
  s.version          = '3.1.0'
  s.summary          = 'Batch.com Events Dispatcher Firebase implementation.'

  s.description      = <<-DESC
  A ready-to-go event dispatcher for Firebase. Requires the Batch iOS SDK.
                       DESC

  s.homepage         = 'https://batch.com'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Batch.com' => 'support@batch.com' }
  s.source           = { :git => 'https://github.com/BatchLabs/Batch-iOS-firebase-dispatcher.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.platforms = {
    "ios" => "10.0"
  }

  s.requires_arc = true
  s.static_framework = true
  
  s.dependency 'Batch', '>= 1.19'
  s.dependency 'Firebase/Analytics'
  
  s.source_files = 'BatchFirebaseDispatcher/Classes/**/*'
end
