# Compilar TDLib para Android (solo si necesitas recompilar `libtdjson.so`)

La app usa `libtdjson.so`, que **no está en Git**: se descarga desde la Release del repositorio con `tools/fetch_tdlib.ps1`. Para compilar la app no necesitas recompilar TDLib.

Versión usada: **TDLib 1.8.69** y **OpenSSL 3.6.5**, para Android arm64, API 24.

## Requisitos (en WSL Ubuntu)

- WSL Ubuntu con `git`, `cmake`, `ninja-build` y `g++`.
- Android NDK **r28c** (Linux x86_64).

Un NDK de Windows no sirve: los binarios son para Windows.

## Variables

Los scripts usan estas variables, con valores por defecto:

| Variable | Por defecto | Qué es |
|---|---|---|
| `TDLIB_ROOT` | `$HOME` | Carpeta donde se crean `openssl-src`, `openssl-android`, `td` y `td-android` |
| `NDK` | `$TDLIB_ROOT/android-ndk/android-ndk-r28c` | Carpeta del NDK |

Si usas otro usuario o ruta, exporta las variables antes de ejecutar:

```bash
export TDLIB_ROOT="$HOME"
export NDK="$HOME/android-ndk/android-ndk-r28c"
```

## Pasos

Ejecuta todo dentro de WSL, desde la carpeta `tools/tdlib` del proyecto (en WSL: `/mnt/d/proy/drive/tools/tdlib`).

```bash
# 1. Compilar OpenSSL para Android
bash build_openssl_android.sh

# 2. Obtener el código de TDLib
git clone --depth 1 --branch v1.8.69 https://github.com/tdlib/td.git "$HOME/td"

# 3. Compilar TDLib (libtdjson.so)
cd "$HOME/td" && bash /mnt/d/proy/drive/tools/tdlib/build_tdlib_android.sh

# 4. Verificar funciones y crear la versión sin símbolos
bash /mnt/d/proy/drive/tools/tdlib/verify_tdjson.sh
```

El resultado queda en `$TDLIB_ROOT/libtdjson-arm64.so`. Para usarlo en la app, cópialo a:

```
app/android/app/src/main/jniLibs/arm64-v8a/libtdjson.so
```

Revisa que `verify_tdjson.sh` liste las funciones `td_json_client_*`. Si no aparecen, la compilación falló: revisa `$TDLIB_ROOT/android-build.log`.

## Publicar el binario nuevo

El `.so` se publica como asset de una Release, no en el código. Tag sugerido: `tdlib-1.8.69`.

## Problemas conocidos

- **OpenSSL no encontrado por CMake:** los scripts ya pasan las rutas de OpenSSL.
- **Un NDK de Windows:** usa el de Linux dentro de WSL.
- **Primera descarga del NDK incompleta:** bórrala y vuelve a descargarla.
