# Configuracion: TDLIB_ROOT (por defecto $HOME) y NDK se pueden cambiar con variables de entorno.
ROOT="${TDLIB_ROOT:-$HOME}"
NDK="${NDK:-$ROOT/android-ndk/android-ndk-r28c}"
#!/bin/bash
NDKBIN=$ROOT/android-ndk/android-ndk-r28c/toolchains/llvm/prebuilt/linux-x86_64/bin
F=$ROOT/td/build-android/libtdjson.so
file "$F" | cut -c1-160
echo "--- exported td_json_client symbols:"
"$NDKBIN/llvm-nm" -D --defined-only "$F" | grep " td_json_client_"
"$NDKBIN/llvm-strip" --strip-unneeded -o $ROOT/libtdjson-arm64.so "$F"
ls -la $ROOT/libtdjson-arm64.so
