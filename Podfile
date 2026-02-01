# Uncomment the next line to define a global platform for your project
platform :ios, '15.0'

target 'sling-test-app-2' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # KMP Shared Framework
  # After running './gradlew :shared:linkDebugFrameworkIosArm64' (or IosSimulatorArm64 for simulator)
  # the framework will be available at:
  # shared/build/bin/iosArm64/debugFramework/Shared.framework (device)
  # shared/build/bin/iosSimulatorArm64/debugFramework/Shared.framework (simulator)
  
  # For development, we'll use a local podspec
  pod 'Shared', :path => './shared'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end
