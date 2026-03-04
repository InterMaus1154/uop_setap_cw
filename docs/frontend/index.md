# Frontend Documentation

This document covers the CampusConnect Flutter frontend — its structure, patterns, and how the pieces fit together. It is aimed at developers working on or reviewing the frontend codebase.

## Project Structure

The frontend lives in the `frontend/` directory and follows a standard Flutter project layout. All application code is under `lib/`, organised by responsibility:

```
frontend/lib/
├── main.dart              # App entry point, provider registration, routing
├── models/                # Data classes that map to backend API responses
├── providers/             # State management (ChangeNotifier + Provider)
├── screens/               # Full-page UI widgets (one per app screen)
├── services/              # HTTP client, secure storage, external integrations
└── widgets/               # Reusable UI components shared across screens
```

### `models/`

Plain Dart classes representing backend entities. Each model has a constructor, a `fromJson` factory for deserialising API responses, and a `toJson` method for serialising outbound requests.

| File | Description |
|------|-------------|
| `user.dart` | User profile — name, email, display name preference |
| `pin.dart` | Map pin — title, description, coordinates, category, expiry, reactions |
| `pin_form_data.dart` | Data class for the pin creation form (used by `PinCreationSheet`) |
| `category.dart` | `Category`, `CategoryLevel`, and `SubCategory` — pin classification |
| `friend_request.dart` | Friend request with status (pending, accepted, blocked) |
| `user_location.dart` | GPS coordinates and sharing enabled/disabled flag |
| `location_permission.dart` | Per-friend location sharing permission record |

All model field names match the backend JSON keys exactly (snake_case in JSON, camelCase in Dart).

### `providers/`

State management using the [Provider](https://pub.dev/packages/provider) package. Each provider extends `ChangeNotifier` and is registered in `main.dart` via `MultiProvider`.

| File | Description |
|------|-------------|
| `user_provider.dart` | Current logged-in user state, login/logout flow |
| `friend_provider.dart` | Friends list, incoming/outgoing requests, user name cache |
| `location_provider.dart` | Location sharing toggle, GPS polling, friend locations, permissions |

Providers accept dependencies via constructor injection (e.g. `ApiService`) so they can be tested with mocked services.

### `screens/`

Each file is a full-page widget corresponding to a screen in the app.

| File | Description |
|------|-------------|
| `user_selection_screen.dart` | Login screen — select a user from the database |
| `home_screen.dart` | Bottom navigation bar wrapper (Map and Profile tabs) |
| `map_screen.dart` | OpenStreetMap with pins, friend markers, pin creation, filters |
| `profile_screen.dart` | User profile display and edit form, logout |
| `friends_screen.dart` | Friends list with tabs (friends, incoming, outgoing), search |

### `services/`

| File | Description |
|------|-------------|
| `api_service.dart` | Single HTTP client for all backend communication |
| `secure_storage_service.dart` | Wrapper around `flutter_secure_storage` for auth token persistence |

### `widgets/`

| File | Description |
|------|-------------|
| `pin_creation_sheet.dart` | Bottom sheet form for creating a new pin (category, title, description) |

### `test/`

Unit and widget tests mirror the `lib/` folder structure:

```
frontend/test/
├── models/                # Model serialisation tests
├── providers/             # Provider state tests
├── screens/               # Widget tests for screen behaviour
└── services/              # API method tests with mocked HTTP client
```

Tests are run with:

```bash
cd frontend
flutter test test/models/ test/providers/ test/services/
```

```{note}
The default `widget_test.dart` in the test root is a Flutter template file and is not maintained. It can be ignored.
```
