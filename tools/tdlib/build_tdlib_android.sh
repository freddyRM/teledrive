# Configuracion: TDLIB_ROOT (por defecto $HOME) y NDK se pueden cambiar con variables de entorno.
ROOT="${TDLIB_ROOT:-$HOME}"
NDK="${NDK:-$ROOT/android-ndk/android-ndk-r28c}"
#!/bin/bash
set -e
cd $ROOT/td
rm -rf build-android
mkdir build-android
cd build-android
cmake -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=$NDK/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-24 \
  -DANDROID_STL=c++_static \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX:PATH=$ROOT/td-android \
  -DTD_ENABLE_JNI=OFF \
  -DTD_GENERATE_SOURCE_FILES=OFF \
  -DOPENSSL_ROOT_DIR=$ROOT/openssl-android \
  -DOPENSSL_USE_STATIC_LIBS=ON \
  -DOPENSSL_INCLUDE_DIR=$ROOT/openssl-android/include \
  -DOPENSSL_CRYPTO_LIBRARY=$ROOT/openssl-android/lib/libcrypto.a \
  -DOPENSSL_SSL_LIBRARY=$ROOT/openssl-android/lib/libssl.a \
  .. > $ROOT/android-config.log 2>&1
echo "config_exit=$?"
ninja -j"$(nproc)" tdjson > $ROOT/android-build.log 2>&1
echo "build_exit=$?"
find $ROOT/td/build-android -name 'libtdjson*.so' -exec ls -la {} \;
