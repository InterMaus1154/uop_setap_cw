# RestAPI Documentation
## Content
- [Overview](#overview)
- [What is a REST API?](#what-is-a-rest-api)
- [Authentication](#authentication)
    - [Overview](#overview-1)
    - [Authentication Logic](#authentication-logic)
- [Endpoints](#endpoints)

## Overview
This document will guide you through the different API endpoints used for **CampusConnect**. Using this API, you can even create your own frontend in your preferred language/framework.\
The API has been built using Python and FastAPI. You can read more about it in our backend documentation (link here later).

## What is a REST API?
A **REST API** is a way for two programs to communicate over the internet using standard HTTP requests — the same technology your browser uses to load websites.

Instead of clicking buttons on a webpage, you send requests to specific URLs (called **endpoints**) and get data back, usually in JSON format.

There are four main types of requests:
- `GET` — fetch data
- `POST` — create something new
- `PUT` / `PATCH` — update something existing
- `DELETE` — remove something

For example, sending a `GET` request to `/pins` would return a list of pins, while sending a `POST` request to `/pins` would create a new one.

## Authentication
### Overview
Some routes are protected by authentication, while some routes are partially protected - they need authentication only for extra logic/functionality.\
As this is just a prototype, we simplified the login functionality to just only using email, and not email+password.\
In the full application, we would use external services, like Microsoft and Google OAuth, allowing students to login via their university accounts.

### Authentication logic
Protected routes require the `Authorization` header to contain a `Bearer` token in the following format: `Authorization: Bearer <your_token>`.\
A token can be obtained from either `POST /auth/login` or `POST /login/code` endpoints.\
For missing or invalid token, a protected route will return `401` HTTP status.

## Endpoints