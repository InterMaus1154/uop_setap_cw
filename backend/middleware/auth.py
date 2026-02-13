from fastapi import Request, HTTPException
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from sqlalchemy.orm import Session
from starlette.responses import Response

from database.db import SessionLocal
from models.user import User


class AuthMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next: RequestResponseEndpoint) -> Response:

        # get token from header
        authorization = request.headers.get("Authorization")

        if not authorization:
            return JSONResponse(status_code=401, content={"message": "Authorization header required"})

        token = authorization.replace("Bearer ", "").strip()

        db: Session = SessionLocal()
        try:
            user = db.query(User).filter(User.user_token == token).first()
            if not user:
                return JSONResponse(status_code=401, content={"message": "Unauthenticated"})

            if not user.user_isactive:
                return JSONResponse(status_code=402, content={"message": "Your account has been disabled"})

            # pass user to request
            request.state.user = user

        finally:
            db.close()

        response = await call_next(request)
        return response