# RestAPI Documentation

```{toctree}
:maxdepth 1
:caption Endpoints specification

auth
categories
pins
users
friends
locshare
```

## Page Content

- [Overview](#overview)
- [What is a REST API?](#what-is-a-rest-api)
- [Authentication](#authentication)
    - [Overview](#overview-1)
    - [Authentication Logic](#authentication-logic)
- [Endpoints](#endpoints-overview)

## Overview

This document will guide you through the different API endpoints used for **CampusConnect**. Using this API, you can
even create your own frontend in your preferred language/framework.\
The API has been built using Python and FastAPI. You can read more about it in our backend documentation (link here
later).

## What is a REST API?

A **REST API** is a way for two programs to communicate over the internet using standard HTTP requests — the same
technology your browser uses to load websites.

Instead of clicking buttons on a webpage, you send requests to specific URLs (called **endpoints**) and get data back,
usually in JSON format.

There are four main types of requests:

- `GET` — fetch data
- `POST` — create something new
- `PUT` / `PATCH` — update something existing
- `DELETE` — remove something

For example, sending a `GET` request to `/pins` would return a list of pins, while sending a `POST` request to `/pins`
would create a new one.

## Authentication

### Overview

Some routes are protected by authentication, while some routes are partially protected - they need authentication only
for extra logic/functionality.\
As this is just a prototype, we simplified the login functionality to just only using email, and not email+password.\
In the full application, we would use external services, like Microsoft and Google OAuth, allowing students to login via
their university accounts.

### Authentication logic

Protected routes require the `Authorization` header to contain a `Bearer` token in the following format:
`Authorization: Bearer <your_token>`.\
A token can be obtained from either `POST /auth/login` or `POST /login/code` endpoints.\
For missing or invalid token, a protected route will return `401` HTTP status.

## Endpoints Overview

Our endpoints are categorised logically, and have the prefix for the entity they represent.\
All of our endpoints returns and expects JSON.\
This section just provides a basic description of the endpoints. To see the required request and response, click on each
individual endpoint and will take you to the corresponding page.

### Auth endpoints

| Method | Endpoint                                       | Description                | Auth Required |
|--------|------------------------------------------------|----------------------------|---------------|
| POST   | [/auth/login](auth.md#post-authlogin)          | Login with email           | No            |
| POST   | [/auth/logout](auth.md#post-authlogout)        | Logout                     | Yes           |
| POST   | [/auth/login/code](auth.md#post-authlogincode) | Login with invitation code | No            | 

### Category endpoints

| Method | Endpoint                                                                        | Description                              | Auth Required |
|--------|---------------------------------------------------------------------------------|------------------------------------------|---------------|
| GET    | [/categories](categories.md#get-categories)                                     | List of main categories                  | No            |
| GET    | [/categories/{id}/sub-categories](categories.md#get-categoriesidsub-categories) | List of sub categories within a category | No            |
| GET    | [/categories/sub-categories](categories.md#get-categoriesidsub-categories)      | List of all sub categories               | No            |
| GET    | [/categories/levels](categories.md#get-categorieslevels)                        | List of category levels                  | No            |

### Pin Endpoints

| Method | Endpoint                                            | Description                  | Auth Required |
|--------|-----------------------------------------------------|------------------------------|---------------|
| GET    | [/pins](pins.md#get-pins)                           | Return a list of active pins | Partially     |
| GET    | [/pins/{pin_id}](pins.md#get-pinpin_id)             | Return a single pin object   | Partially     |
| POST   | [/pins](pins.md#post-pins)                          | Create a new pin             | Yes           |
| PUT    | [/pins/{pin_id}](pins.md#put-pinsid)                | Update a pin                 | Yes           |
| DELETE | [/pins/{pin_id}](pins.md#delete-pinsid)             | Delete a pin                 | Yes           |
| PATCH  | [/pins/{pin_id}/react](pins.md#patch-pinsidreact)   | React to a pin               | Yes           |
| DELETE | [/pins/{pin_id}/react](pins.md#delete-pinsidreact)  | Delete a pin reaction        | Yes           |
| GET    | [/pins/report-types](pins.md#get-pinsreport-types)  | Return report types          | No            |
| GET    | [/pins/{pin_id}/reports](pins.md#get-pinsidreports) | Return pin reports           | No            |
| POST   | [/pins/{pin_id}/report](pins.md#post-pinsidreport)  | Create a new pin report      | Yes           |

### User endpoints

| Method | Endpoint                                               | Description                            | Auth Required |
|--------|--------------------------------------------------------|----------------------------------------|---------------|
| GET    | [/users/me](users.md#get-usersme)                      | Return logged-in user's details        | Yes           |
| GET    | [/users/me/pin-count](users.md#get-usersmepin-count)   | Return logged-in user's number of pins | Yes           |
| PUT    | [/users/me](users.md#put-usersme)                      | Update details of logged-in user       | Yes           |                                      
| PATCH  | [/users/deactivate](users.md#patch-usersdeactivate)    | Deactivate the current logged-in user  | Yes           |                                      
| GET    | [/users/search/{email}](users.md#get-userssearchemail) | Deactivate the current logged-in user  | No            |                                      

### Friend endpoints

| Method | Endpoint                                             | Description                       | Auth Required |
|--------|------------------------------------------------------|-----------------------------------|---------------|
| GET    | [/friends/](friends.md#get-friends)                  | List of logged-in user's friend   | Yes           |
| POST   | [/friends/](friends.md#post-friends)                 | Send a new friend request         | Yes           |
| GET    | [/friends/requests](friends.md#get-friendsrequests)  | List of incoming requests         | Yes           |
| GET    | [/friends/sent](friends.md#get-friendssent)          | List of sent (outgoing) requests  | Yes           |
| GET    | [/friends/blocked](friends.md#get-friendsblocked)    | List of blocked users             | Yes           |
| PATCH  | [/friends/{rel_id}](friends.md#patch-friendsrel_id)  | Update relationship status        | Yes           |
| DELETE | [/friends/{rel_id}](friends.md#delete-friendsrel_id) | Delete relationship between users | Yes           |

## Location sharing endpoints

| Method | Endpoint                                                                          | Description                                                      | Auth Required |
|--------|-----------------------------------------------------------------------------------|------------------------------------------------------------------|---------------|
| GET    | [/user-locations/](locshare.md#get-user-locations)                                | Location record of logged-in user                                | Yes           |
| POST   | [/user-locations/](locshare.md#post-user-locations)                               | Create or update location record for user                        | Yes           |
| PATCH  | [/user-locations/](locshare.md#patch-user-locations)                              | Update location record for user                                  | Yes           |
| PATCH  | [/user-locations/friends](locshare.md#get-user-locationsfriends)                  | Location record of friends who are sharing with the user         | Yes           |
| PATCH  | [/location-permissions](locshare.md#get-location-permissions)                     | Location record of list of friends who are sharing with the user | Yes           |
| POST   | [/location-permissions](locshare.md#post-location-permissions)                    | Share location with a friend                                     | Yes           |
| DELETE | [/location-permissions/{user_id}](locshare.md#delete-location-permissionsuser_id) | Delete location sharing with a friend                            | Yes           |
