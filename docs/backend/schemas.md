# Backend schemas

Pydantic schemas define the structure of data entering and leaving the API.

## Auth

**File:** `schemas/Auth.py`

### `LoginRequest`

Used as the request body for `POST /auth/login`.

| Field | Type | Notes |
|-------|------|-------|
| `email` | EmailStr | Must be a valid email address |

## User

**File:** `schemas/User.py`

### `UserUpdate`

Used as the request body for `PUT /users/me`.

| Field | Type | Notes |
|-------|------|-------|
| `user_fname` | String | Optional, max 60 characters |
| `user_lname` | String | Optional, max 60 characters |
| `user_display_name` | String | Optional, max 30 characters |
| `user_use_displayname` | Boolean | Optional |

### `UserResponse`

Returned by `GET /users/me` and user search endpoints.

| Field | Type | Notes |
|-------|------|-------|
| `user_id` | Integer | |
| `user_email` | String | |
| `user_fname` / `user_lname` | String | |
| `user_displayname` | String | Optional |
| `user_use_displayname` | Boolean | |
| `user_isactive` | Boolean | |
| `last_login` | DateTime | Optional |
| `created_at` | DateTime | |

### `UserLoginResponse`

Returned by `POST /auth/login`. Extends the user fields with an auth token and expiry.

| Field | Type | Notes |
|-------|------|-------|
| `token` | String | Bearer token for subsequent requests |
| `user_id` | Integer | |
| `user_fname` / `user_lname` | String | |
| `user_email` | String | |
| `user_displayname` | String | Optional |
| `user_use_displayname` | Boolean | |
| `user_isactive` | Boolean | |
| `last_login` | DateTime | Optional |
| `created_at` | DateTime | |
| `expires_at` | DateTime | Optional — only set for guest accounts |

## Pin

**File:** `schemas/Pin.py`

### `PinCreate`

Used as the request body for `POST /pins`.

| Field | Type | Notes |
|-------|------|-------|
| `pin_title` | String | Required, max 100 characters |
| `pin_latitude` / `pin_longitude` | Float | GPS coordinates |
| `cat_id` | Integer | Required — must be a valid category ID |
| `sub_cat_id` | Integer | Optional subcategory |
| `pin_expire_at` | DateTime | When the pin should expire |
| `pin_description` | String | Optional, max 300 characters |

### `PinUpdate`

Used as the request body for `PUT /pins/{pin_id}`. All fields are optional.

| Field | Type | Notes |
|-------|------|-------|
| `pin_title` | String | Optional, max 100 characters |
| `pin_description` | String | Optional, max 300 characters |
| `pin_expire_at` | DateTime | Optional |

### `PinResponse`

Returned by `GET /pins` and `GET /pins/{pin_id}`.

| Field | Type | Notes |
|-------|------|-------|
| `pin_id` | Integer | |
| `cat_id` / `sub_cat_id` | Integer | `sub_cat_id` is optional |
| `user_id` | Integer | |
| `pin_title` | String | |
| `pin_description` | String | Optional |
| `pin_picture_url` | String | Optional — full URL to uploaded image |
| `pin_latitude` / `pin_longitude` | Float | |
| `pin_isactive` | Boolean | |
| `pin_expire_at` | DateTime | |
| `created_at` | DateTime | |
| `pin_color` | String | Hex colour derived from the category level |
| `pin_author_name` | String | Display name or full name of the creator |
| `pin_likes` / `pin_dislikes` | Integer | Computed reaction counts |
| `user_reaction` | Integer | `1`, `-1`, or `null` — the current user's reaction |

### `PinReactionRequest`

Used as the request body for `POST /pins/{pin_id}/react`.

| Field | Type | Notes |
|-------|------|-------|
| `value` | Literal[1, -1] | `1` for like, `-1` for dislike |

## Category

**File:** `schemas/Category.py`

### `CategoryLevelResponse`

Returned by `GET /categories/levels`.

| Field | Type | Notes |
|-------|------|-------|
| `cat_level_id` | Integer | |
| `cat_level_name` | String | e.g. `Danger`, `Warning`, `Information` |
| `cat_level_ttl_mins` | Integer | Default pin lifetime in minutes for this level |
| `cat_level_color` | String | Hex colour code |

### `CategoryResponse`

Returned by `GET /categories`.

| Field | Type | Notes |
|-------|------|-------|
| `cat_id` | Integer | |
| `cat_level_id` | Integer | FK to category level |
| `cat_name` | String | |

### `SubCategoryResponse`

Returned by `GET /categories/{cat_id}/sub-categories`.

| Field | Type | Notes |
|-------|------|-------|
| `sub_cat_id` | Integer | |
| `cat_id` | Integer | FK to parent category |
| `sub_cat_name` | String | |

## Friend

**File:** `schemas/Friend.py`

### `FriendCreate`

Used as the request body for `POST /friends`.

| Field | Type | Notes |
|-------|------|-------|
| `target_user_id` | Integer | The user to send a request to |

### `FriendUpdate`

Used as the request body for `PATCH /friends/{rel_id}`.

| Field | Type | Notes |
|-------|------|-------|
| `response` | Literal | `accepted`, `rejected`, or `blocked` |

### `FriendResponse`

Returned by friend list and request endpoints.

| Field | Type | Notes |
|-------|------|-------|
| `user_rel_id` | Integer | |
| `user_id` | Integer | The user who sent the request |
| `target_user_id` | Integer | The user who received the request |
| `user_rel_status` | String | Current status of the relationship |
| `created_at` / `updated_at` | DateTime | |

## Invitation Code

**File:** `schemas/Invitation.py`

### `LoginWithCodeRequest`

Used as the request body for `POST /auth/login/code`.

| Field | Type | Notes |
|-------|------|-------|
| `code` | String | The 12-character invitation code |

### `InvitationCodeResponse`

Returned by `GET /invitation-codes` and `POST /invitation-codes`.

| Field | Type | Notes |
|-------|------|-------|
| `id` | Integer | |
| `creator_id` | Integer | The user who generated the code |
| `code` | String | The 12-character invite code |
| `guest_user_id` | Integer | Optional — set once the code is redeemed |
| `created_at` / `expires_at` | DateTime | Code expires 24 hours after creation |
| `is_used` | Boolean | True once redeemed |

## Location Sharing

### `CreateUserLocation`

**File:** `schemas/UserLocation.py` — used as the request body for `POST /user-locations`.

| Field | Type | Notes |
|-------|------|-------|
| `latitude` / `longitude` | Float | Initial GPS coordinates |

### `UpdateUserLocation`

Used as the request body for `PATCH /user-locations/{id}`. All fields are optional.

| Field | Type | Notes |
|-------|------|-------|
| `latitude` / `longitude` | Float | Optional updated coordinates |
| `is_enabled` | Boolean | Optional — toggle location sharing on or off |

### `UserLocationResponse`

Returned by user location endpoints.

| Field | Type | Notes |
|-------|------|-------|
| `user_loc_id` | Integer | |
| `user_id` | Integer | |
| `latitude` / `longitude` | Float | |
| `is_enabled` | Boolean | |
| `created_at` / `updated_at` | DateTime | |
| `city` / `street` | String | Optional — reverse-geocoded address fields |

### `CreateLocationPermission`

**File:** `schemas/LocationPermission.py` — used as the request body for `POST /location-permissions`.

| Field | Type | Notes |
|-------|------|-------|
| `user_id` | Integer | The friend to grant location access to |

### `LocationPermissionResponse`

Returned by location permission endpoints.

| Field | Type | Notes |
|-------|------|-------|
| `loc_perm_id` | Integer | |
| `user_loc_id` | Integer | FK to the location record being shared |
| `user_id` | Integer | The friend who has been granted access |
| `created_at` / `updated_at` | DateTime | |

## Pin Reporting

**File:** `schemas/pin_reporting.py`

### `PinReportRequest`

Used as the request body for `POST /pins/{pin_id}/report`.

| Field | Type | Notes |
|-------|------|-------|
| `report_type` | PinReportType | One of `inaccurate`, `resolved`, `duplicate`, `expired`, `misleading`, `spam`, or `inappropriate` |

### `PinReportResponse`

Returned after a report is filed.

| Field | Type | Notes |
|-------|------|-------|
| `pin_report_id` | Integer | |
| `user_id` | Integer | |
| `report_type` | String | |
| `created_at` | DateTime | |