# Authentication

Details about the authentication endpoints, including request body and response.

## POST /auth/login

### Description

Logs the user in via email, and returns the user details alongside with the Bearer token.

### Request

#### Parameters

| Field   | Type     | Required | Description                         |
|---------|----------|----------|-------------------------------------|
| `email` | `string` | Yes      | The user's registered email address |

#### Example

```json
{
  "email": "example_user@email.com"
}
```

### Response

#### Fields

| Field                  | Type       | Description                                            |
|------------------------|------------|--------------------------------------------------------|
| `token`                | `string`   | Bearer token to use in subsequent requests             |
| `user_id`              | `integer`  | Unique identifier of the user                          |
| `user_fname`           | `string`   | User's first name                                      |
| `user_lname`           | `string`   | User's last name                                       |
| `user_email`           | `string`   | User's email address                                   |
| `user_displayname`     | `string`   | Optional display name                                  |
| `user_use_displayname` | `boolean`  | Whether the display name is shown instead of full name |
| `user_isactive`        | `boolean`  | Whether the account is active                          |
| `last_login`           | `datetime` | Timestamp of last login                                |
| `created_at`           | `datetime` | Timestamp of account creation                          |

#### Example

```json
{
  "token": "24f51988e42a2eb7642d45499759380b",
  "user_id": 1,
  "user_fname": "Example",
  "user_lname": "User",
  "user_email": "example_user@email.com",
  "user_displayname": "J. D.",
  "user_use_displayname": true,
  "user_isactive": true,
  "last_login": "2026-03-05T11:43:21.912Z",
  "created_at": "2026-03-05T11:43:21.912Z"
}
```

#### HTTP Status Codes

| Error Code | Description                              |
|------------|------------------------------------------|
| 200        | Login successful                         |
| 401        | Email is invalid                         |
| 403        | User is inactive                         |
| 422        | Validation error: email field is missing |

## POST /auth/logout

**Auth Required**

### Description

Logs out the user by deleting the Bearer token - it will be invalid on subsequent requests.

### Request

- No body required

### Response

#### Example

```json
{
  "message": "Successfully logged out"
}
```

#### HTTP Status Codes

| Error Code | Description             |
|------------|-------------------------|
| 200        | Logout successful       |
| 401        | Bearer token is invalid |

## POST /auth/login/code

### Description

Login with an invitation code.

### Request

#### Parameters

| Field  | Type     | Required | Description             |
|--------|----------|----------|-------------------------|
| `code` | `string` | Yes      | A valid invitation code |

#### Example

```json
{
  "code": "hjb32jjl2"
}
```

### Response

| Field                  | Type       | Description                                            |
|------------------------|------------|--------------------------------------------------------|
| `token`                | `string`   | Bearer token to use in subsequent requests             |
| `user_id`              | `integer`  | Unique identifier of the user                          |
| `user_fname`           | `string`   | User's first name                                      |
| `user_lname`           | `string`   | User's last name                                       |
| `user_email`           | `string`   | User's email address                                   |
| `user_displayname`     | `string`   | Optional display name                                  |
| `user_use_displayname` | `boolean`  | Whether the display name is shown instead of full name |
| `user_isactive`        | `boolean`  | Whether the account is active                          |
| `last_login`           | `datetime` | Timestamp of last login                                |
| `created_at`           | `datetime` | Timestamp of account creation                          |

#### Example

```json
{
  "token": "24f51988e42a2eb7642d45499759380b",
  "user_id": 1,
  "user_fname": "Guest",
  "user_lname": "User",
  "user_email": "guest_sgdg532@guest.app",
  "user_displayname": "J. D.",
  "user_use_displayname": true,
  "user_isactive": true,
  "last_login": "2026-03-05T11:43:21.912Z",
  "created_at": "2026-03-05T11:43:21.912Z"
}
```

#### HTTP Status Codes

| Error Code | Description             |
|------------|-------------------------|
| 200        | Login successful        |
| 401        | Invalid or expired code |
