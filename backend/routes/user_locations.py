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
        # update existing record instead of creating new one
        existing.latitude = payload.latitude
        existing.longitude = payload.longitude
        existing.is_enabled = True
        db.commit()
        db.refresh(existing)
        # Write-through to Redis
        redis_client.hset(f"user_location:{current_user.user_id}", mapping={
            "lat": existing.latitude,
            "lng": existing.longitude,
            "is_enabled": int(existing.is_enabled)
        })
        redis_client.expire(f"user_location:{current_user.user_id}", 30)
        geo = _reverse_geocode(existing.latitude, existing.longitude)
        return UserLocationResponse(**existing.__dict__, city=geo["city"], street=geo["street"])

    # if no record exists - creates one
    location = UserLocation(
        user_id=current_user.user_id,
        latitude=payload.latitude,
        longitude=payload.longitude,
        is_enabled=True
    )
    db.add(location)
    db.commit()
    db.refresh(location)
    # Write-through to Redis
    redis_client.hset(f"user_location:{current_user.user_id}", mapping={
        "lat": location.latitude,
        "lng": location.longitude,
        "is_enabled": int(location.is_enabled)
    })
    redis_client.expire(f"user_location:{current_user.user_id}", 30)
    geo = _reverse_geocode(location.latitude, location.longitude)
    return UserLocationResponse(**location.__dict__, city=geo["city"], street=geo["street"])


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

    db.commit()
    db.refresh(location)
    # Write-through to Redis
    redis_client.hset(f"user_location:{current_user.user_id}", mapping={
        "lat": location.latitude,
        "lng": location.longitude,
        "is_enabled": int(location.is_enabled)
    })
    redis_client.expire(f"user_location:{current_user.user_id}", 30)
    geo = _reverse_geocode(location.latitude, location.longitude)
    return UserLocationResponse(**location.__dict__, city=geo["city"], street=geo["street"])


@router.delete("/", status_code=204)
def delete_user_location(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_auth)
):
    """Delete location sharing (deletes permissions first, then location record)."""
    location = db.query(UserLocation).filter(UserLocation.user_id == current_user.user_id).first()

    if not location:
        raise HTTPException(status_code=404, detail="User location not found")

    # Delete all location permissions for this location first
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

    geo = _reverse_geocode(location.latitude, location.longitude)
    return UserLocationResponse(**location.__dict__, city=geo["city"], street=geo["street"])


@router.get("/friends", status_code=200, response_model=list[UserLocationResponse])
def get_friends_locations(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_auth)
):
    """Return UserLocation records for friends who are sharing with the logged-in user."""
    # Get all friends with permission
    friends_query = (
        db.query(UserLocation)
        .join(LocationPermission, LocationPermission.user_loc_id == UserLocation.user_loc_id)
        .filter(
            LocationPermission.user_id == current_user.user_id,
            UserLocation.is_enabled == True
        )
    )
    friends = friends_query.all()

    # Try to get each friend's location from Redis
    results = []
    for friend in friends:
        cache = redis_client.hgetall(f"user_location:{friend.user_id}")
        if cache and "lat" in cache and "lng" in cache and "is_enabled" in cache:
            lat, lng = float(cache["lat"]), float(cache["lng"])
            geo = _reverse_geocode(lat, lng)
            results.append(UserLocationResponse(
                user_loc_id=friend.user_loc_id,
                user_id=friend.user_id,
                latitude=lat,
                longitude=lng,
                is_enabled=bool(int(cache["is_enabled"])),
                created_at=friend.created_at,
                updated_at=friend.updated_at,
                city=geo["city"],
                street=geo["street"]
            ))
        else:
            # Fallback to DB, and update Redis for next time
            geo = _reverse_geocode(friend.latitude, friend.longitude)
            results.append(UserLocationResponse(
                user_loc_id=friend.user_loc_id,
                user_id=friend.user_id,
                latitude=friend.latitude,
                longitude=friend.longitude,
                is_enabled=friend.is_enabled,
                created_at=friend.created_at,
                updated_at=friend.updated_at,
                city=geo["city"],
                street=geo["street"]
            ))
            redis_client.hset(f"user_location:{friend.user_id}", mapping={
                "lat": friend.latitude,
                "lng": friend.longitude,
                "is_enabled": int(friend.is_enabled)
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
    # Validate user location exists
    user_location = db.query(UserLocation).filter(UserLocation.user_id == current_user.user_id).first()
    if not user_location:
        raise HTTPException(status_code=404, detail="User location not found. Please create one first.")

    # Validate friend exists in current user's friends list
    friend = db.query(User).filter(User.user_id == payload.user_id).first()
    if not friend:
        raise HTTPException(status_code=404, detail="Friend not found")

    if friend not in current_user.friends:
        raise HTTPException(status_code=403, detail="User is not your friend")

    # Create permission
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
    # Get current user's location
    user_location = db.query(UserLocation).filter(UserLocation.user_id == current_user.user_id).first()
    if not user_location:
        raise HTTPException(status_code=404, detail="User location not found")

    # Find and delete the permission
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
