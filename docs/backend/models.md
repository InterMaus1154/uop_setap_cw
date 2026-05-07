# Backend models

Information covering the backend python models, mapped to tables in the PostgreSQL database using SQLAlchemy ORM.

## User

Represents an app user. The `user_token` field is how the authentication works, when a user logs in, a token is stored here and matched on each request.

**Table:** `users`

| Column | Type | Notes |
|--------|------|-------|
| `user_email` | String | Unique — used to identify the account |
| `user_fname` / `user_lname` | String | First and last name |
| `user_displayname` | String | Optional public name shown on pins |
| `user_use_displayname` | Boolean | If true, show display name instead of real name |
| `user_token` | String | Set on login, cleared on logout |
| `user_isactive` | Boolean | False if the account has been deactivated |

**Relationships:** A user can have many pins, reactions, and reports and messages.
The `friends` property returns users with an `ACCEPTED` relationship in either direction.

## Pin

Represents a pin placed on the map by a user, storing its location, category and expiry time.

**Table:** `pins`

| Column | Type | Notes |
|--------|------|-------|
| `cat_id` | Integer | FK — which category the pin belongs to |
| `sub_cat_id` | Integer | FK — optional subcategory |
| `user_id` | Integer | FK — the user who created it |
| `pin_title` | String | Max 100 characters |
| `pin_description` | String | Optional, max 300 characters |
| `pin_latitude` / `pin_longitude` | Float | GPS coordinates of the pin |
| `pin_picture_path` | String | File path to uploaded image, if any |
| `pin_isactive` | Boolean | False once expired or manually removed |
| `pin_expire_at` | DateTime | When the pin stops appearing on the map |

**Relationships:** A pin belongs to one User and one Category. It can also have a SubCategory (optional). A pin can have many PinReactions and many PinReports.

## Category, CategoryLevel, SubCategory

Represents the selected, predefined category by a user when creating a pin. Three models form a hierarchy: CategoryLevel (severity tier), Category (type of incident), SubCategory (specific detail). E.g., Danger, Assault, Stabbing.

### Category (`categories`)

| Column | Type | Notes |
|--------|------|-------|
| `cat_level_id` | Integer | FK — severity tier for pin |
| `cat_name` | String | Max 60 characters |

### SubCategory (`sub_categories`)

| Column | Type | Notes |
|--------|------|-------|
| `cat_id` | Integer | FK — the category this belongs to |
| `sub_cat_name` | String | Max 60 characters |

### CategoryLevel (`category_levels`)

Defines the severity tiers for categories. Each level has a display colour and a default expiry duration applied to pins in that tier.

| Column | Type | Notes |
|--------|------|-------|
| `cat_level_name` | String | Unique name e.g. Information, Warning, Danger |
| `cat_level_color` | String | Hex colour code used to colour pins on the map |
| `cat_level_ttl_mins` | Integer | Default pin lifetime in minutes for this tier |

## UserRelationship

Tracks friend requests and their status between two users. `user_id` is the person who sent the request, `target_user_id` is the recipient. A unique constraint prevents duplicate pairs, and a check constraint prevents a user adding themselves.

**Table:** `user_relationships`

| Column | Type | Notes |
|--------|------|-------|
| `user_id` | Integer | FK — the user who sent the request |
| `target_user_id` | Integer | FK — the user who received the request |
| `user_rel_status` | Enum | `pending`, `accepted`, `rejected`, or `blocked` |

## UserLocation & LocationPermission

`UserLocation` stores the current GPS position for a user. Each user has at most one location row. `LocationPermission` controls which friends are allowed to see it.

### UserLocation (`user_locations`)

| Column | Type | Notes |
|--------|------|-------|
| `user_id` | Integer | FK — one location record per user (unique) |
| `latitude` / `longitude` | Float | Current GPS position |
| `is_enabled` | Boolean | False if the user has turned off location sharing |

### LocationPermission (`location_permissions`)

| Column | Type | Notes |
|--------|------|-------|
| `user_loc_id` | Integer | FK — the location record being shared |
| `user_id` | Integer | FK — the friend who is permitted to see it |

## PinReaction & PinReport

### PinReaction (`pin_reactions`)

One row per user reaction on a pin. `reaction_value` is enforced by a database check constraint to only allow `1` (like) or `-1` (dislike).

| Column | Type | Notes |
|--------|------|-------|
| `pin_id` | Integer | FK — the pin being reacted to |
| `user_id` | Integer | FK — the user reacting |
| `reaction_value` | Integer | `1` for like, `-1` for dislike |

### PinReport (`pin_reports`)

A report filed against a pin by a user.

| Column | Type | Notes |
|--------|------|-------|
| `pin_id` | Integer | FK — the pin being reported |
| `user_id` | Integer | FK — the user who filed the report |
| `report_type` | Enum | `inaccurate`, `resolved`, `duplicate`, `expired`, `misleading`, `spam`, or `inappropriate` |

## UserReport & UserBan

### UserReport (`user_reports`)

A report filed against a user. Reports are anonymous.

| Column | Type | Notes |
|--------|------|-------|
| `reported_user_id` | Integer | FK — the user being reported |
| `report_type` | Enum | `bot`, `profanity`, `spam`, `inappropriate content`, `harassment`, `scam`, `impersonation`, or `hate speech` |

### UserBan (`user_bans`)

A ban issued by an admin against a user. `ban_expiry` is only relevant for temporary bans.

| Column | Type | Notes |
|--------|------|-------|
| `user_id` | Integer | FK — the user being banned |
| `admin_id` | Integer | FK — the admin who issued the ban |
| `ban_type` | Enum | `permanent` or `temporary` |
| `ban_expiry` | DateTime | When the ban ends — only set for temporary bans |
| `ban_reason` | Text | Required reason provided by the admin |
| `ban_isactive` | Boolean | Can be set to false to deactivate the ban without deleting it |

## Admin

Admin accounts used for moderation. Similar to User but uses password-based login rather than token-based. Admins can issue bans.

**Table:** `admins`

| Column | Type | Notes |
|--------|------|-------|
| `admin_email` | String | Unique — used to identify the account |
| `admin_fname` / `admin_lname` | String | First and last name |
| `admin_password` | String | Stored password for login |
| `admin_token` | String | Set on login, cleared on logout |

## Message

A direct message sent from one user to another. Currently only exists in database, not in the API.

**Table:** `messages`

| Column | Type | Notes |
|--------|------|-------|
| `sender_id` | Integer | FK — the user who sent the message |
| `receiver_id` | Integer | FK — the user who received the message |
| `message_body` | Text | The message content |

## InvitationCode

A 12 character code generated by a user to invite a guest. When redeemed, `guest_user_id` is set to guest's ID and `is_used` changes to true. Codes expire after the `expires_at` time (24 hours).

**Table:** `invitation_codes`

| Column | Type | Notes |
|--------|------|-------|
| `creator_id` | Integer | FK — the user who generated the code |
| `code` | String | 12-character unique invite code |
| `guest_user_id` | Integer | FK — set to the guest's user ID once redeemed |
| `expires_at` | DateTime | When the code becomes invalid |
| `is_used` | Boolean | True once the code has been redeemed |