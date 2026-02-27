# LarpLand

Aplicacion Flutter para gestion de tienda y eventos de rol en vivo (LARP), con roles de usuario y administrador.

## Contexto academico

Este repositorio corresponde a mi proyecto del Grado Superior de DAM (Desarrollo de Aplicaciones Multiplataforma).

## Ramas disponibles

- `master`: version original con backend Laravel (API REST).
- `firebase`: version migrada para usar Firebase como backend (`Firebase Auth`, `Cloud Firestore`, `Firebase Storage`).

## Funcionalidades actuales

- Autenticacion y registro contra API (`/api/login`, `/api/register`).
- Flujo de usuario:
  - Catalogo de productos.
  - Busqueda de productos.
  - Carrito de compras y checkout.
  - Detalle de producto con reseñas y valoracion.
  - Lista de eventos e inscripcion local.
- Flujo de administrador:
  - Panel con pestanas para usuarios, inventario y eventos.
  - Alta y edicion de productos (incluye imagen por multipart).
  - Alta y listado de eventos.
  - Listado de usuarios.
- Manejo de sesion con token Bearer en llamadas autenticadas.

## Stack tecnico

- Flutter / Dart
- `provider` para estado de carrito
- `http` para consumo de API REST (rama `master`)
- `firebase_core` + `firebase_auth` + `cloud_firestore` + `firebase_storage` (rama `firebase`)
- `image_picker` para seleccion de imagenes
- `flutter_local_notifications` para recordatorios de eventos

## Configuracion de API

La URL base se define en `lib/service/api_config.dart` (rama `master`):

- Web: `http://localhost:8000`
- Android emulator: `http://10.0.2.2:8000`
- Resto de plataformas: `http://localhost:8000`

Asegurate de tener el backend disponible en esa direccion o ajusta `ApiConfig.baseUrl`.

## Configuracion Firebase (rama `firebase`)

1. Configura FlutterFire (`flutterfire configure`) o completa `lib/firebase_options.dart`.
2. Habilita en Firebase Console:
   - Authentication (Email/Password)
   - Firestore Database
   - Firebase Storage
3. Agrega archivos de plataforma si aplica (`google-services.json`, `GoogleService-Info.plist`).

## Ejecutar el proyecto

1. Instalar dependencias:

```bash
flutter pub get
```

2. Ejecutar:

```bash
flutter run
```

## Calidad y pruebas

- Analisis estatico:

```bash
flutter analyze
```

- Tests:

```bash
flutter test
```

## Estructura principal

- `lib/main.dart`: entrada de la app y provider global.
- `lib/view/`: pantallas de login, usuario, carrito y admin.
- `lib/service/`: integracion con API.
- `lib/model/`: modelos de dominio.
- `lib/provider/`: estado global (carrito).
- `test/`: pruebas de widgets.
