# Dog Biometric Frontend

Aplicación móvil desarrollada con **Flutter** para el registro e identificación biométrica de perros **por trufa nasal**. La raza (YOLOv8 + TensorFlow Lite, on-device) es solo un dato descriptivo; la identificación real compara embeddings de trufa contra el microservicio `ml_service` a través del backend.

---

## Tabla de Contenidos

- [Descripción](#descripción)
- [Tecnologías](#tecnologías)
- [Arquitectura](#arquitectura)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Requisitos Previos](#requisitos-previos)
- [Instalación y Ejecución](#instalación-y-ejecución)
- [Configuración de la API](#configuración-de-la-api)
- [Funcionalidades Principales](#funcionalidades-principales)
- [Razas de Perros Soportadas](#razas-de-perros-soportadas)

---

## Descripción

**Dog Biometric** es un sistema de identificación biométrica de mascotas por trufa nasal. La aplicación móvil permite:

- Registro e inicio de sesión de propietarios (sesión persistida en el dispositivo).
- Registro de perros en 5 pasos: datos básicos, foto de perfil (con detección/clasificación de raza descriptiva), 4 fotos de trufa (requeridas para habilitar la identificación), 2 fotos de rostro (se guardan para una futura fusión multimodal, no se usan hoy) y resumen final.
- Identificación de un perro extraviado: 1 foto de trufa → hasta 10 candidatos más similares → el usuario confirma manualmente cuál es → se revela el contacto del dueño solo tras confirmar.
- Historial de identificaciones realizadas.
- Búsqueda de perros por raza detectada (solo descriptiva, independiente de la identificación biométrica).
- Gestión del perfil del usuario.

---

## Tecnologías

| Tecnología | Versión | Uso |
|---|---|---|
| Flutter | SDK ≥3.9.2 | Framework UI multiplataforma |
| Dart | — | Lenguaje de programación |
| TensorFlow Lite | 0.11.0 | Inferencia de modelos ML en dispositivo |
| YOLOv8 (TFLite) | — | Detección de perro y clasificación de raza (descriptivo) |
| camera | 0.11.0+2 | Preview en vivo con guía circular para capturar trufa/rostro |
| image_picker | 1.1.2 | Captura de la foto de perfil (cámara/galería) |
| shared_preferences | 2.3.3 | Persistencia del token JWT entre sesiones |
| HTTP | 1.6.0 | Comunicación con la API REST |
| intl_phone_field | 3.2.0 | Campo de número telefónico |

---

## Arquitectura

```
┌──────────────────────────────────────────────┐
│              Flutter Mobile App               │
│                                               │
│  Login/Register → MainShell → Home / Perfil   │
│  Registro: Datos → Foto perfil → Trufa(x4)    │
│            → Rostro(x2) → Resumen             │
│  Identificar: Scan(trufa) → Resultados(top10) │
│            → Confirmar → Contacto del dueño   │
│                                               │
│  On-Device ML (TFLite): YOLOv8 detección +    │
│  clasificación de raza — solo descriptivo     │
└──────────────────────┬───────────────────────┘
                       │ HTTP REST (JWT)
                       ▼
            ┌──────────────────────┐
            │  Node.js / Express   │
            │  (dog_biometric_api) │
            └──────────┬───────────┘
                       │ HTTP
                       ▼
            ┌──────────────────────┐
            │  FastAPI / PyTorch   │
            │     (ml_service)     │
            │  embeddings de trufa │
            └──────────────────────┘
```

---

## Estructura del Proyecto

```
dog_biometric_frontend/
├── lib/
│   ├── main.dart                          # Punto de entrada de la aplicación
│   ├── core/
│   │   ├── app_colors.dart                # Paleta de colores de la app
│   │   ├── auth_storage.dart              # Persistencia del JWT (shared_preferences)
│   │   └── constants.dart                 # URL base de la API y reglas biométricas (MIN_FOTOS_TRUFA, etc.)
│   ├── screens/
│   │   ├── splash_page.dart               # Splash inicial (lee token guardado)
│   │   ├── welcome_page.dart              # Bienvenida
│   │   ├── login_page.dart                # Inicio de sesión
│   │   ├── register_page.dart             # Registro de usuario (dueño)
│   │   ├── main_shell.dart                # Shell con bottom nav (Home/Perfil) + acceso a Scan e Historial
│   │   ├── home_page.dart                 # Dashboard principal
│   │   ├── profile_page.dart              # Perfil del usuario
│   │   ├── historial_screen.dart          # Historial de identificaciones
│   │   ├── registro_datos_screen.dart     # Registro de perro, paso 1: datos básicos
│   │   ├── foto_perfil_screen.dart        # Registro de perro, paso 2: foto general (raza descriptiva)
│   │   ├── captura_trufa_screen.dart      # Registro de perro, paso 3: 4 fotos de trufa (biométrico)
│   │   ├── captura_rostro_screen.dart     # Registro de perro, paso 4: 2 fotos de rostro (solo se guardan)
│   │   ├── resumen_registro_screen.dart   # Registro de perro, paso 5: confirmación final
│   │   ├── scan_screen.dart               # Identificación: 1 foto de trufa → POST /api/identify
│   │   ├── resultados_screen.dart         # Top-10 candidatos, confirmación manual
│   │   ├── contacto_dueno_screen.dart     # Contacto del dueño (solo tras confirmar)
│   │   ├── sin_coincidencia_screen.dart   # Sin candidatos / "Ninguno coincide"
│   │   ├── add_dog_sheet.dart             # Fuente de kRazas (lista de razas descriptivas)
│   │   └── edit_profile_sheet.dart        # Edición del perfil de usuario
│   ├── widgets/
│   │   ├── camera_capture_widget.dart     # Captura con cámara en vivo + guía circular (trufa/rostro/scan)
│   │   ├── registro_header.dart           # Header con barra de progreso del flujo de registro
│   │   ├── auth_widgets.dart              # AuroraBackground, GlassCard, GradientButton, etc.
│   │   ├── bottom_nav_bar.dart            # Barra de navegación inferior
│   │   └── home_widgets.dart              # Widgets del dashboard
│   └── services/
│       └── ml/
│           ├── breed_classifier.dart      # Clasificación de raza (TFLite) — solo descriptivo
│           └── dog_detector.dart          # Detección de perros (YOLOv8) — solo sobre la foto de perfil
├── assets/
│   └── models/
│       ├── yolov8n_float16.tflite         # Modelo de detección de objetos
│       └── yolov8n-cls_float32.tflite     # Modelo de clasificación de razas
├── android/                       # Código nativo Android
├── ios/                           # Código nativo iOS
├── pubspec.yaml                   # Dependencias y configuración Flutter
└── README.md
```

---

## Requisitos Previos

Antes de ejecutar la aplicación, asegúrate de tener instalado:

1. **Flutter SDK** ≥ 3.9.2
   - [Guía de instalación oficial](https://docs.flutter.dev/get-started/install)
   - Verificar con: `flutter doctor`

2. **Android Studio** (para Android) o **Xcode** (para iOS)

3. **Dispositivo físico o emulador** configurado

4. **El backend** `dog_biometric_api` ejecutándose (ver su README)

---

## Instalación y Ejecución

### Paso 1: Clonar el repositorio

```bash
git clone <URL_DEL_REPOSITORIO>
cd dog_biometric_frontend
```

### Paso 2: Instalar dependencias

```bash
flutter pub get
```

### Paso 3: Configurar la URL de la API

Abre el archivo [lib/core/constants.dart](lib/core/constants.dart) y actualiza la dirección IP con la IP de tu máquina donde corre el backend:

```dart
class ApiConstants {
  static const String baseUrl = 'http://TU_IP_LOCAL:3000';
  ...
}
```

> Para obtener tu IP local en Windows: ejecuta `ipconfig` en CMD y copia la dirección IPv4.
> Este es el único archivo donde se debe cambiar la IP; todas las pantallas la usan desde aquí.

### Paso 4: Ejecutar la aplicación

```bash
# Listar dispositivos disponibles
flutter devices

# Ejecutar en dispositivo específico
flutter run

# Ejecutar en modo release (Android)
flutter build apk --release
```

---

## Configuración de la API

La aplicación se comunica con el backend a través de HTTP REST. La URL base está definida en los archivos de cada pantalla. Asegúrate de:

- El backend está corriendo en el **mismo puerto 3000**.
- El dispositivo móvil y la computadora del backend están en la **misma red WiFi**.
- La IP configurada en el app coincide con la IP del servidor backend.

---

## Funcionalidades Principales

| Función | Descripción |
|---|---|
| Autenticación | Login con carnet/email y contraseña, token JWT persistido en el dispositivo |
| Registro de usuario | Formulario con nombre, apellido, carnet, teléfono, fecha de nacimiento |
| Registro de perro | Flujo de 5 pantallas: datos, foto de perfil, 4 fotos de trufa, 2 de rostro, resumen |
| Detección de raza | Clasificación automática usando YOLOv8 en el dispositivo (solo descriptiva) |
| Identificación biométrica | 1 foto de trufa → hasta 10 candidatos por similitud → confirmación manual → contacto del dueño |
| Historial | Consultas de identificación anteriores del usuario |
| Listado de perros | Vista de todos los perros registrados del usuario |
| Búsqueda por raza | Filtrar perros por raza detectada (independiente de la identificación biométrica) |
| Edición de perfil | Actualizar datos del usuario |

---

## Razas de Perros Soportadas

El clasificador reconoce **36 razas**:

Mestizo, Labrador Retriever, Golden Retriever, Pastor Alemán, Bulldog Francés, Bulldog Inglés, Poodle, Beagle, Rottweiler, Yorkshire Terrier, Dachshund, Boxer, Siberian Husky, Chihuahua, Gran Danés, Dobermann, Shih Tzu, Border Collie, Pomerania, Cocker Spaniel, Maltés, Schnauzer, Shar Pei, Akita, Samoyedo, Weimaraner, Basset Hound, Dálmata, Chow Chow, Bichón Frisé, Pug, Shiba Inu, Australian Shepherd, Bernese Mountain Dog, Pitbull.

---

## Autores

Proyecto de fin de especialidad — Sistema de Identificación Biométrica de Mascotas.
