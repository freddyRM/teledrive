# Resumen del proyecto: Drive Personal (Telegram como nube)

## Objetivo
App personal tipo Google Fotos + Drive para Android (y Windows después), que usa un **supergrupo privado de Telegram** como almacenamiento. Todo se cifra en el teléfono antes de subir. Solo el usuario debe poder ver el contenido.

## Entorno
- PC: Windows 11, proyecto en `D:\proy\drive`. App Flutter en `D:\proy\drive\app`.
- Flutter 3.47.9 (stable) en `D:\dev\flutter`.
- Teléfono: NX789J, Android 16, depuración USB. ID de dispositivo `912505710075`.
- WSL Ubuntu 26.04 en `D:\Programs\WSL\Ubuntu`. Dentro: CMake, Ninja, g++, NDK Android r28c, OpenSSL 3.6.5 para Android y TDLib compilado.
- `libtdjson.so` (arm64, 33 MB) copiado a `app\android\app\src\main\jniLibs\arm64-v8a\`.
- `.env` en `D:\proy\drive\app`: `TG_API_ID`, `TG_API_HASH`, `TG_CHANNEL_ID` (ID del supergrupo). La frase maestra no va en `.env`: se configura dentro de la app. **El `api_hash` se mostró en el chat: conviene regenerarlo.**
- Build de prueba: `flutter build apk --debug` con `--dart-define` de TG_API_ID, TG_API_HASH y TG_CHANNEL_ID tomados de `.env` (no se escriben en el chat).

## Cuenta de Telegram
- Cuenta personal del usuario. Sesión de la app: "drivepersonal" (se puede cerrar desde Telegram > Ajustes > Dispositivos).
- Límite gratuito: 2 GB por archivo (lo probamos con 1.5 GB).

## Lo que ya funciona (verificado)
- Inicio y cierre de sesión con TDLib (código y contraseña de dos pasos).
- Subida de 1.5 GB al supergrupo: 154 s, 9.74 MB/s. Descarga real del mismo archivo: 144 s, y el SHA-256 coincide.
- Cifrado en el teléfono (`lib/core/crypto/vault_cipher.dart`): AES-256-GCM por bloques de 1 MB, clave con Argon2id, con verificación de manipulación y truncado.
- Metadatos cifrados: el nombre, tipo y tamaño van en la descripción del mensaje con prefijo `DRV1:`. En Telegram solo se ven nombres aleatorios `.bin` y el texto cifrado.
- **Drive** (`lib/features/drive/archivos_page.dart`): lista los archivos del supergrupo con nombre descifrado, tamaño y fecha. Selección múltiple y borrado con confirmación. Botón para subir el archivo de prueba cifrado.
- **Fotos** (`lib/features/gallery/gallery_page.dart`): muestra todo el contenido del teléfono (fotos y videos), ordenado de lo más nuevo a lo más viejo, leyendo todas las páginas (~2661 elementos).
- **Previsualizador** (`preview_page.dart`): desliza entre fotos con contador. Los videos se reproducen (probado: el cuadro cambia; tocar pausa o reanuda).
- **Álbumes** (`albums_page.dart`, `album_detail_page.dart`): lista de álbumes con portada, cantidad y estado de respaldo; al abrir uno se ve su cuadrícula.
- **Copias de seguridad** (`lib/features/settings/backup_page.dart`): eliges álbumes y "Subir pendientes" sube todas las fotos pendientes, cifradas, una por una. Se usa para Camera (67+ elementos). Subieron varias; las últimas filas no se confirmaron.
- **Insignias:** nube azul = registrada como subida; reloj = pendiente (solo en álbumes elegidos).
- **Actualización en vivo:** las insignias de Fotos y Álbumes se actualizan al terminar cada subida (instalada en la última versión).
- **Ajustes:** frase maestra (guardada en almacenamiento local de la app, temporal para pruebas), copias de seguridad, cerrar sesión, pruebas de subida/descarga/borrado.

## Decisiones de diseño acordadas
- Fotos y Álbumes muestran **todo** el contenido del teléfono. Ajustes decide qué se sincroniza, y solo lo elegido recibe estado.
- Drive es solo para archivos (zip, PDF, documentos), no para fotos ni videos. Desde ahí se suben y descargan archivos.
- Previsualizador a pantalla completa con deslizamiento entre fotos y reproductor de video.
- **Red:** por defecto solo Wi-Fi. Opción de datos móviles o de ambos. Sin Wi-Fi, las fotos quedan en cola. Pendiente de implementar (ver memoria `project_sync_network_policy`).
- Estado "solo en la nube" (quitada del teléfono pero en el grupo) para fotos que ya no están en el teléfono. Pendiente de diseñar.

## Problemas conocidos / pendientes
1. **Foto marcada con nube que no está en el grupo.** Las insignias salen de un registro local en el teléfono, no se comparan con el grupo. Hay que verificar contra el grupo y guardar el ID del mensaje de cada foto subida.
2. **Final del álbum Camera:** falta confirmar que todas las fotos pendientes se subieron.
3. **Subida automática:** hoy se sube con botón; no hay cola en segundo plano.
4. **Frase maestra:** guardada sin protección en el almacenamiento de la app. Pasar al almacén seguro de Android antes de usar archivos reales.
5. **Drive con carpetas del teléfono:** pendiente el selector de carpetas (SAF) para subir zip, PDF, etc.
6. **Álbum "Descargas" y carpetas:** pendiente incluirlas en Álbumes.
7. **Archivos de prueba:** quedan `prueba_2mb.bin` en `/sdcard/Android/data/com.personal.drive_personal/files/` y copias en `tdlib_files/` del teléfono; la carpeta `D:\proy\drive\pruebas\` en la PC.
8. **Interfaz:** definir un diseño juvenil y amigable (tarjetas, colores vivos, animaciones suaves), manteniendo claridad.
9. **Descarga desde Telegram en Fotos:** hoy las fotos de la nube solo se ven si están en el teléfono.

## Preferencias del usuario
- Responder en español, de forma clara y directa.
- **No subir ni borrar nada en Telegram sin confirmación explícita para cada corrida.** No repetir subidas de prueba a sus grupos reales (ver memoria `feedback_telegram_test_uploads`).
- Pidió un paso a la vez y confirmar antes de cambios grandes en su grupo.
- Quiere que las cosas funcionen primero en el teléfono antes de extender la lógica.

## Memorias guardadas
- `C:\Users\fredd\.claude\projects\D--proy-drive\memory\feedback_telegram_test_uploads.md`
- `C:\Users\fredd\.claude\projects\D--proy-drive\memory\project_sync_network_policy.md`

## Pendiente: carpetas en Drive (decidido, no implementado)

- Solo una capa de carpetas. Anidar carpetas queda para despues, si hace falta.
- Telegram no tiene carpetas: la carpeta de cada archivo va en sus metadatos cifrados (campo `folder`).
- Mover un archivo: se edita la descripcion del mensaje en el grupo; no se vuelve a subir.
- Carpetas vacias: no existen en Telegram. Se guardan en la cache local y se avisa de que son solo de este telefono.
- Borrar una carpeta no borra archivos: primero hay que decidir que pasa con su contenido (mover a "Sin carpeta" o bloquear si tiene archivos).
- Se implementa al terminar el proyecto, despues de Drive con subida real verificada.
