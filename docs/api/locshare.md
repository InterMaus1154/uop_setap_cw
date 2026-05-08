# Location Sharing

All endpoints related to location sharing.

## GET /user-locations

### Description

Location record of the user. Returns even when it is not enabled.

### Response

#### Fields

| Field         | Type      | Description                                |
|---------------|-----------|--------------------------------------------|
| `user_loc_id` | `int`     | Identifier of the user location            |
| `user_id`     | `int`     | Identifier of the user it belongs to       |
| `latitude`    | `decimal` |                                            |
| `longitude`   | `decimal` |                                            |
| `is_enabled`  | `boolean` |                                            |
| `updated_at`  | `dateime` | Last refresh on location                   |
| `city`        | `string`  | Name of city. Null if couldn't be found    |
| `street`      | `string`  | Name of street. Null if couldn't be found. |

#### Example

```json
{
  "user_loc_id": 7,
  "user_id": 1,
  "latitude": 50.796642,
  "longitude": -1.073556,
  "is_enabled": true,
  "created_at": "2026-05-05T15:53:49.474887",
  "updated_at": "2026-05-07T17:59:25.959729",
  "city": "Portsmouth",
  "street": "Selbourne Terrace"
}
```

#### HTTP Status Codes

| Error Code | Description              |
|------------|--------------------------|
| 200        | -                        |
| 404        | User location not exists |
| 401        | Unauthenticated          |

## POST /user-locations

### Description

Creates a user location record (enabled by default), or updates one if exists.\
**Note:** should only be used for first time, for consecutive updates use the `PATCH` method.

### Request

#### Body

| Field       | Type      | Required | Constraints | Description |
|-------------|-----------|----------|-------------|-------------|
| `latitude`  | `decimal` | Yes      |             |             |
| `longitude` | `decimal` | Yes      |             |             |

### Response

#### Fields

| Field         | Type      | Description                                |
|---------------|-----------|--------------------------------------------|
| `user_loc_id` | `int`     | Identifier of the user location            |
| `user_id`     | `int`     | Identifier of the user it belongs to       |
| `latitude`    | `decimal` |                                            |
| `longitude`   | `decimal` |                                            |
| `is_enabled`  | `boolean` |                                            |
| `updated_at`  | `dateime` | Last refresh on location                   |
| `city`        | `string`  | Name of city. Null if couldn't be found    |
| `street`      | `string`  | Name of street. Null if couldn't be found. |

#### Example

```json
{
  "user_loc_id": 7,
  "user_id": 1,
  "latitude": 50.796642,
  "longitude": -1.073556,
  "is_enabled": true,
  "created_at": "2026-05-05T15:53:49.474887",
  "updated_at": "2026-05-07T17:59:25.959729",
  "city": "Portsmouth",
  "street": "Selbourne Terrace"
}
```

#### HTTP Status Codes

| Error Code | Description     |
|------------|-----------------|
| 201        | Record created  |
| 401        | Unauthenticated |

## PATCH /user-locations

### Description

Updates a user location.

### Request

#### Body

| Field        | Type      | Required | Constraints | Description |
|--------------|-----------|----------|-------------|-------------|
| `latitude`   | `decimal` | Yes      |             |             |
| `longitude`  | `decimal` | Yes      |             |             |
| `is_enabled` | `boolean` | Yes      |             |             |

### Response

#### Fields

| Field         | Type      | Description                                |
|---------------|-----------|--------------------------------------------|
| `user_loc_id` | `int`     | Identifier of the user location            |
| `user_id`     | `int`     | Identifier of the user it belongs to       |
| `latitude`    | `decimal` |                                            |
| `longitude`   | `decimal` |                                            |
| `is_enabled`  | `boolean` |                                            |
| `updated_at`  | `dateime` | Last refresh on location                   |
| `city`        | `string`  | Name of city. Null if couldn't be found    |
| `street`      | `string`  | Name of street. Null if couldn't be found. |

#### Example

```json
{
  "user_loc_id": 7,
  "user_id": 1,
  "latitude": 50.796642,
  "longitude": -1.073556,
  "is_enabled": true,
  "created_at": "2026-05-05T15:53:49.474887",
  "updated_at": "2026-05-07T17:59:25.959729",
  "city": "Portsmouth",
  "street": "Selbourne Terrace"
}
```

#### HTTP Status Codes

| Error Code | Description              |
|------------|--------------------------|
| 200        | Record updated           |
| 404        | User location not exists |
| 401        | Unauthenticated          |

## DELETE /user-locations

### Description

Fully delete location sharing.

### Response

#### HTTP Status Codes

| Error Code | Description              |
|------------|--------------------------|
| 204        | Deleted                  |
| 404        | User location not exists |
| 401        | Unauthenticated          |

## GET /user-locations/friends

### Description

Return a list of user location records, where each record is from a friend who is sharing their location with the user.

### Response

#### Example

```json
[
  {
    "user_loc_id": 0,
    "user_id": 0,
    "latitude": 0,
    "longitude": 0,
    "is_enabled": true,
    "created_at": "2026-05-07T16:10:58.792Z",
    "updated_at": "2026-05-07T16:10:58.792Z",
    "city": "string",
    "street": "string"
  }
]
```

#### HTTP Status Codes

| Error Code | Description     |
|------------|-----------------|
| 200        | -               |
| 401        | Unauthenticated |

## GET /location-permissions

### Description

Return a list of friends (location permission records) the user is sharing location with.

### Response

| Field         | Type  | Description                           |
|---------------|-------|---------------------------------------|
| `loc_perm_id` | `int` | Identifier of the location permission |
| `user_loc_id` | `int` | Identifier of user location           |
| `user_id`     | `int` | Identifier of the friend of the user  |

```json
[
  {
    "loc_perm_id": 4,
    "user_loc_id": 7,
    "user_id": 4,
    "created_at": "2026-05-07T18:16:17.871964",
    "updated_at": "2026-05-07T18:16:17.871964"
  }
]
```

#### HTTP Status Codes

| Error Code | Description     |
|------------|-----------------|
| 200        | -               |
| 401        | Unauthenticated |

## POST /location-permissions

### Description

Start sharing the location with a friend.

### Request

#### Body

| Field     | Type  | Required | Constraints                | Description                    |
|-----------|-------|----------|----------------------------|--------------------------------|
| `user_id` | `int` | Yes      | Valid user id from `users` | Target user whom to share with |

### Response

```json
{
  "loc_perm_id": 4,
  "user_loc_id": 7,
  "user_id": 4,
  "created_at": "2026-05-07T18:16:17.871964",
  "updated_at": "2026-05-07T18:16:17.871964"
}
```

#### HTTP Status Codes

| Error Code | Description                             |
|------------|-----------------------------------------|
| 201        | Created                                 |
| 403        | `user_id` is not the friend of the user |
| 404        | `user_id` is not valid                  |
| 404        | Location record does not exist          |
| 401        | Unauthenticated                         |

## DELETE /location-permissions/{user_id}

### Description

Remove a location sharing permission for a friend.

### Response

#### HTTP Status Codes

| Error Code | Description                        |
|------------|------------------------------------|
| 204        | Deleted                            |
| 404        | Location permission does not exist |
| 404        | Location record does not exist     |
| 401        | Unauthenticated                    |

