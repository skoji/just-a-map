MIN_OS=17.0
xcrun actool Resources/source/Assets.xcassets \
      --compile Resources/built \
      --platform iphoneos \
      --app-icon AppIcon \
      --minimum-deployment-target $MIN_OS \
      --enable-on-demand-resources NO 
