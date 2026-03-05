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

## State Management

The app uses the [Provider](https://pub.dev/packages/provider) package for state management. All providers are registered at the top of the widget tree in `main.dart` using `MultiProvider`:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => UserProvider()),
    ChangeNotifierProvider(create: (_) => FriendProvider()),
    ChangeNotifierProvider(create: (_) => LocationProvider()),
  ],
  child: MaterialApp(...),
)
```

This makes all three providers available to every screen in the app via `context.watch<T>()` (to rebuild on changes) or `context.read<T>()` (for one-off access without rebuilding).

### UserProvider

Manages the currently logged-in user.

| Property / Method | Description |
|-------------------|-------------|
| `currentUser` | The logged-in `User` object, or `null` if not logged in |
| `isLoggedIn` | Whether a user is currently authenticated |
| `isLoading` | `true` while a login request is in progress |
| `login(email)` | Calls `POST /auth/login`, stores the returned user and auth token |
| `logout()` | Calls `POST /auth/logout`, clears the token and user state |
| `updateUser(user)` | Directly sets the current user (used after profile edits) |

### FriendProvider

Manages the friends list, friend requests, and a user name resolution cache.

| Property / Method | Description |
|-------------------|-------------|
| `friends` | List of accepted `User` friends |
| `incomingRequests` | Pending `FriendRequest` objects sent to the current user |
| `outgoingRequests` | Pending `FriendRequest` objects sent by the current user |
| `userCache` | `Map<int, User>` cache for resolved user names (avoids repeat lookups) |
| `loadFriends()` | Fetches the friends list from `GET /friends/` |
| `loadIncomingRequests()` | Fetches incoming requests and resolves sender names |
| `loadOutgoingRequests()` | Fetches outgoing requests and resolves target names |
| `resolveUser(userId)` | Looks up a user by ID, caches the result, returns a fallback on failure |
| `sendRequest(userId)` | Sends a friend request via `POST /friends/` |
| `acceptRequest(relId)` | Accepts a request, then reloads friends and incoming lists |
| `rejectRequest(relId)` | Rejects a request, reloads incoming list |
| `blockRequest(relId)` | Blocks a request, reloads incoming list |
| `cancelRequest(relId)` | Cancels an outgoing request, reloads outgoing list |
| `clear()` | Resets all state to defaults — called on logout |

### LocationProvider

Manages location sharing, GPS polling, and per-friend permissions.

| Property / Method | Description |
|-------------------|-------------|
| `myLocation` | The current user's `UserLocation` record, or `null` if not yet created |
| `isSharingEnabled` | Whether the user is actively sharing their location |
| `friendLocations` | List of `UserLocation` objects for friends sharing with the current user |
| `permissions` | List of `LocationPermission` records (friends the user is sharing with) |
| `isLoading` | `true` during initial data fetch |
| `error` | Error message from the last failed operation, or `null` |
| `init()` | Fetches own location, friend locations, and permissions from the backend |
| `startPolling()` | Starts a 20-second timer that refreshes friend locations and pushes own GPS |
| `stopPolling()` | Cancels the polling timer |
| `toggleSharing()` | Toggles location sharing on/off — creates a record on first use, refreshes GPS on re-enable |
| `grantPermission(friendId)` | Shares your location with a friend (creates location record if needed) |
| `revokePermission(friendId)` | Stops sharing your location with a friend |
| `refreshPermissions()` | Reloads the permissions list from the backend |
| `clear()` | Cancels polling, resets all state — called on logout |

### Patterns

A few patterns are consistent across all providers:

- **Constructor injection**: `FriendProvider` and `LocationProvider` accept an optional `ApiService` parameter. In production the default instance is used; in tests a mocked service can be passed in.
- **`clear()` on logout**: Every provider has a `clear()` method that resets state to defaults. These are all called when the user logs out (from `ProfileScreen`).
- **Loading and error state**: Each provider tracks `isLoading` and `error` so screens can show spinners and error messages.
- **`notifyListeners()`**: Called after every state change so widgets using `context.watch<T>()` rebuild automatically.
