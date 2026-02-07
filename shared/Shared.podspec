Pod::Spec.new do |spec|
  spec.name                     = 'Shared'
  spec.version                  = '1.0.0'
  spec.homepage                 = 'https://github.com/example/sling'
  spec.source                   = { :http => '' }
  spec.authors                  = ''
  spec.license                  = ''
  spec.summary                  = 'Sling shared KMP module'
  spec.vendored_frameworks      = 'build/cocoapods/framework/Shared.framework'
  spec.libraries                = 'c++'
  spec.ios.deployment_target    = '15.0'
  spec.pod_target_xcconfig      = {
    'KOTLIN_PROJECT_PATH' => ':shared',
    'PRODUCT_MODULE_NAME' => 'Shared',
  }
  
  # Script phase to build the framework
  spec.script_phases = [
    {
      :name => 'Build Shared',
      :execution_position => :before_compile,
      :shell_path => '/bin/sh',
      :script => <<-SCRIPT
        if [ "YES" = "$OVERRIDE_KOTLIN_BUILD_IDE_SUPPORTED" ]; then
          echo "Skipping Gradle build task invocation due to OVERRIDE_KOTLIN_BUILD_IDE_SUPPORTED environment variable set to YES"
          exit 0
        fi
        set -ev
        REPO_ROOT="$PODS_TARGET_SRCROOT"
        "$REPO_ROOT/../gradlew" -p "$REPO_ROOT/.." :shared:embedAndSignAppleFrameworkForXcode
      SCRIPT
    }
  ]
end
