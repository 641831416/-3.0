#!/bin/bash

set -e

echo "创建修复版 IPTV Android 应用"

rm -rf IPTVApp
mkdir -p IPTVApp
cd IPTVApp

echo "正在创建修复版项目..."

# 创建基础配置文件
cat > settings.gradle << 'EOF'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "IPTVApp"
include ':app'
EOF

cat > build.gradle << 'EOF'
plugins {
    id 'com.android.application' version '8.0.2' apply false
    id 'com.android.library' version '8.0.2' apply false
}
task clean(type: Delete) {
    delete rootProject.buildDir
}
EOF

cat > gradle.properties << 'EOF'
org.gradle.jvmargs=-Xmx2048m
android.useAndroidX=true
android.enableJetifier=true
EOF

mkdir -p gradle/wrapper

cat > gradle/wrapper/gradle-wrapper.properties << 'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.0-all.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

# 简化的gradlew脚本
cat > gradlew << 'EOF'
#!/bin/sh
exec java -cp "gradle/wrapper/gradle-wrapper.jar" org.gradle.wrapper.GradleWrapperMain "$@"
EOF

mkdir -p app/src/main/java/com/iptv/app
mkdir -p app/src/main/res/layout
mkdir -p app/src/main/res/values
mkdir -p app/src/main/res/drawable

# 修复的app构建配置
cat > app/build.gradle << 'EOF'
plugins {
    id 'com.android.application'
}

android {
    namespace 'com.iptv.app'
    compileSdk 33

    defaultConfig {
        applicationId "com.iptv.app"
        minSdk 21
        targetSdk 33
        versionCode 1
        versionName "1.0"
    }

    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
    
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
    
    buildFeatures {
        viewBinding true
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.9.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'androidx.recyclerview:recyclerview:1.3.1'
    implementation 'androidx.swiperefreshlayout:swiperefreshlayout:1.1.0'
}
EOF

cat > app/src/main/AndroidManifest.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:theme="@style/Theme.IPTVApp">
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF

# 创建主Activity（简化版本）
cat > app/src/main/java/com/iptv/app/MainActivity.java << 'EOF'
package com.iptv.app;

import android.os.Bundle;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;

public class MainActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        
        setupToolbar();
        setupChannelList();
    }
    
    private void setupToolbar() {
        Toolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        if (getSupportActionBar() != null) {
            getSupportActionBar().setTitle(R.string.app_name);
        }
    }
    
    private void setupChannelList() {
        TextView channelInfo = findViewById(R.id.channel_info);
        StringBuilder info = new StringBuilder();
        info.append("IPTV电视直播应用\n\n");
        info.append("功能特性:\n");
        info.append("• 自定义频道管理\n");
        info.append("• EPG电子节目指南\n");
        info.append("• 多种源获取方式\n");
        info.append("• IPv4/IPv6双栈支持\n");
        info.append("• 归属地与运营商显示\n");
        info.append("• TVBox等播放器兼容\n\n");
        info.append("数据源: https://github.com/641831416/my-iptv-api");
        
        channelInfo.setText(info.toString());
    }
}
EOF

# 创建资源文件
cat > app/src/main/res/values/strings.xml << 'EOF'
<resources>
    <string name="app_name">IPTV直播</string>
</resources>
EOF

cat > app/src/main/res/values/themes.xml << 'EOF'
<resources>
    <style name="Theme.IPTVApp" parent="Theme.Material3.DayNight">
        <item name="colorPrimary">#FF6200EE</item>
        <ite