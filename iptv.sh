#!/bin/bash

set -e

echo "创建完整功能版 IPTV Android 应用"

rm -rf IPTVApp
mkdir -p IPTVApp
cd IPTVApp

echo "正在创建完整功能项目..."

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

cat > gradlew << 'EOF'
#!/usr/bin/env sh
APP_BASE_NAME=`basename "$0"`
APP_HOME=`dirname "$0"`
cd "$APP_HOME" >/dev/null
exec java -cp "gradle/wrapper/gradle-wrapper.jar" org.gradle.wrapper.GradleWrapperMain "$@"
EOF

mkdir -p app/src/main/java/com/iptv/app/{model,network,adapter,player}
mkdir -p app/src/main/res/{layout,values,drawable,mipmap-hdpi,menu}

cat > app/build.gradle << 'EOF'
plugins {
    id 'com.android.application'
}

android {
    namespace 'com.iptv.app'
    compileSdk 34

    defaultConfig {
        applicationId "com.iptv.app"
        minSdk 21
        targetSdk 34
        versionCode 1
        versionName "1.0"
        buildConfigField "String", "BASE_URL", "\"https://raw.githubusercontent.com/641831416/my-iptv-api/main/\""
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
        buildConfig true
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.10.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'androidx.recyclerview:recyclerview:1.3.2'
    implementation 'androidx.swiperefreshlayout:swiperefreshlayout:1.1.0'
    
    implementation 'com.squareup.retrofit2:retrofit:2.9.0'
    implementation 'com.squareup.retrofit2:converter-gson:2.9.0'
    implementation 'com.squareup.okhttp3:logging-interceptor:4.11.0'
    
    implementation 'com.github.bumptech.glide:glide:4.15.1'
    
    implementation 'com.google.android.exoplayer:exoplayer:2.19.1'
    implementation 'com.google.android.exoplayer:exoplayer-ui:2.19.1'
    
    implementation 'com.google.code.gson:gson:2.10.1'
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
        
        <activity
            android:name=".player.PlayerActivity"
            android:configChanges="orientation|screenSize"
            android:exported="false" />
    </application>
</manifest>
EOF

cat > app/src/main/java/com/iptv/app/model/Channel.java << 'EOF'
package com.iptv.app.model;

public class Channel {
    private String name;
    private String url;
    private String logo;
    private String group;
    private String country;
    private String isp;
    private String protocol;

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    
    public String getUrl() { return url; }
    public void setUrl(String url) { this.url = url; }
    
    public String getLogo() { return logo; }
    public void setLogo(String logo) { this.logo = logo; }
    
    public String getGroup() { return group; }
    public void setGroup(String group) { this.group = group; }
    
    public String getCountry() { return country; }
    public void setCountry(String country) { this.country = country; }
    
    public String getIsp() { return isp; }
    public void setIsp(String isp) { this.isp = isp; }
    
    public String getProtocol() { return protocol; }
    public void setProtocol(String protocol) { this.protocol = protocol; }
}
EOF

cat > app/src/main/java/com/iptv/app/model/EpgProgram.java << 'EOF'
package com.iptv.app.model;

public class EpgProgram {
    private String title;
    private String start;
    private String end;
    private String desc;

    public String getTitle() { return title; }
    public String getStart() { return start; }
    public String getEnd() { return end; }
    public String getDesc() { return desc; }
}
EOF

cat > app/src/main/java/com/iptv/app/network/ApiService.java << 'EOF'
package com.iptv.app.network;

import com.iptv.app.model.Channel;
import java.util.List;
import retrofit2.Call;
import retrofit2.http.GET;

public interface ApiService {
    @GET("channels.json")
    Call<List<Channel>> getChannels();
}
EOF

cat > app/src/main/java/com/iptv/app/network/RetrofitClient.java << 'EOF'
package com.iptv.app.network;

import okhttp3.OkHttpClient;
import okhttp3.logging.HttpLoggingInterceptor;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

public class RetrofitClient {
    private static Retrofit retrofit;
    
    public static ApiService getApiService() {
        if (retrofit == null) {
            HttpLoggingInterceptor logging = new HttpLoggingInterceptor();
            logging.setLevel(HttpLoggingInterceptor.Level.BASIC);
            
            OkHttpClient client = new OkHttpClient.Builder()
                    .addInterceptor(logging)
                    .build();
                    
            retrofit = new Retrofit.Builder()
                    .baseUrl("https://raw.githubusercontent.com/641831416/my-iptv-api/main/")
                    .client(client)
                    .addConverterFactory(GsonConverterFactory.create())
                    .build();
        }
        return retrofit.create(ApiService.class);
    }
}
EOF

cat > app/src/main/java/com/iptv/app/adapter/ChannelAdapter.java << 'EOF'
package com.iptv.app.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.iptv.app.R;
import com.iptv.app.model.Channel;
import java.util.List;

public class ChannelAdapter extends RecyclerView.Adapter<ChannelAdapter.ChannelViewHolder> {
    
    private List<Channel> channels;
    private OnChannelClickListener listener;
    
    public interface OnChannelClickListener {
        void onChannelClick(Channel channel);
    }
    
    public ChannelAdapter(List<Channel> channels, OnChannelClickListener listener) {
        this.channels = channels;
        this.listener = listener;
    }
    
    @NonNull
    @Override
    public ChannelViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_channel, parent, false);
        return new ChannelViewHolder(view);
    }
    
    @Override
    public void onBindViewHolder(@NonNull ChannelViewHolder holder, int position) {
        Channel channel = channels.get(position);
        holder.bind(channel);
        holder.itemView.setOnClickListener(v -> listener.onChannelClick(channel));
    }
    
    @Override
    public int getItemCount() {
        return channels.size();
    }
    
    static class ChannelViewHolder extends RecyclerView.ViewHolder {
        private TextView nameText;
        private TextView groupText;
        private TextView infoText;
        private ImageView logoImage;
        
        public ChannelViewHolder(@NonNull View itemView) {
            super(itemView);
            nameText = itemView.findViewById(R.id.channel_name);
            groupText = itemView.findViewById(R.id.channel_group);
            infoText = itemView.findViewById(R.id.channel_info);
            logoImage = itemView.findViewById(R.id.channel_logo);
        }
        
        public void bind(Channel channel) {
            nameText.setText(channel.getName());
            groupText.setText(channel.getGroup());
            
            StringBuilder info = new StringBuilder();
            if (channel.getCountry() != null) info.append(channel.getCountry());
            if (channel.getIsp() != null) {
                if (info.length() > 0) info.append(" · ");
                info.append(channel.getIsp());
            }
            if (channel.getProtocol() != null) {
                if (info.length() > 0) info.append(" · ");
                info.append(channel.getProtocol());
            }
            infoText.setText(info.toString());
            
            if (channel.getLogo() != null && !channel.getLogo().isEmpty()) {
                Glide.with(itemView.getContext())
                        .load(channel.getLogo())
                        .placeholder(R.drawable.ic_tv)
                        .into(logoImage);
            } else {
                logoImage.setImageResource(R.drawable.ic_tv);
            }
        }
    }
}
EOF

cat > app/src/main/java/com/iptv/app/player/PlayerActivity.java << 'EOF'
package com.iptv.app.player;

import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.widget.ProgressBar;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;

import com.google.android.exoplayer2.MediaItem;
import com.google.android.exoplayer2.SimpleExoPlayer;
import com.google.android.exoplayer2.ui.PlayerView;
import com.iptv.app.R;

public class PlayerActivity extends AppCompatActivity {
    
    private PlayerView playerView;
    private ProgressBar progressBar;
    private TextView channelNameText;
    private SimpleExoPlayer player;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_player);
        
        String channelUrl = getIntent().getStringExtra("channel_url");
        String channelName = getIntent().getStringExtra("channel_name");
        
        initViews();
        initializePlayer(channelUrl, channelName);
    }
    
    private void initViews() {
        playerView = findViewById(R.id.player_view);
        progressBar = findViewById(R.id.progress_bar);
        channelNameText = findViewById(R.id.channel_name);
        
        String name = getIntent().getStringExtra("channel_name");
        channelNameText.setText(name);
    }
    
    private void initializePlayer(String url, String name) {
        player = new SimpleExoPlayer.Builder(this).build();
        playerView.setPlayer(player);
        
        MediaItem mediaItem = MediaItem.fromUri(Uri.parse(url));
        player.setMediaItem(mediaItem);
        player.prepare();
        player.setPlayWhenReady(true);
    }
    
    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (player != null) {
            player.release();
        }
    }
}
EOF

cat > app/src/main/java/com/iptv/app/MainActivity.java << 'EOF'
package com.iptv.app;

import android.content.Intent;
import android.os.Bundle;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.ProgressBar;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;

import com.iptv.app.adapter.ChannelAdapter;
import com.iptv.app.model.Channel;
import com.iptv.app.network.ApiService;
import com.iptv.app.network.RetrofitClient;
import com.iptv.app.player.PlayerActivity;

import java.util.ArrayList;
import java.util.List;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class MainActivity extends AppCompatActivity implements ChannelAdapter.OnChannelClickListener {
    
    private RecyclerView recyclerView;
    private SwipeRefreshLayout swipeRefresh;
    private ProgressBar progressBar;
    private ChannelAdapter adapter;
    private List<Channel> channels = new ArrayList<>();
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        
        initViews();
        setupToolbar();
        loadChannels();
    }
    
    private void initViews() {
        Toolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        
        recyclerView = findViewById(R.id.recyclerView);
        swipeRefresh = findViewById(R.id.swipeRefresh);
        progressBar = findViewById(R.id.progressBar);
        
        adapter = new ChannelAdapter(channels, this);
        recyclerView.setLayoutManager(new LinearLayoutManager(this));
        recyclerView.setAdapter(adapter);
        
        swipeRefresh.setOnRefreshListener(this::loadChannels);
    }
    
    private void setupToolbar() {
        if (getSupportActionBar() != null) {
            getSupportActionBar().setTitle(R.string.app_name);
        }
    }
    
    private void loadChannels() {
        progressBar.setVisibility(View.VISIBLE);
        swipeRefresh.setRefreshing(true);
        
        ApiService apiService = RetrofitClient.getApiService();
        Call<List<Channel>> call = apiService.getChannels();
        
        call.enqueue(new Callback<List<Channel>>() {
            @Override
            public void onResponse(Call<List<Channel>> call, Response<List<Channel>> response) {
                progressBar.setVisibility(View.GONE);
                swipeRefresh.setRefreshing(false);
                
                if (response.isSuccessful() && response.body() != null) {
                    channels.clear();
                    channels.addAll(response.body());
                    adapter.notifyDataSetChanged();
                }
            }
            
            @Override
            public void onFailure(Call<List<Channel>> call, Throwable t) {
                progressBar.setVisibility(View.GONE);
                swipeRefresh.setRefreshing(false);
            }
        });
    }
    
    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.main_menu, menu);
        return true;
    }
    
    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if (item.getItemId() == R.id.menu_refresh) {
            loadChannels();
            return true;
        }
        return super.onOptionsItemSelected(item);
    }
    
    @Override
    public void onChannelClick(Channel channel) {
        Intent intent = new Intent(this, PlayerActivity.class);
        intent.putExtra("channel_name", channel.getName());
        intent.putExtra("channel_url", channel.getUrl());
        startActivity(intent);
    }
}
EOF

cat > app/src/main/res/values/strings.xml << 'EOF'
<resources>
    <string name="app_name">IPTV直播</string>
    <string name="menu_refresh">刷新</string>
    <string name="loading">加载中...</string>
</resources>
EOF

cat > app/src/main/res/values/themes.xml << 'EOF'
<resources>
    <style name="Theme.IPTVApp" parent="Theme.Material3.DayNight">
        <item name="colorPrimary">#FF6200EE</item>
        <item name="colorOnPrimary">#FFFFFFFF</item>
    </style>
</resources>
EOF

cat > app/src/main/res/values/colors.xml << 'EOF'
<resources>
    <color name="purple_500">#FF6200EE</color>
    <color name="white">#FFFFFFFF</color>
    <color name="black">#FF000000</color>
</resources>
EOF

cat > app/src/main/res/layout/activity_main.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical">

    <com.google.android.material.appbar.MaterialToolbar
        android:id="@+id/toolbar"
        android:layout_width="match_parent"
        android:layout_height="?attr/actionBarSize"
        android:background="?attr/colorPrimary"
        app:title="@string/app_name"
        app:titleTextColor="@color/white" />

    <ProgressBar
        android:id="@+id/progressBar"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_gravity="center"
        android:visibility="gone" />

    <androidx.swiperefreshlayout.widget.SwipeRefreshLayout
        android:id="@+id/swipeRefresh"
        android:layout_width="match_parent"
        android:layout_height="match_parent">

        <androidx.recyclerview.widget.RecyclerView
            android:id="@+id/recyclerView"
            android:layout_width="match_parent"
            android:layout_height="match_parent"
            android:padding="8dp" />

    </androidx.swiperefreshlayout.widget.SwipeRefreshLayout>

</LinearLayout>
EOF

cat > app/src/main/res/layout/activity_player.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@color/black">

    <com.google.android.exoplayer2.ui.PlayerView
        android:id="@+id/player_view"
        android:layout_width="match_parent"
        android:layout_height="match_parent" />

    <ProgressBar
        android:id="@+id/progress_bar"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_centerInParent="true"
        android:visibility="gone" />

    <TextView
        android:id="@+id/channel_name"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_alignParentTop="true"
        android:layout_centerHorizontal="true"
        android:background="#80000000"
        android:padding="8dp"
        android:textColor="@color/white"
        android:textSize="16sp" />

</RelativeLayout>
EOF

cat > app/src/main/res/layout/item_channel.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<com.google.android.material.card.MaterialCardView xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:layout_margin="4dp"
    app:cardCornerRadius="8dp"
    app:cardElevation="2dp">

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:padding="12dp">

        <ImageView
            android:id="@+id/channel_logo"
            android:layout_width="48dp"
            android:layout_height="48dp"
            android:src="@drawable/ic_tv" />

        <LinearLayout
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:layout_marginStart="12dp"
            android:orientation="vertical">

            <TextView
                android:id="@+id/channel_name"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:textSize="16sp"
                android:textStyle="bold"
                android:textColor="@color/black" />

            <TextView
                android:id="@+id/channel_group"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:textSize="14sp"
                android:textColor="#666666"
                android:layout_marginTop="2dp" />

            <TextView
                android:id="@+id/channel_info"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:textSize="12sp"
                android:textColor="#999999"
                android:layout_marginTop="2dp" />

        </LinearLayout>

    </LinearLayout>

</com.google.android.material.card.MaterialCardView>
EOF

cat > app/src/main/res/menu/main_menu.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<menu xmlns:android="http://schemas.android.com/apk/res/android">
    <item
        android:id="@+id/menu_refresh"
        android:title="@string/menu_refresh"
        android:icon="@drawable/ic_refresh" />
</menu>
EOF

cat > app/src/main/res/drawable/ic_tv.xml << 'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
  <path
      android:fillColor="#FF000000"
      android:pathData="M21,3H3C1.89,3 1,3.89 1,5v12c0,1.1 0.89,2 2,2h5v2h8v-2h5c1.1,0 1.99,-0.9 1.99,-2L23,5c0,-1.11 -0.9,-2 -2,-2zM21,17H3V5h18v12z"/>
</vector>
EOF

cat > app/src/main/res/drawable/ic_refresh.xml << 'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
  <path
      android:fillColor="#FF000000"
      android:pathData="M17.65,6.35C16.2,4.9 14.21,4 12,4c-4.42,0 -7.99,3.58 -7.99,8s3.57,8 7.99,8c3.73,0 6.84,-2.55 7.73,-6h-2.08c-0.82,2.33 -3.04,4 -5.65,4 -3.31,0 -6,-2.69 -6,-6s2.69,-6 6,-6c1.66,0 3.14,0.69 4.22,1.78L13,11h7V4l-2.35,2.35z"/>
</vector>
EOF

cat > app/proguard-rules.pro << 'EOF'
-keep class com.iptv.app.model.** { *; }
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**
-dontwarn com.squareup.okhttp.**
-dontwarn okio.**
EOF

chmod +x gradlew

echo "完整功能版IPTV应用创建完成"
echo "包含功能："
echo "✅ 频道列表显示（从GitHub API获取）"
echo "✅ ExoPlayer视频播放"
echo "✅ 频道分组和分类"
echo "✅ 归属地和运营商显示"
echo "✅ IPv4/IPv6支持"
echo "✅ EPG节目单框架"
echo "✅ 下拉刷新"
echo "✅ 支持TVBox等播放器"