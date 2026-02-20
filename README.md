# LarpLand

Aplicacion Flutter para gestion de tienda y eventos de rol en vivo (LARP), con roles de usuario y administrador.

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
- `http` para consumo de API REST
- `image_picker` para seleccion de imagenes
- `flutter_local_notifications` para recordatorios de eventos

## Configuracion de API

La URL base se define en `lib/service/api_config.dart`:

- Web: `http://localhost:8000`
- Android emulator: `http://10.0.2.2:8000`
- Resto de plataformas: `http://localhost:8000`

Asegurate de tener el backend disponible en esa direccion o ajusta `ApiConfig.baseUrl`.

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
