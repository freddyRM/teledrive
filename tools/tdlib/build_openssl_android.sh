#!/bin/bash
set -e
NDK=/root/android-ndk/android-ndk-r28c
export ANDROID_NDK_ROOT=$NDK
export PATH=$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH

if [ ! -d /root/openssl-src ]; then
  git clone --depth 1 --branch openssl-3.6.5 https://github.com/openssl/openssl.git /root/openssl-src
fi
cd /root/openssl-src
make distclean >/dev/null 2>&1 || true
./Configure android-arm64 -D__ANDROID_API__=24 --prefix=/root/openssl-android no-shared no-tests > /root/openssl-config.log 2>&1
echo "openssl_config_exit=$?"
make -j"$(nproc)" build_libs > /root/openssl-build.log 2>&1
echo "openssl_build_exit=$?"
make install_dev > /root/openssl-install.log 2>&1
echo "openssl_install_exit=$?"
ls -la /root/openssl-android/lib | head
