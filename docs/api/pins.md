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

Returns a single pin object. The endpoint is public, but if an authenticated user queries it, it will set the
`user_reaction` field to either `1 = liked` or `-1 = disliked`, otherwise it is null. 404 if id is not valid or pin is
not active.

### Request

#### Route Parameters

| Field    | Type  | Required | Description    |
|----------|-------|----------|----------------|
| `pin_id` | `int` | Yes      | A valid pin id |

### Response

A single object.

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