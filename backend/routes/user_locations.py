from datetime import datetime, timezone
from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from geopy.geocoders import Nominatim

from database.db import get_db
from database.redis import redis_client
from middleware.auth import require_auth
from models.user import User
from models.user_location import UserLocation
from models.location_permission import LocationPermission
from schemas.UserLocation import CreateUserLocation, UpdateUserLocation, UserLocationResponse
from schemas.LocationPermission import CreateLocationPermission, LocationPermissionResponse
from checkpins.checkpinactivity import deactivate_expired_sharing

_geolocator = Nominatim(user_agent="campus_connect")


def _reverse_geocode(lat: float, lng: float) -> dict:
    """Return city and street for a coordinate pair, or None if lookup fails."""
    try:
        result = _geolocator.reverse((lat, lng), timeout=5)
        if result and result.raw.get("address"):
            addr = result.raw["address"]
            city = addr.get("city") or addr.get("town") or addr.get("village") or addr.get("county")
            street = addr.get("road") or addr.get("pedestrian") or addr.get("footway")
            return {"city": city, "street": street}
    except Exception:
        pass
    return {"city": None, "street": None}


def _ensure_utc_aware(dt: datetime | None):
    """Return a timezone-aware UTC datetime or None.

    SQLAlchemy stores naive datetimes in UTC. When returning values via
    FastAPI/Pydantic, make sure datetimes are marked as UTC so the JSON
    serializer emits timezone-aware ISO strings (with trailing 'Z').
    """
    if dt is None:
        return None
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)

router = APIRouter(prefix="/user-locations", tags=["user-locations"])
location_permissions_router = APIRouter(prefix="/location-permissions", tags=["location-permissions"])


@router.post("/", status_code=201, response_model=UserLocationResponse)
def create_or_update_user_location(
    payload: CreateUserLocation,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_auth)
):
    """Create new user location record, or update existing one if exists."""
    existing = db.query(UserLocation).filter(UserLocation.user_id == current_user.user_id).first()

    if existing:
        existing.latitude = payload.latitude
        existing.longitude = payload.longitude
        existing.is_enabled = True
        db.commit()
        db.refresh(existing)
        geo = _reverse_geocode(existing.latitude, existing.longitude)
        redis_client.hset(f"user_location:{current_user.user_id}", mapping={
            "lat": existing.latitude,
            "lng": existing.longitude,
            "is_enabled": int(existing.is_enabled),
            "city": geo["city"] or "",
            "street": geo["street"] or ""
        })
        redis_client.expire(f"user_location:{current_user.user_id}", 30)
        resp = existing.__dict__.copy()
        resp['created_at'] = _ensure_utc_aware(existing.created_at)
        resp['updated_at'] = _ensure_utc_aware(existing.updated_at)
        resp['sharing_expires_at'] = _ensure_utc_aware(existing.sharing_expires_at)
        resp['city'] = geo["city"]
        resp['street'] = geo["street"]
        return UserLocationResponse(**resp)

    location = UserLocation(
        user_id=current_user.user_id,
        latitude=payload.latitude,
        longitude=payload.longitude,
        is_enabled=True
    )
    db.add(location)
    db.commit()
    db.refresh(location)
    geo = _reverse_geocode(location.latitude, location.longitude)
    redis_client.hset(f"user_location:{current_user.user_id}", mapping={
        "lat": location.latitude,
        "lng": location.longitude,
        "is_enabled": int(location.is_enabled),
        "city": geo["city"] or "",
        "street": geo["street"] or ""
    })
    redis_client.expire(f"user_location:{current_user.user_id}", 30)
    resp = location.__dict__.copy()
    resp['created_at'] = _ensure_utc_aware(location.created_at)
    resp['updated_at'] = _ensure_utc_aware(location.updated_at)
    resp['sharing_expires_at'] = _ensure_utc_aware(location.sharing_expires_at)
    resp['city'] = geo["city"]
    resp['street'] = geo["street"]
    return UserLocationResponse(**resp)


@router.patch("/", status_code=200, response_model=UserLocationResponse)
def update_user_location(
    payload: UpdateUserLocation,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_auth)
):
    """Update the location record for the logged-in user."""
    location = db.query(UserLocation).filter(UserLocation.user_id == current_user.user_id).first()

    if not location:
        raise HTTPException(status_code=404, detail="User location not found")

    # Update only provided fields
    if payload.latitude is not None:
        location.latitude = payload.latitude
    if payload.longitude is not None:
        location.longitude = payload.longitude
    if payload.is_enabled is not None:
        location.is_enabled = payload.is_enabled
    # Normalize incoming sharing_expires_at to UTC (naive) to avoid
    # naive/aware datetime comparison errors later in cleanup jobs.
    def _to_utc_naive(dt: datetime | None):
        if dt is None:
            return None
        if dt.tzinfo is None:
            # Treat naive datetimes as UTC
            return dt
        return dt.astimezone(timezone.utc).replace(tzinfo=None)

    # If the request explicitly included the sharing_expires_at field (even null),
    # apply it. Use __fields_set__ to distinguish omission vs explicit null.
    if 'sharing_expires_at' in getattr(payload, '__fields_set__', set()):
        location.sharing_expires_at = _to_utc_naive(payload.sharing_expires_at)

    # If disabling sharing, clear the expiry
    if payload.is_enabled is False:
        location.sharing_expires_at = None

    db.commit()
    db.refresh(location)
    geo = _reverse_geocode(location.latitude, location.longitude)
    redis_client.hset(f"user_location:{current_user.user_id}", mapping={
        "lat": location.latitude,
        "lng": location.longitude,
        "is_enabled": int(location.is_enabled),
        "city": geo["city"] or "",
        "street": geo["street"] or ""
    })
    redis_client.expire(f"user_location:{current_user.user_id}", 30)
    resp = location.__dict__.copy()
    resp['created_at'] = _ensure_utc_aware(location.created_at)
    resp['updated_at'] = _ensure_utc_aware(location.updated_at)
    resp['sharing_expires_at'] = _ensure_utc_aware(location.sharing_expires_at)
    resp['city'] = geo["city"]
    resp['street'] = geo["street"]
    return UserLocationResponse(**resp)


@router.delete("/", status_code=204)
def delete_user_location(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_auth)
):
    """Delete location sharing (deletes permissions first, then location record)."""
    location = db.query(UserLocation).filter(UserLocation.user_id == current_user.user_id).first()

    if not location:
        raise HTTPException(status_code=404, detail="User location not found")

    db.query(LocationPermission).filter(LocationPermission.user_loc_id == location.user_loc_id).delete()
    db.delete(location)
    db.commit()


@router.get("/", status_code=200, response_model=UserLocationResponse)
def get_user_location(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_auth)
):
    """Return the location record for the logged-in user."""
    location = db.query(UserLocation).filter(UserLocation.user_id == current_user.user_id).first()

    if not location:
        raise HTTPException(status_code=404, detail="User location not found")

    # Auto-disable if sharing has expired
    if location.sharing_expires_at and datetime.utcnow() > location.sharing_expires_at:
        location.is_enabled = False
        location.sharing_expires_at = None
        db.commit()
        db.refresh(location)
        # Update Redis so other clients see the disabled state immediately
        try:
            redis_client.hset(f"user_location:{current_user.user_id}", mapping={
                "lat": location.latitude,
                "lng": location.longitude,
                "is_enabled": int(location.is_enabled),
                "city": "",
                "street": "",
            })
            redis_client.expire(f"user_location:{current_user.user_id}", 30)
        except Exception:
            pass

    resp = location.__dict__.copy()
    resp['created_at'] = _ensure_utc_aware(location.created_at)
    resp['updated_at'] = _ensure_utc_aware(location.updated_at)
    resp['sharing_expires_at'] = _ensure_utc_aware(location.sharing_expires_at)
    resp['city'] = None
    resp['street'] = None
    return UserLocationResponse(**resp)


@router.get("/friends", status_code=200, response_model=list[UserLocationResponse])
def get_friends_locations(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_auth)
):
    """Return UserLocation records for friends who are sharing with the logged-in user."""
    friends_query = (
        db.query(UserLocation)
        .join(LocationPermission, LocationPermission.user_loc_id == UserLocation.user_loc_id)
        .filter(
            LocationPermission.user_id == current_user.user_id,
            UserLocation.is_enabled == True
        )
    )
    friends = friends_query.all()

    now = datetime.utcnow()
    results = []
    for friend in friends:
        # Skip friends whose sharing has expired and disable them
        if friend.sharing_expires_at and now > friend.sharing_expires_at:
            friend.is_enabled = False
            friend.sharing_expires_at = None
            db.commit()
            # Ensure cache reflects disabled state so requesting client doesn't get stale data
            try:
                redis_client.hset(f"user_location:{friend.user_id}", mapping={
                    "lat": friend.latitude,
                    "lng": friend.longitude,
                    "is_enabled": int(friend.is_enabled),
                    "city": "",
                    "street": "",
                })
                redis_client.expire(f"user_location:{friend.user_id}", 30)
            except Exception:
                pass
            continue

        cache = redis_client.hgetall(f"user_location:{friend.user_id}")
        if cache and "lat" in cache and "lng" in cache and "is_enabled" in cache:
            lat, lng = float(cache["lat"]), float(cache["lng"])
            city = cache.get("city") or None
            street = cache.get("street") or None
            if city is None and street is None:
                geo = _reverse_geocode(lat, lng)
                city, street = geo["city"], geo["street"]
            results.append(UserLocationResponse(
                user_loc_id=friend.user_loc_id,
                user_id=friend.user_id,
                latitude=lat,
                longitude=lng,
                is_enabled=bool(int(cache["is_enabled"])),
                created_at=_ensure_utc_aware(friend.created_at),
                updated_at=_ensure_utc_aware(friend.updated_at),
                sharing_expires_at=_ensure_utc_aware(friend.sharing_expires_at),
                city=city,
                street=street
            ))
        else:
            geo = _reverse_geocode(friend.latitude, friend.longitude)
            results.append(UserLocationResponse(
                user_loc_id=friend.user_loc_id,
                user_id=friend.user_id,
                latitude=friend.latitude,
                longitude=friend.longitude,
                is_enabled=friend.is_enabled,
                created_at=_ensure_utc_aware(friend.created_at),
                updated_at=_ensure_utc_aware(friend.updated_at),
                sharing_expires_at=_ensure_utc_aware(friend.sharing_expires_at),
                city=geo["city"],
                street=geo["street"]
            ))
            redis_client.hset(f"user_location:{friend.user_id}", mapping={
                "lat": friend.latitude,
                "lng": friend.longitude,
                "is_enabled": int(friend.is_enabled),
                "city": geo["city"] or "",
                "street": geo["street"] or ""
            })
            redis_client.expire(f"user_location:{friend.user_id}", 30)

    return results


@location_permissions_router.post("/", status_code=201, response_model=LocationPermissionResponse)
def create_location_permission(
    payload: CreateLocationPermission,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_auth)
):
    """Create a location permission (share location with a friend)."""
    user_location = db.query(UserLocation).filter(UserLocation.user_id == current_user.user_id).first()
    if not user_location:
        raise HTTPException(status_code=404, detail="User location not found. Please create one first.")

    friend = db.query(User).filter(User.user_id == payload.user_id).first()
    if not friend:
        raise HTTPException(status_code=404, detail="Friend not found")

    if friend not in current_user.friends:
        raise HTTPException(status_code=403, detail="User is not your friend")

    permission = LocationPermission(
        user_loc_id=user_location.user_loc_id,
        user_id=payload.user_id
    )
    db.add(permission)
    db.commit()
    db.refresh(permission)
    return permission


@location_permissions_router.delete("/{user_id}", status_code=204)
def delete_location_permission(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_auth)
):
    """Delete a location permission (stop sharing with a friend)."""
    user_location = db.query(UserLocation).filter(UserLocation.user_id == current_user.user_id).first()
    if not user_location:
        raise HTTPException(status_code=404, detail="User location not found")

    permission = db.query(LocationPermission).filter(
        LocationPermission.user_loc_id == user_location.user_loc_id,
        LocationPermission.user_id == user_id
    ).first()

    if not permission:
        raise HTTPException(status_code=404, detail="Location permission not found")

    db.delete(permission)
    db.commit()


@location_permissions_router.get("/", status_code=200, response_model=list[LocationPermissionResponse])
def get_location_permissions(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_auth)
):
    """Return list of friends the user is sharing location with."""
    user_location = db.query(UserLocation).filter(UserLocation.user_id == current_user.user_id).first()
    if not user_location:
        raise HTTPException(status_code=404, detail="User location not found")

    permissions = db.query(LocationPermission).filter(
        LocationPermission.user_loc_id == user_location.user_loc_id
    ).all()

    return permissions


@router.post('/expire-now')
def expire_now(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_auth)
):
    """Trigger server-side expiry processing immediately (diagnostic endpoint)."""
    try:
        deactivate_expired_sharing()
        return {"detail": "expiry processed"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))