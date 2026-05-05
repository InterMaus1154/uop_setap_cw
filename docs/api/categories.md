# Categories

## GET /categories

### Description

Returns a list of main categories used for pins.

### Response

#### Fields

| Field          | Type     | Description                                              |
|----------------|----------|----------------------------------------------------------|
| `cat_id`       | `int`    | Identifier of the category                               |
| `cat_level_id` | `int`    | Identifier of the category level the category belongs to |
| `cat_name`     | `string` | Name of the category                                     |

#### Example

```json
[
  {
    "cat_id": 1,
    "cat_level_id": 1,
    "cat_name": "Assault"
  }
]

```

#### HTTP Status Codes

| Error Code | Description |
|------------|-------------|
| 200        | -           |

## GET /categories/{id}/sub-categories

### Description

Returns a list of sub categories which belongs to the given category.

### Response

#### Example

```json
[
  {
    "sub_cat_id": 1,
    "cat_id": 1,
    "sub_cat_name": "Campus Event"
  },
  {
    "sub_cat_id": 2,
    "cat_id": 1,
    "sub_cat_name": "Public Social Event"
  }
]
```

#### Fields

| Field          | Type     | Description                                             |
|----------------|----------|---------------------------------------------------------|
| `sub_cat_id`   | `int`    | Identifier of the sub category                          |
| `cat_id`       | `int`    | Identifier of the category  the sub-category belongs to |
| `sub_cat_name` | `string` | Name of the sub-category                                |

#### HTTP Status Codes

| Error Code | Description         |
|------------|---------------------|
| 200        | -                   |
| 404        | Invalid category id |

## GET /categories/sub-categories

### Description

Returns a list of all available sub categories.

### Response

#### Example

```json
[
  {
    "sub_cat_id": 1,
    "cat_id": 1,
    "sub_cat_name": "Campus Event"
  },
  {
    "sub_cat_id": 2,
    "cat_id": 1,
    "sub_cat_name": "Public Social Event"
  }
]
```

#### Fields

| Field          | Type     | Description                                             |
|----------------|----------|---------------------------------------------------------|
| `sub_cat_id`   | `int`    | Identifier of the sub category                          |
| `cat_id`       | `int`    | Identifier of the category  the sub-category belongs to |
| `sub_cat_name` | `string` | Name of the sub-category                                |

#### HTTP Status Codes

| Error Code | Description |
|------------|-------------|
| 200        | -           |

## GET /categories/levels

### Description

Category levels. The top "domain" of the categories. Each category belongs to a category level, and based on the level a
pin gets an assigned colour.

### Response

#### Example

```json
[
  {
    "cat_level_id": 1,
    "cat_level_name": "Information",
    "cat_level_ttl_mins": 1440,
    "cat_level_color": "#3B82F6"
  },
  {
    "cat_level_id": 2,
    "cat_level_name": "Warning",
    "cat_level_ttl_mins": 1440,
    "cat_level_color": "#F59E0B"
  },
  {
    "cat_level_id": 3,
    "cat_level_name": "Danger",
    "cat_level_ttl_mins": 180,
    "cat_level_color": "#EF4444"
  }
]
```

#### Fields

| Field                | Type     | Description                                                           |
|----------------------|----------|-----------------------------------------------------------------------|
| `cat_level_id`       | `int`    | Identifier of the level                                               |
| `cat_id`             | `int`    | Name of the level                                                     |
| `cat_level_ttl_mins` | `int`    | Default time to live for a given level, used for pin expiry. Minutes. |
| `cat_level_color`    | `string` | Colour used for pins when rendering.                                  |

#### HTTP Status Codes

| Error Code | Description |
|------------|-------------|
| 200        | -           |


