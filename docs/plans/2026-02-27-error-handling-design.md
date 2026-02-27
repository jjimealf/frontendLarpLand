# Diseno de Manejo de Errores - Fase 1

Fecha: 2026-02-27

## Objetivo

Reemplazar excepciones genericas por un contrato de error tipado y consistente,
sin cambiar los mensajes funcionales que recibe la UI.

## Alcance

- Nuevo tipo `AppError` en capa de servicios.
- Migracion inicial en:
  - `firebase_backend.dart`
  - `login.dart`
  - `register.dart`
  - `user.dart`
  - `product.dart`
  - `order.dart`
- Eliminacion de `catch (_) {}` en flujo de checkout y limpieza de Storage.
- Adaptacion de `uiErrorMessage` para soportar `AppError`.
- Test unitario para `uiErrorMessage`.

## Contrato de Error

`AppError` incluye:

- `code`: identificador estable para clasificacion (`auth.*`, `validation.*`, `firestore.*`, `storage.*`).
- `message`: texto listo para mostrar en UI.
- `cause`: error original opcional para diagnostico.

## Criterios de exito

- No usar `throw Exception(...)` en los servicios incluidos.
- No usar `catch (_) {}` en los flujos refactorizados.
- La UI sigue mostrando mensajes legibles y sin prefijos tecnicos.
- Test de `uiErrorMessage` pasando con casos tipados y genericos.
