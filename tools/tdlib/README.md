# Compilar TDLib para Android (solo si necesitas recompilar `libtdjson.so`)

La app ya trae el binario `app/android/app/src/main/jniLibs/arm64-v8a/libtdjson.so`. **Solo necesitas esta guía si quieres regenerarlo.** Para compilar la app no hace falta.

Versión usada: **TDLib 1.8.69** y **OpenSSL 3.6.5**, para Android arm64, API 24.

## Requisitos (en WSL Ubuntu)

- WSL Ubuntu con `git`, `cmake`, `ninja-build` y `g++`.
- Android NDK **r28c** (Linux x86_64), descomprimido en `/root/android-ndk/android-ndk-r28c`.

Un NDK de Windows no sirve: los binarios son para Windows.

## Pasos

Ejecuta todo dentro de WSL. Los scripts asumen las rutas de `/root`.

```bash
# 1. Compilar OpenSSL para Android
bash build_openssl_android.sh

# 2. Obtener el código de TDLib
git clone --depth 1 --branch v1.8.69 https://github.com/tdlib/td.git /root/td

# 3. Compilar TDLib (libtdjson.so)
cd /root/td && bash /ruta/a/tools/tdlib/build_tdlib_android.sh

# 4. Verificar funciones y crear la versión sin símbolos
bash /ruta/a/tools/tdlib/verify_tdjson.sh
```

El resultado queda en `/root/libtdjson-arm64.so`. Cópialo a:

```
app/android/app/src/main/jniLibs/arm64-v8a/libtdjson.so
```

Revisa que `verify_tdjson.sh` liste las funciones `td_json_client_*`. Si no aparecen, la compilación falló: revisa `/root/android-build.log`.

## Problemas conocidos

- **OpenSSL no encontrado por CMake:** pasa las rutas de OpenSSL explícitamente (ya están en el script).
- **Un NDK de Windows:** usa el de Linux dentro de WSL.
- **Primera descarga del NDK incompleta:** bórrala y vuelve a descargarla.
