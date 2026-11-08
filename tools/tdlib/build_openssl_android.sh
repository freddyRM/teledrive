# Configuracion: TDLIB_ROOT (por defecto $HOME) y NDK se pueden cambiar con variables de entorno.
ROOT="${TDLIB_ROOT:-$HOME}"
NDK="${NDK:-$ROOT/android-ndk/android-ndk-r28c}"
#!/bin/bash
set -e
export ANDROID_NDK_ROOT=$NDK
export PATH=$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH

if [ ! -d $ROOT/openssl-src ]; then
  git clone --depth 1 --branch openssl-3.6.5 https://github.com/openssl/openssl.git $ROOT/openssl-src
fi
cd $ROOT/openssl-src
make distclean >/dev/null 2>&1 || true
./Configure android-arm64 -D__ANDROID_API__=24 --prefix=$ROOT/openssl-android no-shared no-tests > $ROOT/openssl-config.log 2>&1
echo "openssl_config_exit=$?"
make -j"$(nproc)" build_libs > $ROOT/openssl-build.log 2>&1
echo "openssl_build_exit=$?"
make install_dev > $ROOT/openssl-install.log 2>&1
echo "openssl_install_exit=$?"
ls -la $ROOT/openssl-android/lib | head
