name: Build IPTV APK

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Run IPTV script
      run: chmod +x iptv.sh && ./iptv.sh
      
    - name: Set up JDK 17
      uses: actions/setup-java@v4
      with:
        java-version: '17'
        distribution: 'temurin'
        
    - name: Setup Android SDK
      uses: android-actions/setup-android@v3
      
    - name: Download Gradle Wrapper JAR
      run: |
        cd IPTVApp
        curl -L -o gradle/wrapper/gradle-wrapper.jar \
        https://github.com/gradle/gradle/raw/master/gradle/wrapper/gradle-wrapper.jar
      
    - name: Build APK
      run: |
        cd IPTVApp
        ./gradlew assembleDebug --no-daemon
      
    - name: Upload APK
      uses: actions/upload-artifact@v4
      with:
        name: iptv-app
        path: IPTVApp/app/build/outputs/apk/debug/app-debug.apk