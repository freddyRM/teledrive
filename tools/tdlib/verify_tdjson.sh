#!/bin/bash
NDKBIN=/root/android-ndk/android-ndk-r28c/toolchains/llvm/prebuilt/linux-x86_64/bin
F=/root/td/build-android/libtdjson.so
file "$F" | cut -c1-160
echo "--- exported td_json_client symbols:"
"$NDKBIN/llvm-nm" -D --defined-only "$F" | grep " td_json_client_"
"$NDKBIN/llvm-strip" --strip-unneeded -o /root/libtdjson-arm64.so "$F"
ls -la /root/libtdjson-arm64.so
