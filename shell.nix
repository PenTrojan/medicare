{ pkgs ? import <nixpkgs> { config.allowUnfree = true; config.android_sdk.accept_license = true;} }:

let
  # Compose the precise Android SDK requirements dynamically
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    buildToolsVersions = [ "35.0.0" "34.0.0" "30.0.3" ];
    platformVersions = [ "36" "34" "33" ];
    abiVersions = [ "x86_64" ];
    includeEmulator = true;
    
    includeNDK = true;
    ndkVersions = [ "28.2.13676358" ];
    cmakeVersions = [ "3.22.1" ];
  };
  androidSdk = androidComposition.androidsdk;
in
# --- CHANGED FROM buildFHSUserEnv TO buildFHSEnv ---
(pkgs.buildFHSEnv {
  name = "flutter-development-environment";
  
  targetPkgs = pkgs: with pkgs; [
    flutter
    jdk17
    androidSdk
    pkg-config
    gtk3
    firebase-tools
    nodejs_22
    git
    glibc
    zlib
    libx11
    stdenv.cc.cc.lib  
  ];

  profile = ''
    export ANDROID_HOME="${androidSdk}/libexec/android-sdk"
    export ANDROID_SDK_ROOT="${androidSdk}/libexec/android-sdk"
    export JAVA_HOME="${pkgs.jdk17.home}"
        
    export GRADLE_USER_HOME="$PWD/.gradle_home"
    export PUB_CACHE="$PWD/.pub_cache"

    echo "🔨 Building writable local Flutter SDK overlay..."
    MOCK_FLUTTER="$PWD/.gradle_home/mock_flutter"
    rm -rf "$MOCK_FLUTTER"
    mkdir -p "$MOCK_FLUTTER"

    ln -s ${pkgs.flutter}/* "$MOCK_FLUTTER/"
    rm -f "$MOCK_FLUTTER/packages"
    mkdir -p "$MOCK_FLUTTER/packages"
    ln -s ${pkgs.flutter}/packages/* "$MOCK_FLUTTER/packages/"
    
    rm -f "$MOCK_FLUTTER/packages/flutter_tools"
    mkdir -p "$MOCK_FLUTTER/packages/flutter_tools"
    ln -s ${pkgs.flutter}/packages/flutter_tools/* "$MOCK_FLUTTER/packages/flutter_tools/"
    
    rm -f "$MOCK_FLUTTER/packages/flutter_tools/gradle"
    cp -r ${pkgs.flutter}/packages/flutter_tools/gradle "$MOCK_FLUTTER/packages/flutter_tools/gradle"
    chmod -R +w "$MOCK_FLUTTER/packages/flutter_tools/gradle"

    export FLUTTER_ROOT="$MOCK_FLUTTER"

    echo "⚡ Welcome ravenousbyte. FHS Flutter dev environment is active! ⚡"
  '';
}).env
