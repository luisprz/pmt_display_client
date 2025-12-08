# pmt_display_client |||||||||||||    MVP    ||||||||||||| 



Qué es el proyecto

Cómo funciona

Cómo levantarlo en VS Code

Cómo compilarlo

Cómo instalarlo en un Firestick

Cómo prepararlo para GitHub Pages

Cómo extenderlo

Qué falta por hacer (TO-DO list)

Cómo iniciar el ID de pantalla

Cómo se estructura el JSON

Qué comandos de ADB usar

Qué hardware es compatible

Qué hacer si salen errores



# 🖥️ ProMultiTech Display Client  
Sistema de Cartelería Digital para Fire TV Stick / Android TV  
**(Flutter + GitHub Pages)**

Este proyecto es un cliente Flutter diseñado para mostrar imágenes de forma remota en pantallas (Fire TV Stick / Android TV Box / Android TV).  
La aplicación descarga un archivo JSON desde GitHub Pages, interpreta qué imagen debe mostrar y la presenta en pantalla completa 24/7.

Es parte del ecosistema **ProMultiTech Digital Signage**, diseñado para instalarse fácilmente en múltiples pantallas.

---

## 🚀 Características principales

- ✔️ Fullscreen digital signage (sin UI visible)  
- ✔️ Descarga imagen remota desde GitHub Pages  
- ✔️ Lee configuración JSON por pantalla  
- ✔️ Auto-refresh cada X segundos  
- ✔️ Funciona sin backend (solo GitHub Pages)  
- ✔️ Permite múltiples pantallas (caja1, entrada, lavadero, etc.)  
- ✔️ Preparado para escalar a 3, 10, 50 pantallas  
- ✔️ Código limpio en Flutter/Dart

---

## 📁 Estructura general del proyecto



pmt_display_client/
│── lib/
│ └── main.dart
│── android/
│── assets/
│ └── fallback.jpg
│── pubspec.yaml
│── README.md ← este archivo


---

## 🛠 Requisitos

### Software

- Flutter 3.x+
- Android SDK
- Git
- VS Code (recomendado)
- ADB (incluido en Android SDK)

### Hardware compatible

| Dispositivo | Compatible |
|------------|------------|
| Fire TV Stick 4K / 4K MAX | ✅ Recomendado |
| Android TV Box (Android 9+) | ✅ |
| Android TV (Google TV) | ✅ |
| Fire OS 5.x muy antiguo | ❌ No compatible con Flutter moderno |
| Fire OS 4.x / Android < API 16 | ❌ Rechaza APKs |

---

## 📦 Instalación del proyecto en VS Code

En terminal:

```bash
git clone https://github.com/TU_USUARIO/pmt_display_client.git
cd pmt_display_client
flutter pub get


Luego abre el proyecto:

code .

⚙️ Compilar APK para Firestick
flutter clean
flutter pub get
flutter build apk --release


El APK se genera en:

build/app/outputs/flutter-apk/app-release.apk

📡 Instalar APK en Firestick
1. Activar modo desarrollador en Firestick

En el Fire TV:

Settings → My Fire TV → About → (presionar 7 veces)
Settings → My Fire TV → Developer Options


Activar:

ADB Debugging → ON

Apps from Unknown Sources → ON

2. Ver la IP del Firestick
Settings → My Fire TV → About → Network → IP Address


Ejemplo: 192.168.137.58

3. Conectarse con ADB
cd C:\Users\maste\AppData\Local\Android\Sdk\platform-tools
adb kill-server
adb start-server
adb connect 192.168.137.58:5555
adb devices


Debe aparecer:

192.168.137.58:5555   device

4. Instalar el APK
adb install -r "C:\ruta\app-release.apk"

🌐 Configuración con GitHub Pages
Crear repo GitHub Pages

Crear repositorio: pmt-signage

En Settings → Pages, activar GitHub Pages

Crear estructura:

pmt-signage/
│── screens/
│    ├── lavadero-01.json
│    └── caja1.json
└── images/
     ├── lavadero-menu.jpg
     └── caja1-ofertas.jpg

Ejemplo JSON (screens/lavadero-01.json)
{
  "image_url": "https://TU_USUARIO.github.io/pmt-signage/images/lavadero-menu.jpg",
  "reload_seconds": 300
}

Flutter toma este JSON desde:
static const String baseConfigUrl =
    'https://TU_USUARIO.github.io/pmt-signage/screens';

static const String displayId = 'lavadero-01';

🧠 ¿Cómo funciona?

La app construye esta URL:

https://TU_USUARIO.github.io/pmt-signage/screens/lavadero-01.json


Descarga el JSON.

Extrae:

image_url → imagen a mostrar

reload_seconds → cada cuánto verificar cambios

Descarga la imagen.

La muestra en fullscreen.

Cada ciclo vuelve a consultar por cambios en GitHub Pages.

📂 Estructura del JSON
{
  "image_url": "URL completa a la imagen",
  "reload_seconds": 60
}


Más adelante se puede extender a:

videos

playlist

schedule (mañana/tarde)

overlays

layouts

🧩 Código principal (main.dart)

Explicar qué hace:

pantalla fullscreen

sin barra de sistema

mantiene pantalla encendida (wakelock_plus)

usa cached_network_image

auto-reintento

🧪 Test básico

Para probar, sube:

/images/test.jpg

/screens/test.json

Luego en app:

displayId = "test";

🛠 Troubleshooting
❌ INSTALL_FAILED_OLDER_SDK

Significa:

El Firestick tiene Android demasiado viejo.

Usa Firestick 4K / Android Box moderno.

❌ ADB: device unauthorized

Solución:

Mira la TV → sale popup de “Allow debugging”

Toca Always allow

❌ No carga imagen

Revisa que el JSON exista

Revisa que la URL de imagen exista

Revisa que GitHub Pages publique (esperar 10–30s)

📌 TO-DO / Próximas mejoras

 Pantalla inicial para configurar displayId sin recompilar

 Agregar soporte para playlists (múltiples imágenes)

 Agregar soporte para video (.mp4)

 Panel web (Flutter Web o Node) para subir imágenes sin entrar a GitHub

 Sistema de logs remoto

 Actualización por WebSockets o SSE

 Branding completo ProMultiTech

 Modo kiosk completo en Firestick (auto-launch)














///////////////////////// ETAPA 0 ////////////////////////////
App que permite leer imagenes de github / todavia sin app para celular ni panel admin

Este proyecto es un cliente Flutter diseñado para mostrar imágenes de forma remota en pantallas (Fire TV Stick / Android TV Box / Android TV).  
La aplicación descarga un archivo JSON desde GitHub Pages, interpreta qué imagen debe mostrar y la presenta en pantalla completa 24/7.






///////////////////// Volver a compilar e instalar //////////////

En la carpeta del proyecto:

cd "C:\Users\maste\Documents\PMT\Software\pmt_display_client"
flutter build apk --release


Luego, en platform-tools:

cd "C:\Users\maste\AppData\Local\Android\Sdk\platform-tools"
.\adb connect 192.168.137.70:5555
.\adb install -r "C:\Users\maste\Documents\PMT\Software\pmt_display_client\build\app\outputs\flutter-apk\app-release.apk"


Abre la app en el Firestick.





//////////////////////////// Subir A Github //////////////////////////////////////
cd "C:\Users\maste\Documents\PMT\Software\pmt_display_client"
git pull origin main

git add .
git commit -m "mensaje"
git push origin main
