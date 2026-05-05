# Pins

Details about pin interaction related endpoints.

## GET /pins

### Description

Returns a list of active pins. The endpoint is public, but if an authenticated user queries it, it will set the
`user_reaction` field to either `1 = liked` or `-1 = disliked`, otherwise it is null.

### Query parameters (optional)

The route takes some optional parameters as filtering options.

| Param           | Description                      | Note                                                |
|-----------------|----------------------------------|-----------------------------------------------------| 
| `cat_id`        | A valid category id              | Works in an `or` condition with `cat_level_id`      |
| `cat_level_id`  | A valid category level id        | Works in an `or` condition with `cat_id`            |
| `pin_expire_at` | A date in format of `YYYY-MM-DD` | Returns pins that expire on that day or before that | 

### Response

Returns an array of pin objects.

#### Fields

Each object contains the following

| Field             | Type            | Description                                                                                             |
|-------------------|-----------------|---------------------------------------------------------------------------------------------------------|
| `pin_id`          | `int`           | Identifier of the pin                                                                                   |
| `cat_id`          | `int`           | Category identifier                                                                                     |
| `sub_cat_id`      | `int`           | Subcategory identifier. May be null                                                                     |
| `user_id`         | `int`           | Pin author identifier                                                                                   | 
| `pin_title`       | `string`        | -                                                                                                       | 
| `pin_description` | `string`        | Extra info about a pin. May be null                                                                     |
| `pin_picture_url` | `string`        | Full url for a pin. May be null. Resolves to the server it is running on                                |
| `pin_latitude`    | `decimal`       | -                                                                                                       |
| `pin_longitude`   | `decimal`       | -                                                                                                       |
| `pin_isactive`    | `boolean`       | Either true or false, in this endpoint always true                                                      | 
| `pin_expire_at`   | `timestamp`     | Example format: 2026-05-15T20:00:00                                                                     | 
| `created_at`      | `timestamp`     | Example format: 2026-03-11T01:00:58.241294                                                              |
| `pin_color`       | `string`        | Hex code of the pin color based on the category level                                                   |
| `pin_author_name` | `string`        | The set name who created the pin, either first name or display name, based on user preferences          | 
| `pin_likes`       | `int`           | Positive integer                                                                                        |
| `pin_dislikes`    | `int`           | Positive integer                                                                                        |
| `user_reaction`   | `int` or `null` | When authenticated, shows 1 for like, -1 for dislike, otherwise null if unauthenticated or didn't react |

#### Example

```json
[
  {
    "pin_id": 2,
    "cat_id": 1,
    "sub_cat_id": 3,
    "user_id": 3,
    "pin_title": "5-a-side Football - Southsea Common",
    "pin_description": "Open football session on the common",
    "pin_picture_url": null,
    "pin_latitude": 50.7891,
    "pin_longitude": -1.0889,
    "pin_isactive": true,
    "pin_expire_at": "2026-05-15T20:00:00",
    "created_at": "2026-03-11T01:00:58.241294",
    "pin_color": "#3B82F6",
    "pin_author_name": "CJ_Da_Great",
    "pin_likes": 0,
    "pin_dislikes": 1,
    "user_reaction": null
  },
  {
    "pin_id": 3,
    "cat_id": 1,
    "sub_cat_id": 2,
    "user_id": 5,
    "pin_title": "Student Night - Pryzm",
    "pin_description": "Student night with discounted entry before 11pm",
    "pin_picture_url": null,
    "pin_latitude": 50.796,
    "pin_longitude": -1.093,
    "pin_isactive": true,
    "pin_expire_at": "2026-04-25T03:00:00",
    "created_at": "2026-03-11T01:00:58.241294",
    "pin_color": "#3B82F6",
    "pin_author_name": "MikeBrown88",
    "pin_likes": 2,
    "pin_dislikes": 0,
    "user_reaction": null
  },
  {
    "pin_id": 31,
    "cat_id": 5,
    "sub_cat_id": 23,
    "user_id": 7,
    "pin_title": "Slippery Path - Old Portsmouth",
    "pin_description": "Cobblestones extremely slippery after rain near the cathedral",
    "pin_picture_url": null,
    "pin_latitude": 50.7989,
    "pin_longitude": -1.1066,
    "pin_isactive": true,
    "pin_expire_at": "2026-04-26T15:00:00",
    "created_at": "2026-03-11T01:00:58.241294",
    "pin_color": "#F59E0B",
    "pin_author_name": "JDavis_",
    "pin_likes": 1,
    "pin_dislikes": 0,
    "user_reaction": null
  }
]
```

#### HTTP Status Codes

| Error Code | Description |
|------------|-------------|
| 200        | -           |

## GET /pin/{pin_id}

### Description

Returns a single pin record. The endpoint is public, but if an authenticated user queries it, it will set the
`user_reaction` field to either `1 = liked` or `-1 = disliked`, otherwise it is null. 404 if id is not valid or pin is
not active.

### Request

#### Route Parameters

| Field    | Type  | Required | Description    |
|----------|-------|----------|----------------|
| `pin_id` | `int` | Yes      | A valid pin id |

### Response

A single pin record.

#### Fields

| Field             | Type            | Description                                                                                             |
|-------------------|-----------------|---------------------------------------------------------------------------------------------------------|
| `pin_id`          | `int`           | Identifier of the pin                                                                                   |
| `cat_id`          | `int`           | Category identifier                                                                                     |
| `sub_cat_id`      | `int`           | Subcategory identifier. May be null                                                                     |
| `user_id`         | `int`           | Pin author identifier                                                                                   | 
| `pin_title`       | `string`        | -                                                                                                       | 
| `pin_description` | `string`        | Extra info about a pin. May be null                                                                     |
| `pin_picture_url` | `string`        | Full url for a pin. May be null. Resolves to the server it is running on                                |
| `pin_latitude`    | `decimal`       | -                                                                                                       |
| `pin_longitude`   | `decimal`       | -                                                                                                       |
| `pin_isactive`    | `boolean`       | Either true or false, in this endpoint always true                                                      | 
| `pin_expire_at`   | `timestamp`     | Example format: 2026-05-15T20:00:00                                                                     | 
| `created_at`      | `timestamp`     | Example format: 2026-03-11T01:00:58.241294                                                              |
| `pin_color`       | `string`        | Hex code of the pin color based on the category level                                                   |
| `pin_author_name` | `string`        | The set name who created the pin, either first name or display name, based on user preferences          | 
| `pin_likes`       | `int`           | Positive integer                                                                                        |
| `pin_dislikes`    | `int`           | Positive integer                                                                                        |
| `user_reaction`   | `int` or `null` | When authenticated, shows 1 for like, -1 for dislike, otherwise null if unauthenticated or didn't react |

#### Example

```json
{
  "pin_id": 2,
  "cat_id": 1,
  "sub_cat_id": 3,
  "user_id": 3,
  "pin_title": "5-a-side Football - Southsea Common",
  "pin_description": "Open football session on the common",
  "pin_picture_url": null,
  "pin_latitude": 50.7891,
  "pin_longitude": -1.0889,
  "pin_isactive": true,
  "pin_expire_at": "2026-05-15T20:00:00",
  "created_at": "2026-03-11T01:00:58.241294",
  "pin_color": "#3B82F6",
  "pin_author_name": "CJ_Da_Great",
  "pin_likes": 0,
  "pin_dislikes": 1,
  "user_reaction": null
}
```

#### HTTP Status Codes

| Error Code | Description                      |
|------------|----------------------------------|
| 200        | Pin found.                       |
| 404        | Id is invalid or pin is inactive |

## POST /pins

### Description

Creates a new pin record, and returns the newly created pin. Only authenticated users can perform this action.

### Request

### Body

| Field             | Type       | Required | Constraints                                       | Description            |
|-------------------|------------|----------|---------------------------------------------------|------------------------|
| `pin_title`       | `string`   | Yes      | Max length 100                                    |                        |
| `pin_latitude`    | `float`    | Yes      |                                                   |                        |
| `pin_longitude`   | `float`    | Yes      |                                                   |                        |
| `cat_id`          | `int`      | Yes      | Must exist in categories                          | A main category id     |
| `sub_cat_id`      | `int`      | No       | Must exist in sub_categories and belong to cat_id | A sub main category id |
| `pin_expire_at`   | `datetime` | Yes      |                                                   |                        | 
| `pin_description` | `string`   | No       |                                                   |                        |
| `image`           | `file`     | No       | Type image, less than 5MB                         |                        |

### Response

#### Fields

| Field             | Type            | Description                                                                                             |
|-------------------|-----------------|---------------------------------------------------------------------------------------------------------|
| `pin_id`          | `int`           | Identifier of the pin                                                                                   |
| `cat_id`          | `int`           | Category identifier                                                                                     |
| `sub_cat_id`      | `int`           | Subcategory identifier. May be null                                                                     |
| `user_id`         | `int`           | Pin author identifier                                                                                   | 
| `pin_title`       | `string`        | -                                                                                                       | 
| `pin_description` | `string`        | Extra info about a pin. May be null                                                                     |
| `pin_picture_url` | `string`        | Full url for a pin. May be null. Resolves to the server it is running on                                |
| `pin_latitude`    | `decimal`       | -                                                                                                       |
| `pin_longitude`   | `decimal`       | -                                                                                                       |
| `pin_isactive`    | `boolean`       | Either true or false, in this endpoint always true                                                      | 
| `pin_expire_at`   | `timestamp`     | Example format: 2026-05-15T20:00:00                                                                     | 
| `created_at`      | `timestamp`     | Example format: 2026-03-11T01:00:58.241294                                                              |
| `pin_color`       | `string`        | Hex code of the pin color based on the category level                                                   |
| `pin_author_name` | `string`        | The set name who created the pin, either first name or display name, based on user preferences          | 
| `pin_likes`       | `int`           | Positive integer                                                                                        |
| `pin_dislikes`    | `int`           | Positive integer                                                                                        |
| `user_reaction`   | `int` or `null` | When authenticated, shows 1 for like, -1 for dislike, otherwise null if unauthenticated or didn't react |

#### Example

```json
{
  "pin_id": 2,
  "cat_id": 1,
  "sub_cat_id": 3,
  "user_id": 3,
  "pin_title": "5-a-side Football - Southsea Common",
  "pin_description": "Open football session on the common",
  "pin_picture_url": null,
  "pin_latitude": 50.7891,
  "pin_longitude": -1.0889,
  "pin_isactive": true,
  "pin_expire_at": "2026-05-15T20:00:00",
  "created_at": "2026-03-11T01:00:58.241294",
  "pin_color": "#3B82F6",
  "pin_author_name": "CJ_Da_Great",
  "pin_likes": 0,
  "pin_dislikes": 1,
  "user_reaction": null
}
```

#### HTTP Status Codes

| Error Code | Description            |
|------------|------------------------|
| 201        | Pin created            |
| 422        | Validation error (any) |
| 401        | Unauthenticated        |

## PUT /pins/{id}

### Description

Update some details of a pin. Only the owner of the pin (user who created it) can update it.

### Request

### Body

| Field             | Type       | Required  | Constraints    | Description |
|-------------------|------------|-----------|----------------|-------------|
| `pin_title`       | `string`   | Sometimes | Max length 100 |             |
| `pin_expire_at`   | `datetime` | Sometimes |                |             | 
| `pin_description` | `string`   | Sometimes |                |             |

### Response

#### Fields

| Field             | Type            | Description                                                                                             |
|-------------------|-----------------|---------------------------------------------------------------------------------------------------------|
| `pin_id`          | `int`           | Identifier of the pin                                                                                   |
| `cat_id`          | `int`           | Category identifier                                                                                     |
| `sub_cat_id`      | `int`           | Subcategory identifier. May be null                                                                     |
| `user_id`         | `int`           | Pin author identifier                                                                                   | 
| `pin_title`       | `string`        | -                                                                                                       | 
| `pin_description` | `string`        | Extra info about a pin. May be null                                                                     |
| `pin_picture_url` | `string`        | Full url for a pin. May be null. Resolves to the server it is running on                                |
| `pin_latitude`    | `decimal`       | -                                                                                                       |
| `pin_longitude`   | `decimal`       | -                                                                                                       |
| `pin_isactive`    | `boolean`       | Either true or false, in this endpoint always true                                                      | 
| `pin_expire_at`   | `timestamp`     | Example format: 2026-05-15T20:00:00                                                                     | 
| `created_at`      | `timestamp`     | Example format: 2026-03-11T01:00:58.241294                                                              |
| `pin_color`       | `string`        | Hex code of the pin color based on the category level                                                   |
| `pin_author_name` | `string`        | The set name who created the pin, either first name or display name, based on user preferences          | 
| `pin_likes`       | `int`           | Positive integer                                                                                        |
| `pin_dislikes`    | `int`           | Positive integer                                                                                        |
| `user_reaction`   | `int` or `null` | When authenticated, shows 1 for like, -1 for dislike, otherwise null if unauthenticated or didn't react |

#### Example

```json
{
  "pin_id": 2,
  "cat_id": 1,
  "sub_cat_id": 3,
  "user_id": 3,
  "pin_title": "5-a-side Football - Southsea Common",
  "pin_description": "Open football session on the common",
  "pin_picture_url": null,
  "pin_latitude": 50.7891,
  "pin_longitude": -1.0889,
  "pin_isactive": true,
  "pin_expire_at": "2026-05-15T20:00:00",
  "created_at": "2026-03-11T01:00:58.241294",
  "pin_color": "#3B82F6",
  "pin_author_name": "CJ_Da_Great",
  "pin_likes": 0,
  "pin_dislikes": 1,
  "user_reaction": null
}
```

#### HTTP Status Codes

| Error Code | Description              |
|------------|--------------------------|
| 200        | Pin updated              |
| 422        | Validation error (any)   |
| 401        | Unauthenticated          |
| 403        | User doesn't own the pin |
| 404        | Pin not found            |

## DELETE /pins/{id}

### Description

Delete a pin. Only the owner of the pin (user who created it) can delete it. As many records are dependent on the pin,
we only deactivate it (soft-delete).

### Response

200:

```json
{
  "message": "Pin deleted"
}

```

#### HTTP Status Codes

| Error Code | Description              |
|------------|--------------------------|
| 200        | Pin deleted              |
| 401        | Unauthenticated          |
| 403        | User doesn't own the pin |
| 404        | Pin not found            |

## PATCH /pins/{id}/react

### Description

React to a pin (either like or dislike)

`1` = like\
`-1` = dislike

### Request

#### Body

| Field   | Type  | Required | Constraints | Description |
|---------|-------|----------|-------------|-------------|
| `value` | `int` | Yes      | -1 or 1     |             |

### Response

#### Examples

200 - if a reaction already exists, we update it:

```json
{
  "message": "Reaction updated"
}
```

200 - if the user has already reacted, and same reaction is received:

```json
{
  "message": "Reaction already set"
}
```

201 - if the user hasn't reacted to this pin yet:

```json
{
  "message": "Reaction successfully created"
}
```

#### HTTP Status Codes

| Error Code | Description      |
|------------|------------------|
| 200        | Reaction updated |
| 201        | Reaction created |
| 401        | Unauthenticated  |
| 404        | Pin not found    |

## DELETE /pins/{id}/react

### Description

Delete a pin reaction.

### Response

#### HTTP Status Codes

| Error Code | Description                             |
|------------|-----------------------------------------|
| 200        | Reaction deleted                        |
| 401        | Unauthenticated                         |
| 404        | Pin not found                           |
| 404        | Reaction not found for user for the pin |

## GET /pins/report-types

### Description

Returns a list of possible report types.

### Response

#### HTTP Status Codes

| Error Code | Description |
|------------|-------------|
| 200        | -           |

## GET /pins/{id}/reports

### Description

Returns a list of reports for a pin.

### Response

#### Fields

| Field           | Type       | Description                  |
|-----------------|------------|------------------------------|
| `pin_report_id` | `int`      |                              |
| `pin_id`        | `int`      | Identifier of the pin        |
| `user_id`       | `int`      | User who made the report     |
| `report_type`   | `string`   | A value from report types    |
| `created_at`    | `datetime` | The date the report was made |

#### HTTP Status Codes

| Error Code | Description    |
|------------|----------------|
| 200        | -              |
| 404        | Pin not found. |

## POST /pins/{id}/report

### Description

Create a new report for a pin.

### Request

#### Body

| Field         | Type     | Required | Constraints             | Description |
|---------------|----------|----------|-------------------------|-------------|
| `report_type` | `string` | Yes      | Valid from report types |             |

### Response

#### Example

200:

```json
{
  "message": "Pin reported successfully"
}
```

400:

```json
{
  "message": "You already reported this pin"
}
```

#### HTTP Status Codes

| Error Code | Description                    |
|------------|--------------------------------|
| 201        | Pin report created             |
| 404        | Pin not found.                 |
| 400        | User already reported the pin. |
