# Friends endpoints

All endpoints related to relationships (friends) between users.

## GET /friends

### Description

Returns a list of users, whom the logged-in user is friends with. (relationship status = accepted)\
Returns empty array if user has no friends:(

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

## POST /friends

### Description

Sends a new friend request.

### Request

#### Body

| Field            | Type  | Required | Constraints                  | Description                                                          |
|------------------|-------|----------|------------------------------|----------------------------------------------------------------------|
| `target_user_id` | `int` | Yes      | existing id from users table | A valid user id with whom the user wants to have a relationship with | 

### Response

#### Examples

201 - a request has been sent

| Field             | Type     | Description                                                               |
|-------------------|----------|---------------------------------------------------------------------------|
| `user_rel_id`     | `int`    | Identifier of the relationship                                            |
| `user_id`         | `int`    | The user who sent the request                                             |
| `target_user_id`  | `int`    | The user who received the request                                         |
| `user_rel_status` | `string` | Relationship status. Can be: `pending`, `accepted`, `rejected`, `blocked` |

```json
{
  "user_rel_id": 16,
  "user_id": 1,
  "target_user_id": 5,
  "user_rel_status": "pending",
  "created_at": "2026-05-07T17:21:14.179304",
  "updated_at": "2026-05-07T17:21:14.179304"
}
```

204 - relationship already exists (status = accepted)

403 - the other user has blocked this user (or vica-versa)

```json
{
  "detail": "Relationship is blocked"
}
```

404 - the `target_user_id` is invalid

```json
{
  "detail": "User not found"
}
```

#### HTTP Status Codes

| Error Code | Description                             |
|------------|-----------------------------------------|
| 201        | Request sent                            |
| 204        | Relationship already exists as accepted |
| 401        | Unauthenticated                         |
| 403        | Relationship is blocked by either party |
| 404        | Target user does not exist              |
| 422        | Target user id is the same as user id   |

## GET /friends/requests

### Description

A list of incoming requests from the logged-in user point of view (where `target_user_id` is the user) and status is
`pending`\
Returns empty list if no incoming requests

### Response

#### Fields

| Field             | Type     | Description                                                   |
|-------------------|----------|---------------------------------------------------------------|
| `user_rel_id`     | `int`    | Identifier of the relationship                                |
| `user_id`         | `int`    | The user who sent the request                                 |
| `target_user_id`  | `int`    | The user who received the request (this case: logged-in user) |
| `user_rel_status` | `string` | Relationship status. Here only `pending`                      |

#### Example

```json
[
  {
    "user_rel_id": 20,
    "user_id": 5,
    "target_user_id": 1,
    "user_rel_status": "pending",
    "created_at": "2026-05-07T15:29:48.454Z",
    "updated_at": "2026-05-07T15:29:48.454Z"
  }
]
```

#### HTTP Status Codes

| Error Code | Description     |
|------------|-----------------|
| 200        | -               |
| 401        | Unauthenticated | 

## GET /friends/sent

### Description

A list of outgoing requests from the logged-in user point of view (where `user_id` is the user) and status is
`pending`\
Returns empty list if no outgoing requests

### Response

#### Fields

| Field             | Type     | Description                                               |
|-------------------|----------|-----------------------------------------------------------|
| `user_rel_id`     | `int`    | Identifier of the relationship                            |
| `user_id`         | `int`    | The user who sent the request (this case: logged-in user) |
| `target_user_id`  | `int`    | The user who received the request                         |
| `user_rel_status` | `string` | Relationship status. Here only `pending`                  |

#### Example

```json
[
  {
    "user_rel_id": 20,
    "user_id": 1,
    "target_user_id": 5,
    "user_rel_status": "pending",
    "created_at": "2026-05-07T15:29:48.454Z",
    "updated_at": "2026-05-07T15:29:48.454Z"
  }
]
```

#### HTTP Status Codes

| Error Code | Description     |
|------------|-----------------|
| 200        | -               |
| 401        | Unauthenticated | 

## GET /friends/blocked

### Description

A list of relationships where the `status` is `blocked` (the requests that were blocked by the user).\
Returns empty list if none

### Response

#### Fields

| Field             | Type     | Description                                                   |
|-------------------|----------|---------------------------------------------------------------|
| `user_rel_id`     | `int`    | Identifier of the relationship                                |
| `user_id`         | `int`    | The user who sent the request                                 |
| `target_user_id`  | `int`    | The user who received the request (this case: logged-in user) |
| `user_rel_status` | `string` | Relationship status. Here only `blocked`                      |

#### Example

```json
[
  {
    "user_rel_id": 20,
    "user_id": 5,
    "target_user_id": 1,
    "user_rel_status": "blocked",
    "created_at": "2026-05-07T15:29:48.454Z",
    "updated_at": "2026-05-07T15:29:48.454Z"
  }
]
```

#### HTTP Status Codes

| Error Code | Description     |
|------------|-----------------|
| 200        | -               |
| 401        | Unauthenticated | 

## PATCH /friends/{rel_id}

### Description

Change the status of a relationship.

### Request

#### Body

| Field      | Type     | Required | Constraints                          | Description                        |
|------------|----------|----------|--------------------------------------|------------------------------------|
| `response` | `string` | Yes      | `accepted`, `rejected`, or `blocked` | The new status of the relationship |

### Response

#### Fields

| Field             | Type     | Description                                                   |
|-------------------|----------|---------------------------------------------------------------|
| `user_rel_id`     | `int`    | Identifier of the relationship                                |
| `user_id`         | `int`    | The user who sent the request                                 |
| `target_user_id`  | `int`    | The user who received the request (this case: logged-in user) |
| `user_rel_status` | `string` | Relationship status. Here only `blocked`                      |

#### Example

```json
[
  {
    "user_rel_id": 20,
    "user_id": 5,
    "target_user_id": 1,
    "user_rel_status": "accepted",
    "created_at": "2026-05-07T15:29:48.454Z",
    "updated_at": "2026-05-07T15:29:48.454Z"
  }
]
```

#### HTTP Status Codes

| Error Code | Description                                                               |
|------------|---------------------------------------------------------------------------|
| 200        | -                                                                         |
| 403        | Forbidden. The request doesn't belong to the user who tries to modify it. | 
| 422        | Invalid `response` value                                                  | 
| 404        | Invalid `rel_id`                                                          | 

## DELETE /friends/{rel_id}

### Description

Delete a relationship completely.

### Response

#### HTTP Status Codes

| Error Code | Description                                                               |
|------------|---------------------------------------------------------------------------|
| 204        | Deleted                                                                   |
| 403        | Forbidden. The request doesn't belong to the user who tries to modify it. |
| 404        | Invalid `rel_id`                                                          | 