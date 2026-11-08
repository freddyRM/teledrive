#!/bin/bash
set -e
NDK=/root/android-ndk/android-ndk-r28c
cd /root/td
rm -rf build-android
mkdir build-android
cd build-android
cmake -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=$NDK/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-24 \
  -DANDROID_STL=c++_static \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX:PATH=/root/td-android \
  -DTD_ENABLE_JNI=OFF \
  -DTD_GENERATE_SOURCE_FILES=OFF \
  -DOPENSSL_ROOT_DIR=/root/openssl-android \
  -DOPENSSL_USE_STATIC_LIBS=ON \
  -DOPENSSL_INCLUDE_DIR=/root/openssl-android/include \
  -DOPENSSL_CRYPTO_LIBRARY=/root/openssl-android/lib/libcrypto.a \
  -DOPENSSL_SSL_LIBRARY=/root/openssl-android/lib/libssl.a \
  .. > /root/android-config.log 2>&1
echo "config_exit=$?"
ninja -j"$(nproc)" tdjson > /root/android-build.log 2>&1
echo "build_exit=$?"
find /root/td/build-android -name 'libtdjson*.so' -exec ls -la {} \;
