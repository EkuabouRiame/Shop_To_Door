from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity

from ..extensions import db
from ..models import User


users_bp = Blueprint(
    "users",
    __name__,
    url_prefix="/api/users"
)


# =========================================================
# SAVE USER LOCATION
# =========================================================

@users_bp.post("/location")
@jwt_required()
def save_location():

    data = request.get_json(silent=True)

    if not data:
        return jsonify({
            "status": "error",
            "message": "Request body must contain JSON data"
        }), 400

    # =====================================================
    # GET LOCATION DATA
    # =====================================================

    latitude = data.get("latitude")
    longitude = data.get("longitude")

    address = str(
        data.get("address", "")
    ).strip()

    city = str(
        data.get("city", "")
    ).strip()

    state = str(
        data.get("state", "")
    ).strip()

    pincode = str(
        data.get("pincode", "")
    ).strip()

    # =====================================================
    # VALIDATE COORDINATES
    # =====================================================

    if latitude is None or longitude is None:

        return jsonify({
            "status": "error",
            "message": "Latitude and longitude are required"
        }), 400

    try:

        latitude = float(latitude)
        longitude = float(longitude)

    except (TypeError, ValueError):

        return jsonify({
            "status": "error",
            "message": "Latitude and longitude must be numbers"
        }), 400

    # =====================================================
    # VALIDATE LATITUDE
    # =====================================================

    if latitude < -90 or latitude > 90:

        return jsonify({
            "status": "error",
            "message": "Invalid latitude"
        }), 400

    # =====================================================
    # VALIDATE LONGITUDE
    # =====================================================

    if longitude < -180 or longitude > 180:

        return jsonify({
            "status": "error",
            "message": "Invalid longitude"
        }), 400

    # =====================================================
    # GET LOGGED-IN USER
    # =====================================================

    user_id = get_jwt_identity()

    try:

        user_id = int(user_id)

    except (TypeError, ValueError):

        return jsonify({
            "status": "error",
            "message": "Invalid user identity"
        }), 401

    user = (
        db.session.query(User)
        .filter(User.id == user_id)
        .first()
    )

    if not user:

        return jsonify({
            "status": "error",
            "message": "User not found"
        }), 404

    # =====================================================
    # SAVE LOCATION
    # =====================================================

    user.latitude = latitude
    user.longitude = longitude

    user.address = address if address else None
    user.city = city if city else None
    user.state = state if state else None
    user.pincode = pincode if pincode else None

    # =====================================================
    # SAVE TO DATABASE
    # =====================================================

    try:

        db.session.commit()

    except Exception:

        db.session.rollback()

        return jsonify({
            "status": "error",
            "message": "Failed to save user location"
        }), 500

    # =====================================================
    # RESPONSE
    # =====================================================

    return jsonify({

        "status": "success",

        "message": "Location saved successfully",

        "location": {

            "latitude": user.latitude,
            "longitude": user.longitude,

            "address": user.address,
            "city": user.city,
            "state": user.state,
            "pincode": user.pincode

        }

    }), 200


# =========================================================
# GET USER LOCATION
# =========================================================

@users_bp.get("/location")
@jwt_required()
def get_location():

    user_id = get_jwt_identity()

    try:

        user_id = int(user_id)

    except (TypeError, ValueError):

        return jsonify({
            "status": "error",
            "message": "Invalid user identity"
        }), 401

    user = (
        db.session.query(User)
        .filter(User.id == user_id)
        .first()
    )

    if not user:

        return jsonify({
            "status": "error",
            "message": "User not found"
        }), 404

    return jsonify({

        "status": "success",

        "location": {

            "latitude": user.latitude,
            "longitude": user.longitude,

            "address": user.address,
            "city": user.city,
            "state": user.state,
            "pincode": user.pincode

        }

    }), 200