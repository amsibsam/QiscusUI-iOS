# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

def pod_release
    pod 'QiscusCore', :path => '../QiscusCore'
    pod 'QiscusRealtime', :git => 'https://github.com/qiscus/QiscusRealtime-iOS.git'
end

def pod_dev
    pod 'QiscusCore', :path => '../QiscusCore'
    pod 'QiscusRealtime', :path => '../QiscusRealtime'
end

target 'Example' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  pod 'QiscusUI', :path => '.'
#  pod_release
  pod_dev
end


