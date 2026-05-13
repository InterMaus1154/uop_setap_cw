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

Plain Dart classes representing backend entities. Each model has a constructor and a `fromJson` factory for deserialising API responses. Models that need to send data back to the backend also have a `toJson` method.

| File | Description |
|------|-------------|
| `user.dart` | User profile — name, email, display name preference |
| `pin.dart` | Map pin — title, description, coordinates, category, expiry, reactions |
| `pin_form_data.dart` | Data class for the pin creation form (used by `PinCreationSheet`) |
| `category.dart` | `Category`, `CategoryLevel`, and `SubCategory` — pin classification |
| `friend_request.dart` | Friend request with status (pending, accepted, blocked) |
| `user_location.dart` | GPS coordinates and sharing enabled/disabled flag |
| `location_permission.dart` | Per-friend location sharing permission record |
| `invitation_code.dart` | Guest invitation code with expiry and usage status |

All model field names match the backend JSON keys exactly (snake_case in JSON, camelCase in Dart).

### `providers/`

State management using the [Provider](https://pub.dev/packages/provider) package. Each provider extends `ChangeNotifier` and is registered in `main.dart` via `MultiProvider`.

| File | Description |
|------|-------------|
| `user_provider.dart` | Current logged-in user state, login/logout flow |
| `friend_provider.dart` | Friends list, incoming/outgoing requests, user name cache |
| `location_provider.dart` | Location sharing toggle, GPS polling, friend locations, permissions |
| `invitation_code_provider.dart` | Guest invitation code generation and listing |

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
| `invitation_codes_screen.dart` | Generate and view guest invitation codes |

### `services/`

| File | Description |
|------|-------------|
| `api_service.dart` | Single HTTP client for all backend communication |
| `secure_storage_service.dart` | Wrapper around `flutter_secure_storage` for auth token persistence |

### `widgets/`

| File | Description |
|------|-------------|
| `pin_creation_sheet.dart` | Bottom sheet form for creating a new pin (category, title, description, optional image upload via gallery or camera) |

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
    ChangeNotifierProvider(create: (_) => InvitationCodeProvider(apiService: apiService)),
  ],
  child: MaterialApp(...),
)
```

This makes all four providers available to every screen in the app via `context.watch<T>()` (to rebuild on changes) or `context.read<T>()` (for one-off access without rebuilding).

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
| `getCurrentPosition()` | Gets the device's GPS position, handles permission prompts, returns `null` on failure |
| `clear()` | Cancels polling, resets all state — called on logout |

### InvitationCodeProvider

Manages guest invitation code generation and listing. Unlike the other providers, this one requires `ApiService` as a constructor argument (not optional) because it is created in `main.dart` with a shared instance.

| Property / Method | Description |
|-------------------|-------------|
| `codes` | List of `InvitationCode` objects for the current user |
| `isLoading` | `true` while fetching or creating codes |
| `errorMessage` | Error from `loadCodes()`, or `null` |
| `createError` | Error from `createNewCode()` (e.g. 429 rate limit), or `null` |
| `loadCodes()` | Fetches all active invitation codes from `GET /invitation-codes` |
| `createNewCode()` | Creates a new code via `POST /invitation-codes`, inserts it at the top of the list |
| `clearError()` | Resets `errorMessage` |
| `clearCreateError()` | Resets `createError` |

### Patterns

A few patterns are consistent across all providers:

- **Constructor injection**: `FriendProvider`, `LocationProvider`, and `InvitationCodeProvider` accept an optional or required `ApiService` parameter. In production the default instance is used; in tests a mocked service can be passed in.
- **`clear()` on logout**: `FriendProvider` and `LocationProvider` each have a `clear()` method that resets state to defaults. `UserProvider` resets via its `logout()` method instead. These are all called when the user logs out (from `ProfileScreen`).
- **Loading and error state**: Each provider tracks `isLoading` and `error` so screens can show spinners and error messages.
- **`notifyListeners()`**: Called after every state change so widgets using `context.watch<T>()` rebuild automatically.

## API Service

All backend communication goes through a single class: `ApiService` in `lib/services/api_service.dart`. There is no direct HTTP usage anywhere else in the codebase — screens and providers always go through `ApiService`.

### Configuration

| Constant | Value | Description |
|----------|-------|-------------|
| `baseUrl` | `http://localhost:8000` | Backend server address |
| `_timeout` | 10 seconds | Request timeout for all HTTP calls |

The constructor accepts optional `http.Client` and `SecureStorageService` parameters for dependency injection. In production the defaults are used; in tests mocked versions can be passed in:

```dart
// Production (default)
final api = ApiService();

// Testing with mocks
final api = ApiService(storage: mockStorage, httpClient: mockClient);
```

### Authentication

Auth tokens are managed by `SecureStorageService`, a thin wrapper around `flutter_secure_storage` that stores the token in the OS keychain. `ApiService` reads the token and attaches it to every request via the `_authHeaders()` helper:

```dart
Future<Map<String, String>> _authHeaders() async {
  final token = await _storage.getToken();
  return {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}
```

On login, the token is saved automatically. On logout, it is cleared both server-side (via `POST /auth/logout`) and locally.

### Error Handling

All methods throw `ApiException` on failure. This is a custom exception class that carries a human-readable `message` and an optional `statusCode`:

```dart
class ApiException implements Exception {
  final String message;
  final int? statusCode;
}
```

Every HTTP call catches the following error types and wraps them in `ApiException`:

| Exception | Message |
|-----------|---------|
| `SocketException` | No internet connection |
| `TimeoutException` | Request timed out |
| `ClientException` | Could not connect to server |
| `FormatException` | Invalid response from server |

Callers (providers and screens) catch `ApiException` and display the message in a `SnackBar` or set it on an error state field.

### The `_getList` Helper

Most GET endpoints return a JSON array. Rather than repeating the same fetch-decode-map logic, `_getList` handles it generically:

```dart
Future<List<T>> _getList<T>(
  String path,
  T Function(Map<String, dynamic>) fromJson,
)
```

Usage is a one-liner per endpoint:

```dart
Future<List<User>> getFriends() => _getList('/friends/', User.fromJson);
Future<List<Category>> getCategories() => _getList('/categories/', Category.fromJson);
```

### Methods by Domain

#### Auth

| Method | HTTP | Endpoint | Returns |
|--------|------|----------|---------|
| `login(email)` | POST | `/auth/login` | `LoginResponse` (user + token) |
| `logout()` | POST | `/auth/logout` | void (clears token even if request fails) |

#### Users

| Method | HTTP | Endpoint | Returns |
|--------|------|----------|---------|
| `getUsers()` | GET | `/users/` | `List<User>` |
| `getUserById(userId)` | GET | `/users/{userId}` | `User` |
| `searchUsers(email)` | GET | `/users/search/{email}` | `List<User>` |
| `updateUserProfile(...)` | PUT | `/users/` | void |
| `getMyPinCount()` | GET | `/users/me/pin-count` | `int` |

#### Pins

| Method | HTTP | Endpoint | Returns |
|--------|------|----------|---------|
| `getPins({catIds, catLevelIds, pinExpireAt})` | GET | `/pins/` (with query params) | `List<Pin>` |
| `createPin(formData, {imageFile})` | POST (multipart) | `/pins/` | `Pin` |
| `reactToPin(pinId, value)` | PATCH | `/pins/{pinId}/react` | void |
| `deletePinReaction(pinId)` | DELETE | `/pins/{pinId}/react` | void |

#### Categories

| Method | HTTP | Endpoint | Returns |
|--------|------|----------|---------|
| `getCategories()` | GET | `/categories/` | `List<Category>` |
| `getCategoryLevels()` | GET | `/categories/levels` | `List<CategoryLevel>` |
| `getSubCategories()` | GET | `/categories/sub-categories` | `List<SubCategory>` |

#### Friends

| Method | HTTP | Endpoint | Returns |
|--------|------|----------|---------|
| `getFriends()` | GET | `/friends/` | `List<User>` |
| `getIncomingRequests()` | GET | `/friends/requests` | `List<FriendRequest>` |
| `getSentRequests()` | GET | `/friends/sent` | `List<FriendRequest>` |
| `sendFriendRequest(targetUserId)` | POST | `/friends/` | `FriendRequest` |
| `updateFriendRequest(relId, response)` | PATCH | `/friends/{relId}` | `FriendRequest` |
| `deleteFriendRequest(relId)` | DELETE | `/friends/{relId}` | void |

#### User Locations

| Method | HTTP | Endpoint | Returns |
|--------|------|----------|---------|
| `createOrUpdateUserLocation(lat, lng)` | POST | `/user-locations/` | `UserLocation` |
| `updateUserLocation({lat, lng, isEnabled})` | PATCH | `/user-locations/` | `UserLocation` |
| `getUserLocation()` | GET | `/user-locations/` | `UserLocation` |
| `deleteUserLocation()` | DELETE | `/user-locations/` | void |
| `getFriendsLocations()` | GET | `/user-locations/friends` | `List<UserLocation>` |

#### Location Permissions

| Method | HTTP | Endpoint | Returns |
|--------|------|----------|---------|
| `createLocationPermission(userId)` | POST | `/location-permissions/` | `LocationPermission` |
| `deleteLocationPermission(userId)` | DELETE | `/location-permissions/{userId}` | void |
| `getLocationPermissions()` | GET | `/location-permissions/` | `List<LocationPermission>` |

#### Invitation Codes

| Method | HTTP | Endpoint | Returns |
|--------|------|----------|---------|
| `createInvitationCode()` | POST | `/invitation-codes` | `InvitationCode` |
| `getInvitationCodes()` | GET | `/invitation-codes` | `List<InvitationCode>` |

### Adding a New Endpoint

To add a new API method:

1. If it returns a JSON array, use `_getList` with the model's `fromJson` factory
2. If it returns a single object or needs custom logic, follow the existing pattern: `_authHeaders()`, `_httpClient.verb(...)`, status code checks, wrap errors in `ApiException`
3. Add the corresponding model in `lib/models/` if one doesn't exist yet

```{note}
`createPin` is the only method that uses `MultipartRequest` instead of JSON. This is because the backend expects `Form(...)` fields plus an optional file upload. If you need to add another file-upload endpoint, follow the same pattern: build a `MultipartRequest`, attach fields as strings, attach files via `MultipartFile.fromBytes()`, and send with `.send()`.
```


## Screens

Each screen is a `StatefulWidget` in `lib/screens/`. This section describes what each one does and how it connects to the rest of the app.

### UserSelectionScreen

The login screen. Fetches all users from `GET /users/` and displays them as animated cards. Tapping a card calls `UserProvider.login(email)`, which authenticates with the backend and stores the token. On success, navigates to `HomeScreen` with a fade+slide transition.

Key details:
- Uses `FutureBuilder` to load the user list on init
- Shows a retry button if the API call fails
- Cards animate in with staggered delays (100ms per card)
- Hover effect on desktop (slight scale-up)

### HomeScreen

A thin wrapper that holds a `BottomNavigationBar` with two tabs: Map and Profile. Uses `IndexedStack` so both screens stay alive when switching tabs (the map doesn't reload every time you switch back).

### MapScreen

The main screen of the app. Displays an OpenStreetMap centred on the University of Portsmouth campus with pin markers, friend location markers, and controls for pin creation and filtering.

Key responsibilities:
- Loads pins from `GET /pins/` and renders them as coloured markers (colour from category level)
- Loads categories, category levels, and subcategories for the pin creation form and filter dialog
- Manages pin placement mode: tap map → confirm location → open `PinCreationSheet` → submit via multipart `POST /pins/`
- Shows pin detail bottom sheet on marker tap with title, description, image (if attached), author name, expiry countdown, category chips, and like/dislike buttons
- Pin images are tappable — opens a fullscreen viewer with `InteractiveViewer` for pinch-to-zoom
- Renders friend location markers (teal circle avatars) from `LocationProvider.friendLocations`, with tap-to-show-name tooltips
- Location sharing toggle FAB (bottom-left) calls `LocationProvider.toggleSharing()`
- Recenter FAB moves the map to the user's current GPS position
- Filter FAB opens a dialog to filter pins by category, category level, and expiry date
- Starts `LocationProvider.startPolling()` on init, stops on dispose
- Stores `LocationProvider` reference in a `late final` field to avoid accessing a deactivated widget's ancestor in `dispose()`
- Client-side filter hides expired pins (`pinExpireAt.isAfter(DateTime.now())`)

### ProfileScreen

Displays the current user's avatar, name, email, and pin count. Provides navigation to `FriendsScreen` and `InvitationCodesScreen`, plus a logout button.

Key responsibilities:
- Loads pin count from `GET /users/me/pin-count` on init
- Collapsible edit form for first name, last name, display name, and display name preference toggle
- Save calls `ApiService.updateUserProfile(...)`, then re-fetches the user to update `UserProvider`
- Logout clears all providers (`FriendProvider.clear()`, `LocationProvider.clear()`) and navigates back to `UserSelectionScreen`

### FriendsScreen

Three-tab screen (Friends, Incoming, Outgoing) with a search action in the app bar.

Key responsibilities:
- Friends tab: lists accepted friends with per-friend location sharing switches (reads `LocationProvider.permissions` to show toggle state)
- Incoming tab: shows pending requests with accept/reject/block buttons
- Outgoing tab: shows sent requests with a cancel button
- Search: `UserSearchDelegate` searches users by email (min 3 characters), shows results with an "Add Friend" button that handles all status codes (201 created, 204 already friends, 403 blocked, 422 validation error)
- Loads friends, requests, and location permissions via `addPostFrameCallback` on init

### InvitationCodesScreen

Lets users generate guest invitation codes and view their active codes.

Key responsibilities:
- Loads codes from `InvitationCodeProvider.loadCodes()` on init
- Generate button shows a confirmation dialog, then calls `createNewCode()`
- Handles 429 rate limit error (max 5 codes per week) with a red snackbar
- Each code card shows the code string, expiration text, and a copy-to-clipboard button
- Responsive layout: FAB on mobile, text button in app bar on wider screens

## Models

All models live in `lib/models/` and follow the same structure: a plain Dart class with a constructor, a `fromJson` factory, and (where needed) a `toJson` method.

### JSON Mapping

Every `fromJson` factory maps backend snake_case keys to Dart camelCase fields with explicit type casts:

```dart
factory User.fromJson(Map<String, dynamic> json) {
  return User(
    userId: json['user_id'] as int,
    firstName: json['user_fname'] as String,
    email: json['user_email'] as String,
    displayName: json['user_displayname'] as String?,
    useDisplayName: json['user_use_displayname'] as bool,
  );
}
```

The `as Type` casts are intentional — they catch bad data at parse time rather than letting it propagate silently through the app.

### Numeric Coordinates

GPS coordinates come from the backend as JSON numbers, which Dart may decode as `int` or `double` depending on the value. To handle both safely, coordinate fields cast via `num` first:

```dart
pinLatitude: (json['pin_latitude'] as num).toDouble(),
pinLongitude: (json['pin_longitude'] as num).toDouble(),
```

This pattern is used in `Pin` and `UserLocation`.

### Nullable Fields and Defaults

Optional fields use nullable types (`String?`, `int?`) and are parsed with `as Type?`. Some fields also provide defaults for safety:

```dart
pinLikes: json['pin_likes'] as int? ?? 0,
pinDislikes: json['pin_dislikes'] as int? ?? 0,
userReaction: json['user_reaction'] as int?,
```

### Computed Properties

Several models have getter properties that derive values from their fields:

| Model | Property | Description |
|-------|----------|-------------|
| `User` | `fullName` | `'$firstName $lastName'` |
| `Pin` | `pinColor` | Parses `pinColorHex` string to a Flutter `Color`, falls back to blue |
| `Pin` | `isExpired` | `DateTime.now().isAfter(pinExpireAt)` |
| `PinFormData` | `expiresAt` | `DateTime.now().add(Duration(minutes: ttlMinutes))` — computed at submission time |
| `InvitationCode` | `isActive` | `!isUsed && DateTime.now().isBefore(expiresAt)` |
| `InvitationCode` | `expirationText` | Human-readable relative time string ("Expires in 3 hours", "Expired") |

### Model Summary

| Model | `fromJson` | `toJson` | Computed Properties |
|-------|:----------:|:--------:|---------------------|
| `User` | yes | no | `fullName` |
| `Pin` | yes | yes | `pinColor`, `isExpired` |
| `PinReaction` | yes | no | — |
| `PinFormData` | no | yes | `expiresAt` |
| `Category` | yes | no | — |
| `CategoryLevel` | yes | no | — |
| `SubCategory` | yes | no | — |
| `FriendRequest` | yes | yes | — |
| `UserLocation` | yes | yes | — |
| `LocationPermission` | yes | yes | — |
| `InvitationCode` | yes | no | `isActive`, `expirationText` |

## Key Patterns and Conventions

This section documents recurring patterns used across the frontend codebase.

### `context.mounted` Checks

Any time an `async` method awaits a future and then uses `context` (e.g. to show a `SnackBar` or call `Navigator`), the code checks `mounted` or `context.mounted` first. This prevents the "deactivated widget's ancestor" crash if the user navigates away while the future is in flight:

```dart
await _apiService.updateUserProfile(...);
if (!mounted) return;
ScaffoldMessenger.of(context).showSnackBar(...);
```

### `addPostFrameCallback` for Provider Init

Providers that call `notifyListeners()` during initialisation (e.g. `LocationProvider.init()`) cannot be called directly in `initState()` because the widget tree is still building. Instead, the call is deferred:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<LocationProvider>().init();
  });
}
```

This pattern is used in `MapScreen`, `FriendsScreen`, and `InvitationCodesScreen`.

### Storing Provider References for `dispose()`

`context.read<T>()` is not safe to call in `dispose()` because the widget may already be deactivated. `MapScreen` solves this by storing the provider reference in a `late final` field during `initState`:

```dart
late final LocationProvider _locationProvider;

@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _locationProvider = context.read<LocationProvider>();
    _locationProvider.startPolling();
  });
}

@override
void dispose() {
  _locationProvider.stopPolling();
  super.dispose();
}
```

### Polling Timer

`LocationProvider` runs a 20-second periodic timer that pushes the user's GPS coordinates to the backend and refreshes friend locations. The timer is started when the map screen opens and stopped when it disposes. The `clear()` method also cancels the timer on logout.

### `clear()` on Logout

`FriendProvider` and `LocationProvider` each have a `clear()` method that resets all state to defaults. `UserProvider` resets via its `logout()` method instead. `ProfileScreen._logout()` calls all three before navigating back to the login screen:

```dart
context.read<FriendProvider>().clear();
context.read<LocationProvider>().clear();
await context.read<UserProvider>().logout();
```

This ensures no stale data leaks between user sessions.

### Constructor Injection for Testability

`ApiService`, `FriendProvider`, `LocationProvider`, and `InvitationCodeProvider` all accept their dependencies via constructor parameters. In production the defaults are used; in tests mocked versions can be passed in:

```dart
// Production
final api = ApiService();
final provider = FriendProvider();

// Testing
final api = ApiService(storage: mockStorage, httpClient: mockClient);
final provider = FriendProvider(apiService: mockApi);
```

### Image Upload (Pin Creation)

Pin creation supports an optional image attachment. The flow:

1. `PinCreationSheet` uses `image_picker` to let the user pick from gallery or take a photo (camera hidden on web via `kIsWeb` check)
2. The selected `XFile` is passed alongside `PinFormData` to the `onSubmit` callback
3. `ApiService.createPin()` builds a `MultipartRequest` with form fields as strings and the image as `MultipartFile.fromBytes()`
4. `XFile.readAsBytes()` is used instead of `fromPath()` so it works on both web and mobile platforms

### Pin Image Display

When a pin has an attached image (`pinPictureUrl` is not null), the pin detail bottom sheet shows it with:
- `Image.network` with loading spinner and error fallback
- `GestureDetector` wrapping the image — tap opens a fullscreen route
- Fullscreen viewer uses `InteractiveViewer` with `minScale: 0.5` and `maxScale: 4.0` for pinch-to-zoom
