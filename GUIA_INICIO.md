# Guía de inicio: Drive Personal

Esta guía lleva de cero a una app funcionando en tu Android. Usa tu propia cuenta de Telegram y tu propio grupo privado. Nada sale de tu teléfono sin cifrar.

## 1. Lo que necesitas

- Una cuenta de Telegram con tu número (la app de Telegram instalada en el celular).
- Un computador con Windows, Flutter y el SDK de Android (lo que ya configuramos en el proyecto).
- Un cable USB para el teléfono, con la **depuración USB** activada.
- Unos 15 minutos.

> **Importante:** tus datos de acceso (`api_id`, `api_hash`) son privados. No los pegues en chats, capturas, correos ni repositorios públicos. Si alguna vez se exponen, regenéralos en my.telegram.org.

## 2. Crear tu aplicación en Telegram

1. Entra a **https://my.telegram.org** desde el navegador.
2. Escribe tu número de Telegram con el código de país, por ejemplo `+58 412 1234567`.
3. Telegram te envía un código **dentro de la app de Telegram** (no por SMS, normalmente). Escríbelo en la web.
4. Entra a **API development tools**.
5. Si es la primera vez, completa el formulario:
   - **App title:** `Drive Personal` (o el nombre que quieras).
   - **Short name:** `drivepersonal` (solo letras y números, sin espacios).
   - **Platform:** Android.
   - Los demás campos pueden quedar vacíos o con cualquier valor.
6. Te aparecen dos datos:
   - **App api_id:** un número, por ejemplo `12345678`.
   - **App api_hash:** una cadena de letras y números.

Guárdalos en un lugar seguro. Los usaremos en el paso 5.

> Si ves el mensaje **"Too many attempts"**, Telegram te bloqueó temporalmente por insistir. Espera un buen rato (puede ser horas) y no cambies de red ni de cuenta para intentar de nuevo.

## 3. Crear el grupo privado de almacenamiento

Este grupo es donde se guardan tus archivos cifrados.

1. En Telegram, crea un **grupo nuevo** (no un canal).
2. Ponle un nombre cualquiera, por ejemplo `Nube Personal`.
3. Conviértelo en **supergrupo**: si Telegram lo sugiere, acéptalo. Los supergrupos tienen IDs que empiezan por `-100`.
4. Déjalo **privado**: no le pongas nombre de usuario público.
5. Añade solo a tu cuenta (no hace falta nadie más).

## 4. Obtener el ID del grupo

El ID de un supergrupo empieza por `-100` seguido de números, por ejemplo `-1001234567890`.

Forma más fácil:

1. Abre el grupo en **Telegram Web** (https://web.telegram.org). La dirección tendrá la forma `.../#-1001234567890` o `.../c/1234567890/...`.
2. Si ves `/c/1234567890`, el ID es `-100` + ese número: `-1001234567890`.

Otra forma: reenvía cualquier mensaje del grupo al bot **@getidsbot** y te responde con el ID.

Guárdalo; es el valor de `TG_CHANNEL_ID`.

## 5. Configurar el proyecto

1. En la carpeta `app`, copia `.env.example` y renómbralo a `.env`.
2. Abre `.env` y completa:

```
TG_API_ID=12345678
TG_API_HASH=tu_api_hash_aqui
TG_CHANNEL_ID=-1001234567890
```

> `.env` está excluido de Git. **No lo subas a ningún lado.**
>
> La frase maestra no va en `.env`: se configura dentro de la app (ver paso 8).

## 6. Compilar e instalar en el teléfono

1. Activa la **depuración USB** en el teléfono y acepta el permiso cuando lo conectes.
2. Desde la carpeta `app`, compila pasando los datos del `.env`. Con los valores reales:

```bash
flutter build apk --debug --dart-define=TG_API_ID=12345678 --dart-define=TG_API_HASH=tu_api_hash_aqui --dart-define=TG_CHANNEL_ID=-1001234567890
```

3. Instala el resultado:

```bash
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

Si el teléfono no aparece en `adb devices`, revisa el cable y la depuración USB.

## 7. Primer inicio de sesión en la app

1. Abre **Drive Personal** en el teléfono.
2. Escribe tu número de Telegram con el código de país.
3. Telegram te envía un código **a la app de Telegram** de ese mismo número. Escríbelo.
4. Si tienes **verificación en dos pasos** (contraseña de Telegram), la app te la pedirá. Escríbela.
   - Si no la recuerdas, no hay forma de recuperarla desde la app. Se cambia en Telegram: Ajustes → Privacidad y seguridad → Verificación en dos pasos.
5. Cuando aparezca la pantalla principal (Fotos, Álbumes, Drive, Ajustes), la sesión está lista. Se guarda en el teléfono; no vuelves a pedir código salvo que cierres sesión.

## 8. Configurar la frase maestra

La frase maestra cifra tus archivos y sus nombres. **Sin ella no se pueden leer.**

1. Ve a **Ajustes → Frase maestra**.
2. Escribe una frase larga y guárdala **fuera del teléfono** (en un gestor de contraseñas o en papel).
3. Si la pierdes, no hay recuperación.

> La frase se guarda hoy en el teléfono sin cifrar extra. Está pendiente pasarla al almacén seguro de Android.

## 9. Permisos de fotos

La primera vez, la app pide acceso a fotos y videos. Elige **Permitir todas**. Con acceso limitado solo verás las fotos que elegiste y las copias no serán completas.

## 10. Listo: primeras acciones

- **Ajustes → Copias de seguridad:** elige los álbumes a respaldar y pulsa **Guardar**. Por defecto solo sube con Wi-Fi.
- **Drive:** el botón de subir elige archivos del teléfono y los cifra al grupo.
- **Ajustes → Liberar espacio:** quita del teléfono lo que ya está en el grupo, o borra del grupo. Antes de borrar, cada elemento tiene vista previa.

## Problemas frecuentes

| Problema | Qué hacer |
|---|---|
| "Falta TG_API_ID o TG_API_HASH al compilar" | Compila de nuevo con los tres `--dart-define`. |
| "Too many attempts" de Telegram | Espera horas y no insistas. |
| El código no llega | Revisa la app de Telegram del mismo número; el código va ahí. |
| Pide contraseña y no la recuerdas | Cámbiala desde Telegram en otro dispositivo, o usa la recuperación de Telegram. |
| Las fotos no aparecen | Revisa el permiso de fotos: debe ser **Permitir todas**. |
| No sube nada | Revisa la red permitida en Copias de seguridad (Solo Wi-Fi por defecto). |
