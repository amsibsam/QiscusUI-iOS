# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

target 'example' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
    pod 'QiscusUI', :path => '.'

end

target 'QiscusUI' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  pod 'QiscusCore', :path => '../QiscusCore/'
  pod 'AlamofireImage'
  pod 'SwiftyJSON'
  
  target 'QiscusUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end
