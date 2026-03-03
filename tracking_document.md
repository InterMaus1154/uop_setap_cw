# setap - Work Tracking Document (will make it easier for claudia)

Use this document to log your contributions. Add new entries at the top.

---

## Entry Template

```
### [Your Name and up number] - [Date] [Time]
**Summary:** Brief description of what you did

**Files Modified/Created:**
- path/to/file1
- path/to/file2

**Notes:** Any additional context
```

---

## Entries

### Josh up2255832 - 03/03/2026
**Summary:** Built friend location sharing frontend — friends can see each other's live location on the map with toggleable sharing. Created Dart models for UserLocation and LocationPermission, added ApiService methods for location and permission endpoints, built LocationProvider with GPS integration and 20s polling, registered provider in widget tree, added friend markers (teal avatars with initials and name tooltips) and share toggle FAB to map screen, added per-friend permission switches to friends screen. Fixed 404 handling for users without location records, build context lint warning, and setState-during-build crash.

**Files Created:**
- frontend/lib/models/user_location.dart
- frontend/lib/models/location_permission.dart
- frontend/lib/providers/location_provider.dart

**Files Modified:**
- frontend/lib/services/api_service.dart (added 8 location/permission API methods)
- frontend/lib/screens/map_screen.dart (friend markers, share toggle FAB, polling lifecycle)
- frontend/lib/screens/friends_screen.dart (per-friend location sharing switches)
- frontend/lib/main.dart (registered LocationProvider, added clear on logout)
- frontend/lib/screens/profile_screen.dart (clear LocationProvider on logout)
- frontend/pubspec.yaml (added geolocator package)

**Notes:** Backend location endpoints were built by Julian. Frontend wires up to all of them. Friend markers show teal circle avatars with the friend's initial, tap to see their name. Share toggle FAB (bottom-left of map) enables/disables your own location sharing. Per-friend switches on the friends list control who can see you. Polling refreshes friend positions every 20 seconds. 404s from the backend (no location record yet) are handled gracefully as empty state.

---

### Julian up2301253 - 01/03/2026
**Description: Location Sharing**
- Added user location sharing endpoints for storing and updating user GPS coordinates
- Added location permissions endpoints for sharing location with specific friends
- Added endpoint to retrieve friends who are sharing their location with the logged-in user

**Files Created:**
- backend/models/user_location.py
- backend/models/location_permission.py
- backend/schemas/UserLocation.py
- backend/schemas/LocationPermission.py
- backend/routes/user_locations.py

---

### Theodore up2282406 - 01/03/2026 
**Summary:** Added toggle functionality for displaying pin author name. Users can choose whether their display name is shown on pins.

**Files Modified/Created:**
- frontend/lib/widgets/pin_card.dart 

**Notes:**
- Implemented backend logic to store user preference for showing display name.
- Updated pin model and API to respect user’s display name setting.
- Added toggle control in frontend for users to set their preference.
-Added a boolean field to the user or pin model to store display name preference.
- Tested with different user settings to ensure correct display.
-Once again , the preferences were not showing that they were actually being saved , but Josh came to the rescue and resolved it , I beleive it had to do with slight issues in the backend


### Julian up2301253 - 01/03/2026
**Description: Invitation Codes**
- Added invitation codes feature allowing registered users to generate 12-character invite codes for guests
- Added guest login via invitation code with automatic guest account creation (24hr expiry)
- Restricted code generation to 5 per week per user

**Files Created:**
- backend/models/invitation_code.py
- backend/schemas/InvitationCode.py
- backend/routes/invitations.py

**Files Modified:**
- backend/main.py
- backend/models/__init__.py

--

### Luke up2264308 - 01/03/2026
**Summary** 
Added pin filtering based on expiry date so that you can put a date in and then have it only show the pins that expire before or on that date 
**Files Modified** 
- frontend/lib/screens/map_screen.dart
- frontend/services/api_service.dart

### Josh up2255832 - 01/03/2026
**Summary:** Fixed Theo's profile editing bug — changes to name/display name weren't saving. Fixed frontend API calls (wrong HTTP method, wrong endpoint, wrong field names), backend schema (missing field, truthy checks), and profile screen UI (duplicate save button, broken validation, state overwrite on rebuild). Restyled profile screen with collapsible edit form. Added backend and frontend tests to catch regressions.

**Files Modified:**
- frontend/lib/screens/profile_screen.dart (fixed all UI bugs, restyled with collapsible edit form)
- frontend/lib/services/api_service.dart (fixed updateUserProfile to use PUT /users/ with correct field names, removed updateUserDisplayNamePreference)
- backend/schemas/User.py (added user_use_displayname to UserUpdate)
- backend/routes/users.py (fixed truthy checks, added user_use_displayname handling)
- backend/requirements.txt (added hypothesis, httpx)
- .gitignore (added .hypothesis/)

**Files Created:**
- backend/tests/test_profile_update_bugs.py (4 backend bug condition tests)
- backend/tests/test_profile_preservation.py (4 backend preservation tests including property-based)
- frontend/test/screens/profile_screen_bugs_test.dart (2 frontend widget tests)

---

### Mark up2306492 - 27/02/2026

**Description:**
- added pin_expire_at filter for `GET /pins` that filters pins based on pin_expire_at, where expire_at <= selected expire_at
- refined Josh's `pin_author_name` property on `pin` model to show displayname only if user said so

**Files modified:**
- backend/models/pin.py
- backend/routes/pins.py

### Mark up2306492 - 26/02/2026

**Description:**
- explored how to do API testing in Python
- installed pytest as a package
- created a test demo for authentication endpoints which we can use as a "template" for later testing
- added a test user that can be used for testing, making testing more easy

**Files Created:**
- backend/tests/base.py
- backend/tests/test_auth.py
- backend/tests/test_demo.py
- backend/conftest.py

### Josh up2255832 - 26/02/2026 (busy busy coding day for me today!)
**Summary:** Added unit tests for friends feature — FriendRequest model, FriendProvider, and ApiService friend methods (25 tests). Refactored ApiService and FriendProvider to accept dependencies via constructor injection so mocked HTTP client and storage can be passed in tests. Removed singleton pattern from SecureStorageService to make it mockable — no functional impact since FlutterSecureStorage is stateless and all instances read/write the same OS keychain.

**Files Created:**
- frontend/test/models/friend_request_test.dart (6 tests: fromJson, toJson, round-trip, all statuses, missing field, bad date)
- frontend/test/providers/friend_provider_test.dart (3 tests: initial state, clear resets state, clear notifies listeners)
- frontend/test/services/api_service_friends_test.dart (16 tests: getFriends, searchUsers, getIncomingRequests, getSentRequests, sendFriendRequest with 201/204/403/422, updateFriendRequest with 200/403/404, deleteFriendRequest with 204/403/404)

**Files Modified:**
- frontend/lib/services/api_service.dart (constructor injection for http.Client and SecureStorageService, replaced top-level http calls with injected client)
- frontend/lib/providers/friend_provider.dart (constructor injection for ApiService)
- frontend/lib/services/secure_storage_service.dart (removed singleton pattern, plain constructor for mockability)
- frontend/pubspec.yaml (added mockito and build_runner dev dependencies)

---

### Josh up2255832 - 26/02/2026
**Summary:** Implemented friends feature frontend — FriendRequest model, ApiService friend methods, FriendProvider state management, FriendsScreen with tabs (friends list, incoming/outgoing requests), UserSearchDelegate with add friend flow and status code handling, profile screen integration. Also fixed backend UserLocation back_populates bug.

**Files Created:**
- frontend/lib/models/friend_request.dart
- frontend/lib/providers/friend_provider.dart
- frontend/lib/screens/friends_screen.dart

**Files Modified:**
- frontend/lib/services/api_service.dart (added 7 friend-related API methods)
- frontend/lib/screens/profile_screen.dart (added Friends button, clear provider on logout)
- frontend/lib/main.dart (switched to MultiProvider with FriendProvider)
- backend/models/user_location.py (fixed back_populates from plural to singular)

**Notes:** Backend friend endpoints were already built by Julian. Frontend wires up to all of them: friend list, search, send/accept/reject/block/cancel requests. UserSearchDelegate handles all response codes (201/204/403/422). FriendProvider resolves user names via parallel lookups with caching.

---

### Josh up2255832 - 25/02/2026
**Summary:** Wrote installation documentation for ReadTheDocs

**Files Modified/Created:**
- docs/installation.md (full developer installation guide covering backend, frontend, all OS platforms, troubleshooting)
- docs/conf.py (added sphinx_design extension and colon_fence for tabbed content)
- docs/requirements.txt (added sphinx-design dependency)

---

### Mark up2306492 - 25/02/2026

**Description:**
- added user_locations and location_permissions tables to ERD (erd image updated)
- created UserLocation and LocationPermission models in Python
- created pydantic schemas for both new models

**Files created**
- backend/models/user_location.py
- backend/models/location_permission.py
- database/erd2.jpg
- backend/schemas/UserLocation.py
- backend/schemas/LocationPermission.py

### Mark up2306492 - 24/02/2026

**Description:** Fix pin filtering to work with or logic (minor bug)

**Files modified:**
- backend/routes/pins.py


### Theodore up2282406 - 23/02/2026
**Summary:** Added like and dislike buttons to the frontend pin display. Implemented interactive UI for users to react to pins, with status saved and reflected in the backend.

**Files Modified/Created:**
- frontend/lib/widgets/pin_card.dart
- frontend/lib/screens/pins_screen.dart
- frontend/lib/services/pin_service.dart
- backend/routes/pins.py (if backend API was updated)

**Notes:**
- Created like/dislike buttons with visual feedback for selected state.
- Connected buttons to API endpoints to save user reactions.
- Updated pin UI to show current reaction status for each user.
- Handled optimistic UI updates and error states.
- Ensured backend saves and returns reaction status correctly.
- when i had finished coding , there were still issues with the likes/dislikes not saving , Josh helped out to make sure this was resolved with Testing  multiple users and edge cases (e.g., toggling reactions, removing reaction).



### Julian up2301253 - 23/02/2026
**Description:** Added /sent and /blocked endpoints and updated code to match spec.

**File(s) Modified:**
- backend/routes/friends.py
- backend/schemas/Friend.py

---

### Luke up2264308 - 23/02/2026
**Summary** Added pin filtering on the frontend based on categories and category levels 

**Files modified**
- frontend/lib/screens/map_screen.dart
- frontend/services/api_service.dart


### Josh up2255832 - 23/02/2026
**Summary:** Code review and fix of Theo's pin reactions frontend implementation

**Files Modified:**
- frontend/lib/services/api_service.dart (added auth headers to _getList so GET /pins/ sends token for user_reaction, added proper error handling/timeouts to reactToPin and deletePinReaction, moved methods to correct position in class)
- frontend/lib/screens/map_screen.dart (moved reaction state variables outside StatefulBuilder so they persist across rebuilds, added try/catch around reaction API calls with user-facing error snackbar, removed hardcoded isLoggedIn dead code, added state sync back to _pins list after successful reaction)
- backend/main.py (added PATCH to CORS allowed methods — preflight OPTIONS requests were returning 400)

**Notes:** Reactions were failing for three reasons: CORS config didn't allow PATCH method (400 on preflight), _getList didn't send auth headers so user_reaction was always null, and StatefulBuilder reinitialised state variables on every rebuild which wiped out UI updates. Also added missing error handling that was absent from the original implementation.

---

### Josh up2255832 - 21/02/2026
**Summary:** Pin details now show author name instead of user ID

**Files Modified:**
- backend/models/pin.py (added pin_author_name property, returns display name or first name for privacy)
- backend/schemas/Pin.py (added pin_author_name to PinResponse)
- backend/routes/pins.py (added joinedload for user relationship on pin queries)
- frontend/lib/models/pin.dart (added pinAuthorName field)
- frontend/lib/screens/map_screen.dart (pin detail sheet shows "Posted by [name]" instead of "user #id")
- frontend/lib/services/api_service.dart (added getUserById method)

**Notes:** Previously showed raw user ID on pin details. Now resolves to display name if set, otherwise first name only (last name excluded for privacy).

---


### Mark up2306492 - 21/02/2026
**Summary:** Implemented reacting with pins

**Details:**
- added PATCH /pins/{pin_id}/react endpoint to create or update an interaction
- added DELETE /pins/{pin_id}/react endpoint to delete an existing interaction between a user and a pin
- added pin_likes and pin_dislikes properties on Pin model and on PinResponse
- added user_reaction property on Pin model and on PinResponse to show how a user interacted (or not) with a pin
- more details in issue [#13](https://github.com/InterMaus1154/uop_setap_cw/issues/13)

**Files modified:**
- backend/routes/pins.py (added endpoints)
- backend/models/pin.py (added properties on model)
- backend/middleware/auth.py (added optional_auth that is needed for user_reaction property)
- backend/schemas/Pin.py (added extra fields on PinResponse)

### Josh up2255832 - 19/02/2026
**Summary:** Implemented pin colour coding on map using backend hex colours from category levels

**Files Modified:**
- frontend/lib/models/pin.dart (added pinColorHex field and pinColor getter for hex-to-Color conversion)
- frontend/lib/screens/map_screen.dart (map markers and category chips now use pin colour from API)

**Notes:** Mark added cat_level_color to the backend, each pin response now includes pin_color as a hex string. Frontend parses it and applies it to markers and detail sheet chips. Falls back to blue if colour is missing.

---

### Julian up2301253 - 19/02/2026
**Description:** Added error handling for blocked and and accepted relationship states. Also added permission checks, ensuring only users involved in a relationship can update it.

**File(s) Modified:**
- backend/routes/friends.py

---

### Mark up2306492 - 19/02/2026
**Summary:** Worked on categories and seeding for them

**Details:**
- Added color for category_level as cat_level_color
- Added more categories to what Luke has already one
- Added more subcategories for new categories
- Added extra pins and refined existing ones made by Luke
- Modified pin model, so it returns pin color as well
- Added check for correct sub_cat_id during pin creation

**Files modified:**
- backend/schemas/Pin.py (added pin_color to PinResponse)
- backend/models/pin.py (added pin_color as property on the model)
- backend/routes/pins.py (added loading categories to fetch pin colors)
- backend/database/seed.py (worked on category levels, categories, subcategories and pinseeder (refined what Luke already had there))


### Josh up2255832 - 18/02/2026
**Summary:** Added profile page with bottom nav, pin count endpoint

**Files Created:**
- frontend/lib/screens/profile_screen.dart (profile page with avatar, name, email, pin count, logout)

**Files Modified:**
- frontend/lib/screens/home_screen.dart (converted to bottom nav bar with Map and Profile tabs)
- frontend/lib/screens/map_screen.dart (removed top bar, cleaned up unused imports)
- frontend/lib/services/api_service.dart (added getMyPinCount method)
- backend/routes/users.py (added GET /users/me/pin-count endpoint)

**Notes:** Forgot to git pull before merging to master, caused divergent branches with Julian's friend  commits. Resolved with a merge commit, no work lost. Lesson learned  always pull before merging lol.

---

### Julian up2301253 - 18/02/2026
**Description:** Added Friend.py schema and friend.py endpoints to allow ability to send, accept, and reject friend requests and delete friends from list.

**Files Created:**
- backend/schemas/Friend.py
- backend/routes/friends.py

---

### Theodore up2282406 - 18/02/2026

**Summary:** Implemented frontend and backend logic for displaying pins to users. Integrated API to fetch pins and render them in the UI. Added loading and error states for better user experience.

**Files Modified/Created:**
-  frontend/lib/screens/pins_screen.dart
- frontend/lib/widgets/pin_card.dart
- backend/routes/pins.py
- backend/models/pin.py

**Notes:** Used API endpoint to fetch pins and display them. Added error handling/loading state. 
- Mapped backend pin model to frontend display format.
- Added pagination and filtering for pins.
- Ensured pins are only shown if not expired.
- Improved UI with pin details, author info, and reaction buttons.
-Verified pin display works on web and mobile platforms.
- Tested with sample data and handled edge cases, Added error message for failed pin fetches. (e.g., no pins available).




### Josh up2255832 - 18/02/2026
**Summary:** Code reviewed and fixed pin display on map, improved pin detail sheet

**Files Modified:**
- frontend/lib/screens/map_screen.dart (removed dead _pinsLoaded variable, added loading indicator, styled pin detail bottom sheet to match creation sheet, added category/subcategory chips, formatted expiry as relative time, added placement mode guard on pin taps, clientbside expired pin filter, fixed RenderFlex overflow on narrow screens)

**Issues encountered and resolved:**
1. Dead code, _pinsLoaded was set but never read, replaced with _isLoadingPins driving a spinner
2. Pin detail sheet was unstyled and inconsistent with creation sheet, added drag handle, rounded corners, matching layout
3. Raw DateTime shown for expiry, formatted as readable time
5. RenderFlex overflow on small screens, wrapped text in Expanded with ellipsis overflow
6. Category/subcategory not shown on pin details, added chip display with lookup from cached data

**Notes:** Categories now load on map, so they're available when tapping pins. will discuss colour coding with team

---

### Josh up2255832 - 17/02/2026
**Summary:** Cleaned up redundant user_id from pin creation after reviewing backend changes

**Files Modified:**
- frontend/lib/services/api_service.dart (removed userId parameter from createPin, backend now derives it from auth token)
- frontend/lib/screens/map_screen.dart (removed userId lookup before createPin call)

**Notes:** POST /pins/ endpoint correctly pulls user_id from the authenticated token server-side, so passing it from the frontend was redundant. Also reviewed new pin filtering (GET /pins?cat_id=1&cat_level_id=2) — will be useful for map category filtering later.

---

### Mark up2306492 - 17/02/2026
**Summary:** Pin filtering and additional user endpoints

**Details:** 
- Pins can be filtered now using cat_id or cat_level_id, or both, and multiple, so for example `GET /pins?cat_id=1&cat_level_id=2&cat_id=3`
- Added `GET /users/me` endpoint for getting the profile information of a user
- Added `PUT /users` endpoint for updating the `user_fname` `user_lname` and `user_displayname` fields. (GitHub issue #9)
- Fixed that `last_login` timestamp wasn't being updated in the database upon login, now it is
- Added `PATCH /users/deactivate` endpoint, allowing a user to deactivate their account
- Fixed `GET /users/search/{email}` endpoint, now it allows to search by partial match and returns a list of users
- (Deleted some of my older branches on GH for cleanup)

**Files modified:**
- backend/routes/pins.py (added filtering for get_pins function)
- backend/routes/users.py (added new endpoints)
- backend/routes/auth.py (added that last_login timestamp is automatically updated in the database after login)

### Josh up2255832 - 16/02/2026
**Summary:** Integrated frontend authentication with backend token-based auth system

**Files Modified:**
- frontend/lib/services/api_service.dart (added login/logout methods, Bearer token auth headers, LoginResponse class, 401/403 error handling)
- frontend/lib/providers/user_provider.dart (replaced manual setUser with async login/logout via API, added isLoading state)
- frontend/lib/screens/user_selection_screen.dart (user selection now calls POST /auth/login, async with error handling)
- frontend/lib/screens/map_screen.dart (logout now calls POST /auth/logout before clearing local state)

**Notes:** Frontend auth is now fully wired to Mark's backend auth system. User selection calls login endpoint, receives token, stores it via SecureStorageService (which Mark created). All authenticated requests (pin creation, logout) send Bearer token in headers. Token is cleared both server-side and locally on logout. Tested full flow: login → create pin (authenticated) → logout → back to user selection.

---

### Mark up2306492 - 16/02/2026

**Summary**: Created backend authentication, simple login and logout and middleware for validating authenticated user

**Files created**
- backend/middleware/auth.py
- backend/routes/auth.py

### Josh up2255832 - 12/02/2026 (nearly midnight)
**Summary:** Created backend category endpoints and wired up full frontend API integration for pin creation

**Files Created:**
- backend/schemas/Category.py (Pydantic response schemas for CategoryLevel, Category, SubCategory)
- backend/routes/categories.py (GET /categories/, GET /categories/levels, GET /categories/sub-categories, GET /categories/{cat_id}/sub-categories)

**Files Modified:**
- backend/main.py (registered categories router)
- frontend/lib/services/api_service.dart (added getCategories, getCategoryLevels, getSubCategories, createPin methods, extracted generic _getList helper)
- frontend/lib/widgets/pin_creation_sheet.dart (removed hardcoded mock data, now accepts categories/levels/subcategories via constructor, added null check on TTL)
- frontend/lib/screens/map_screen.dart (fetches category data from API, lazy-loaded and cached, pin creation now calls POST /pins/ with logged-in user ID)

**Issues encountered and resolved:**
1. Force unwrap on _ttlMinutes could crash if category level data was inconsistent  added null check with user-facing snackbar fallback

**Notes:** Pin creation is now fully end to end: user taps map  selects location fills form (categories fetched from DB)  pin saved to database via POST /pins/. Tested and confirmed working. Julian created most endpoints,  I created the backend category endpoints myself as they were simple read only GETs and I needed them to unblock frontend work.

---
### Julian up2301253 - 11/02/2026
**Description:** Added Pin.py schema and some pins.py endpoints to enable frontend pin creation, editing and, displaying pins.

**Files Created:**
- backend/schemas/Pin.py
- backend/routes/pins.py


### Josh up2255832 - 06/02/2026
**Summary:** Built pin creation form UI with bottom sheet, tap-to-place flow, category-based auto-expiry, and performed strict code review with fixes

**Files Created:**
- frontend/lib/widgets/pin_creation_sheet.dart (bottom sheet form with category/subcategory dropdowns, title, description, auto TTL display)
- frontend/lib/models/pin_form_data.dart (extracted data class for form submission, includes toJson for API)

**Files Modified:**
- frontend/lib/screens/map_screen.dart (pin placement mode, tap-to-place marker, confirm location flow, bottom sheet integration, added MapController dispose)
- frontend/lib/models/category.dart (renamed catLevelPins to catLevelTtlMins to match backend schema, added explicit type casting in fromJson)
- frontend/lib/models/pin.dart (added explicit type casting in fromJson for null safety)
- frontend/lib/models/user.dart (added explicit type casting in fromJson)
- frontend/lib/services/api_service.dart (added TimeoutException handling, extracted timeout to constant)
- frontend/lib/screens/user_selection_screen.dart (fixed _getInitials to handle empty strings)

**Issues encountered and resolved:**
1. Dropdown assertion error when switching categories — subcategory dropdown held stale state. Fixed by adding ValueKey to force widget rebuild.
2. Deprecated `value` parameter in DropdownButtonFormField (Flutter 3.33+) — removed deprecated usage.
3. `firstWhere` in _ttlMinutes could throw if no matching level found — added try-catch with graceful fallback.
4. JSON parsing had no null safety — added explicit `as Type` casts to all model fromJson methods to catch bad data at parse time.
5. TimeoutException not caught in ApiService — added explicit catch block.
6. MapController memory leak — added dispose() method.
7. _getInitials crash on empty firstName/lastName — added defensive checks with '?' fallback.

**Notes:** Pin creation is fully functional UI-wise but does NOT save to database — purely mock/testing. Categories and subcategories are hardcoded to match seed data. Auto-expiry calculates from category level TTL (Danger=60min, Information=120min, Level 3=180min). All frontend model JSON keys verified to match backend column names exactly.

**Backend team action needed:** To complete this feature, please create:
1. `routes/pins.py` with `GET /pins/` and `POST /pins/` endpoints
2. `routes/categories.py` with `GET /categories/`, `GET /category-levels/`, `GET /sub-categories/` endpoints
3. Register routers in `main.py`

Once endpoints exist, I can wire up the API calls and remove hardcoded data.

---

### Josh up2255832 - 03/02/2026
**Summary:** Built out frontend models and map screen in preparation for backend endpoints

**Files Modified/Created:**
- frontend/lib/models/category.dart (CategoryLevel, Category, SubCategory models)
- frontend/lib/models/pin.dart (Pin, PinReaction models with safe num to double casting for coordinates)
- frontend/lib/screens/home_screen.dart (wrapper for MapScreen)
- frontend/lib/screens/map_screen.dart (OpenStreetMap integration, campus centered on Portsmouth, recenter button, logout flow, placeholder for pin creation)

**Notes:** Read the erd, frontend models are aligned with backend DB schema and ready for API integration. Added defensive casting for latitude/longitude to handle int/double JSON inconsistencies.(this issue was alerted from a code review by the flutter discord community) Map screen has UI scaffolding, just needs pin fetching and creation endpoints wired up.

---


### Luke up2264308 - 06/02/2026
**Summary** Added sample data in the database to allow for easier testing of things such as sample users, categories, pins, etc.

**Files Modified/Created:**
- backend/database/seed.py

### Josh up2255832 - 31/01/2026 
**Summary:** Created test user flow branch with fake login system for UI testing

**Files Modified/Created:**
- frontend/lib/main.dart
- frontend/lib/models/user.dart
- frontend/lib/providers/user_provider.dart
- frontend/lib/services/api_service.dart
- frontend/lib/screens/user_selection_screen.dart
- frontend/lib/screens/home_screen.dart
- backend/main.py (added CORS, included users router) sorry for fiddling with backend mark XD 

**Notes:** Users can select from DB users to "login" without OAuth. Placeholder for map screen. minor work i did on the backend -  CORS properly configured, Router included correctly
questions i asked: could the user_selection_screen be split to remove a single long file, i asked the flutter discord and they informed me that there is no need. 
---

### Mark up2306492 - 28-29/01/2026
**Summary**: Set up backend with models and basic routes
**Details**: I have set up the Python backend - continued from Josh's template -, and connected our database, created models that can be used to interact with database entities more easily. Created a migration/seed template, that will enable us for easier testing and ensuring the database can be easily reset to a working state.

### Mark up2306492 - 28/01/2026
**Description**: I have created our conceptual design and ERD for the database in Miro.
