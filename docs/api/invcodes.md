# Invitation Codes Endpoints

All endpoints related to the invitation code mechanism.

## GET /invitation-codes

### Description

Returns all active (unused) invitation codes, that have been created by the logged-in user.

### Response

#### Fields

| Field           | Type            | Description                                                 |
|-----------------|-----------------|-------------------------------------------------------------|
| `id`            | `int`           | Identifier of the code                                      |
| `creator_id`    | `int`           | The user who created the code                               |
| `code`          | `string`        | The actual code                                             |
| `guest_user_id` | `int` or `null` | Null until the user logs in, then it will be the guest user |
| `is_used`       | `boolean`       |                                                             |

```json
[
  {
    "id": 13,
    "creator_id": 1,
    "code": "3xcKXXjmeG7a",
    "guest_user_id": 16,
    "created_at": "2026-05-07T16:54:50.568007",
    "expires_at": "2026-05-08T16:54:50.568007",
    "is_used": true
  },
  {
    "id": 14,
    "creator_id": 1,
    "code": "ZTTX6iQIl0cy",
    "guest_user_id": null,
    "created_at": "2026-05-07T16:56:14.693755",
    "expires_at": "2026-05-08T16:56:14.693755",
    "is_used": false
  }
]
```

#### HTTP Status Codes

| Error Code | Description     |
|------------|-----------------|
| 200        | -               |
| 401        | Unauthenticated |

## POST /invitation-codes

### Description

Create a new invitation code if the user hasn't run out of limit yet. Each user can make 5 code per week.

### Response

#### Fields

| Field           | Type            | Description                                                 |
|-----------------|-----------------|-------------------------------------------------------------|
| `id`            | `int`           | Identifier of the code                                      |
| `creator_id`    | `int`           | The user who created the code                               |
| `code`          | `string`        | The actual code                                             |
| `guest_user_id` | `int` or `null` | Null until the user logs in, then it will be the guest user |
| `is_used`       | `boolean`       |                                                             |

```json
{
  "id": 15,
  "creator_id": 1,
  "code": "EbyPDHqdkxBM",
  "guest_user_id": null,
  "created_at": "2026-05-07T17:00:33.181550",
  "expires_at": "2026-05-08T17:00:33.181550",
  "is_used": false
}
```

#### HTTP Status Codes

| Error Code | Description     |
|------------|-----------------|
| 201        | Code created    |
| 429        | Limit reached   |
| 401        | Unauthenticated |