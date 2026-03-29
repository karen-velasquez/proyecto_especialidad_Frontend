# Dog Biometric Frontend

Aplicación móvil desarrollada con **Flutter** para el registro y gestión biométrica de perros. Permite a los usuarios autenticarse, registrar sus mascotas con fotos y clasificar la raza del perro directamente en el dispositivo mediante modelos de inteligencia artificial (YOLOv8 con TensorFlow Lite).

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

**Dog Biometric** es un sistema de identificación biométrica de mascotas. La aplicación móvil permite:

- Registro e inicio de sesión de propietarios.
- Captura de fotos del perro usando la cámara del dispositivo.
- Detección y clasificación de raza en tiempo real (on-device) usando modelos YOLOv8.
- Registro de perros con datos completos (nombre, raza, edad, género, esterilización).
- Búsqueda de perros por raza detectada.
- Gestión del perfil del usuario.

---

## Tecnologías

| Tecnología | Versión | Uso |
|---|---|---|
| Flutter | SDK ≥3.9.2 | Framework UI multiplataforma |
| Dart | — | Lenguaje de programación |
| TensorFlow Lite | 0.11.0 | Inferencia de modelos ML en dispositivo |
| YOLOv8 (TFLite) | — | Detección y clasificación de razas |
| HTTP | 1.6.0 | Comunicación con la API REST |
| image_picker | 1.1.2 | Captura de imágenes con cámara/galería |
| intl_phone_field | 3.2.0 | Campo de número telefónico |

---

## Arquitectura

```
┌──────────────────────────────────────────────┐
│              Flutter Mobile App               │
│                                              │
│  ┌──────────┐  ┌────────────┐  ┌──────────┐ │
│  │ Login /  │  │ Home Page  │  │ Add Dog  │ │
│  │ Register │  │ (Dashboard)│  │  Sheet   │ │
│  └──────────┘  └────────────┘  └──────────┘ │
│                                              │
│  ┌─────────────────────────────────────────┐ │
│  │         On-Device ML (TFLite)           │ │
│  │  YOLOv8 Detection + Breed Classifier    │ │
│  └─────────────────────────────────────────┘ │
└──────────────────────┬───────────────────────┘
                       │ HTTP REST
                       ▼
            ┌──────────────────────┐
            │  Node.js / Express   │
            │  (dog_biometric_api) │
            └──────────────────────┘
```

---

## Estructura del Proyecto

```
dog_biometric_frontend/
├── lib/
│   ├── main.dart                  # Punto de entrada de la aplicación
│   ├── app_colors.dart            # Paleta de colores de la app
│   ├── login_page.dart            # Pantalla de inicio de sesión
│   ├── register_page.dart         # Pantalla de registro de usuario
│   ├── home_page.dart             # Dashboard principal
│   ├── add_dog_sheet.dart         # Formulario de registro de perros
│   ├── edit_profile_sheet.dart    # Edición del perfil de usuario
│   ├── breed_classifier.dart      # Clasificación de raza (TFLite)
│   └── dog_detector.dart          # Detección de perros (YOLOv8)
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

Abre el archivo [lib/login_page.dart](lib/login_page.dart) y actualiza la dirección IP con la IP de tu máquina donde corre el backend:

```dart
// Buscar la línea que contiene la URL base y cambiar la IP:
final String baseUrl = 'http://TU_IP_LOCAL:3000';
```

> Para obtener tu IP local en Windows: ejecuta `ipconfig` en CMD y copia la dirección IPv4.

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
| Autenticación | Login con carnet/email y contraseña, token JWT |
| Registro de usuario | Formulario con nombre, apellido, carnet, teléfono, fecha de nacimiento |
| Registro de perro | Foto, nombre, raza, género, edad, esterilización |
| Detección de raza | Clasificación automática usando YOLOv8 en el dispositivo |
| Listado de perros | Vista de todos los perros registrados del usuario |
| Búsqueda por raza | Filtrar perros por raza detectada |
| Edición de perfil | Actualizar datos del usuario |

---

## Razas de Perros Soportadas

El clasificador reconoce **36 razas**:

Mestizo, Labrador Retriever, Golden Retriever, Pastor Alemán, Bulldog Francés, Bulldog Inglés, Poodle, Beagle, Rottweiler, Yorkshire Terrier, Dachshund, Boxer, Siberian Husky, Chihuahua, Gran Danés, Dobermann, Shih Tzu, Border Collie, Pomerania, Cocker Spaniel, Maltés, Schnauzer, Shar Pei, Akita, Samoyedo, Weimaraner, Basset Hound, Dálmata, Chow Chow, Bichón Frisé, Pug, Shiba Inu, Australian Shepherd, Bernese Mountain Dog, Pitbull.

---

## Autores

Proyecto de fin de especialidad — Sistema de Identificación Biométrica de Mascotas.
