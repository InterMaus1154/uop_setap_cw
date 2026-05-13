# Users

All user (profile) related endpoints.

## GET /users/me

### Description

Returns the current user's profile.

### Response

#### Fields

| Field                  | Type       | Description                                           |
|------------------------|------------|-------------------------------------------------------|
| `user_id`              | `int`      | -                                                     |
| `user_email`           | `string`   | -                                                     |
| `user_fname`           | `string`   | -                                                     |
| `user_lname`           | `string`   | -                                                     |
| `user_displayname`     | `string`   | Optional display name for each user.                  |
| `user_use_displayname` | `boolean`  | Controls whether full name or displayname is returned |
| `user_isactive`        | `boolean`  | -                                                     |
| `last_login`           | `datetime` | -                                                     |
| `created_at`           | `datetime` | -                                                     |

#### Example

```json
{
  "user_email": "johndoe@port.ac.uk",
  "user_fname": "John",
  "user_lname": "Doe",
  "user_displayname": "JDoe92",
  "user_use_displayname": true,
  "user_id": 1,
  "user_isactive": true,
  "last_login": "2026-05-05T14:59:50.801530",
  "created_at": "2026-03-11T01:00:57.051456"
}
```

#### HTTP Status Codes

| Error Code | Description     |
|------------|-----------------|
| 200        | -               |
| 401        | Unauthenticated |

## GET /users/me/pin-count

### Description

Returns the number of pins the user has created.

### Response

#### Fields

| Field       | Type  | Description |
|-------------|-------|-------------|
| `pin_count` | `int` | -           |

#### Example

```json
{
  "pin_count": 3
}
```

#### HTTP Status Codes

| Error Code | Description     |
|------------|-----------------|
| 200        | -               |
| 401        | Unauthenticated |

## PUT /users/me

### Description

Update some details of the user who is logged-in.

### Request

#### Body

| Field                   | Type      | Constraints   | Description |
|-------------------------|-----------|---------------|-------------|
| `user_display_name`     | `string`  | Max length 30 |             |
| `user_use_display_name` | `boolean` | true or false |             |
| `user_fname`            | `string`  | Max length 60 |             |
| `user_lname`            | `string`  | Max length 60 |             |

### Response

The updated user with the same fields as `GET /users/me`.

#### HTTP Status Codes

| Error Code | Description      |
|------------|------------------|
| 200        | -                |
| 401        | Unauthenticated  |
| 422        | Validation error |

## PATCH /users/deactivate

### Description

Deactivate the user who is logged-in. Also logs the user out. The user will not be able to recover their account
themselves. They will be unable to login.

### Response

#### Example:

```json
{
  "message": "Account deactivated"
}
```

| Error Code | Description     |
|------------|-----------------|
| 200        | -               |
| 401        | Unauthenticated |

## GET /users/search/{email}

### Description

Search for a user based on email address. Case-insensitive. Uses database "like" method to search (partial match).
Returns a list of users.

### Response

#### Fields

Returns a list of records. Each record contains the same field as `GET /users/me`.

#### Example:

When the input is "john"
```json
[
  {
    "user_email": "carljohnson@port.ac.uk",
    "user_fname": "Carl",
    "user_lname": "Johnson",
    "user_displayname": "CJ_Da_Great",
    "user_use_displayname": true,
    "user_id": 3,
    "user_isactive": true,
    "last_login": "2026-04-27T23:01:01.103193",
    "created_at": "2026-03-11T01:00:57.051456"
  },
  {
    "user_email": "johndoe@port.ac.uk",
    "user_fname": "mmklm",
    "user_lname": "dsgsdgsdg",
    "user_displayname": "string",
    "user_use_displayname": true,
    "user_id": 1,
    "user_isactive": true,
    "last_login": "2026-05-05T14:59:50.801530",
    "created_at": "2026-03-11T01:00:57.051456"
  }
]
```

| Error Code | Description     |
|------------|-----------------|
| 200        | -               |
