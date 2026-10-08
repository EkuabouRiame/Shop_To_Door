from flask import Blueprint, jsonify, request

import random
from datetime import datetime, timedelta

from flask_jwt_extended import (
    create_access_token,
    get_jwt_identity,
    jwt_required,
)

from flask_mail import Message

from ..extensions import db, mail
from ..models import User


auth_bp = Blueprint(
    "auth",
    __name__,
    url_prefix="/api/auth",
)


# =====================================================
# PASSWORD RESET OTP STORAGE
# =====================================================

password_reset_otps = {}


# =====================================================
# USER SERIALIZER
# =====================================================

def user_to_dict(user):
    return {
        "id": user.id,
        "name": user.name,
        "email": user.email,
        "phone": user.phone,
        "role": user.role,
        "is_active": user.is_active,
        "created_at": user.created_at.isoformat()
        if user.created_at
        else None,
        "updated_at": user.updated_at.isoformat()
        if user.updated_at
        else None,
    }


# =====================================================
# CURRENT USER FROM JWT
# =====================================================

def get_current_user_from_token():
    identity = get_jwt_identity()

    try:
        user_id = int(identity)
    except (TypeError, ValueError):
        return None

    return (
        db.session.query(User)
        .filter(User.id == user_id)
        .first()
    )


# =====================================================
# REQUIRE ADMIN USER
# =====================================================

def require_admin_user():
    user = get_current_user_from_token()

    if not user:
        return None, (
            jsonify({
                "status": "error",
                "message": "User not found",
            }),
            404,
        )

    if not user.is_active:
        return None, (
            jsonify({
                "status": "error",
                "message": "This account is inactive",
            }),
            403,
        )

    if user.role != "admin":
        return None, (
            jsonify({
                "status": "error",
                "message": "Admin access is required",
            }),
            403,
        )

    return user, None


# =====================================================
# REGISTER
# =====================================================

@auth_bp.post("/register")
def register():
    data = request.get_json(silent=True)

    if not data:
        return jsonify({
            "status": "error",
            "message": "Request body must contain JSON data",
        }), 400

    name = str(data.get("name", "")).strip()
    email = str(data.get("email", "")).strip().lower()
    phone = str(data.get("phone", "")).strip()
    password = str(data.get("password", ""))

    if not name:
        return jsonify({
            "status": "error",
            "message": "Name is required",
        }), 400

    if not email:
        return jsonify({
            "status": "error",
            "message": "Email is required",
        }), 400

    if not password:
        return jsonify({
            "status": "error",
            "message": "Password is required",
        }), 400

    if len(password) < 6:
        return jsonify({
            "status": "error",
            "message": "Password must contain at least 6 characters",
        }), 400

    existing_email = (
        db.session.query(User)
        .filter(User.email == email)
        .first()
    )

    if existing_email:
        return jsonify({
            "status": "error",
            "message": "Email is already registered",
        }), 409

    if phone:
        existing_phone = (
            db.session.query(User)
            .filter(User.phone == phone)
            .first()
        )

        if existing_phone:
            return jsonify({
                "status": "error",
                "message": "Phone number is already registered",
            }), 409

    user = User(
        name=name,
        email=email,
        phone=phone if phone else None,
        role="customer",
        is_active=True,
    )

    user.set_password(password)

    db.session.add(user)
    db.session.commit()

    access_token = create_access_token(
        identity=str(user.id)
    )

    return jsonify({
        "status": "success",
        "message": "Registration successful",
        "user": user_to_dict(user),
        "access_token": access_token,
    }), 201


# =====================================================
# CREATE DELIVERY ACCOUNT
# =====================================================

@auth_bp.post("/admin/delivery-accounts")
@jwt_required()
def create_delivery_account():
    admin, error_response = require_admin_user()

    if error_response:
        return error_response

    data = request.get_json(silent=True)

    if not data:
        return jsonify({
            "status": "error",
            "message": "Request body must contain JSON data",
        }), 400

    name = str(data.get("name", "")).strip()
    email = str(data.get("email", "")).strip().lower()
    phone = str(data.get("phone", "")).strip()

    # Password created by the admin
    password = str(data.get("password", ""))

    # Password confirmation entered by the admin
    confirm_password = str(
        data.get("confirm_password", "")
    )

    # -------------------------------------------------
    # BASIC VALIDATION
    # -------------------------------------------------

    if not name:
        return jsonify({
            "status": "error",
            "message": "Name is required",
        }), 400

    if not email:
        return jsonify({
            "status": "error",
            "message": "Email is required",
        }), 400

    # -------------------------------------------------
    # PASSWORD VALIDATION
    # -------------------------------------------------

    if not password:
        return jsonify({
            "status": "error",
            "message": "Password is required",
        }), 400

    if len(password) < 6:
        return jsonify({
            "status": "error",
            "message": "Password must contain at least 6 characters",
        }), 400

    if not confirm_password:
        return jsonify({
            "status": "error",
            "message": "Please confirm the password",
        }), 400

    if password != confirm_password:
        return jsonify({
            "status": "error",
            "message": "Passwords do not match",
        }), 400

    # -------------------------------------------------
    # CHECK EMAIL
    # -------------------------------------------------

    existing_email = (
        db.session.query(User)
        .filter(User.email == email)
        .first()
    )

    if existing_email:
        return jsonify({
            "status": "error",
            "message": "Email is already registered",
        }), 409

    # -------------------------------------------------
    # CHECK PHONE
    # -------------------------------------------------

    if phone:
        existing_phone = (
            db.session.query(User)
            .filter(User.phone == phone)
            .first()
        )

        if existing_phone:
            return jsonify({
                "status": "error",
                "message": "Phone number is already registered",
            }), 409

    # -------------------------------------------------
    # CREATE DELIVERY USER
    # -------------------------------------------------

    delivery_user = User(
        name=name,
        email=email,
        phone=phone if phone else None,
        role="delivery_person",
        is_active=True,
    )

    # Store the password securely using the User model.
    delivery_user.set_password(password)

    try:
        db.session.add(delivery_user)
        db.session.commit()

    except Exception:
        db.session.rollback()

        return jsonify({
            "status": "error",
            "message": "Unable to create delivery account",
        }), 500

    # -------------------------------------------------
    # SUCCESS
    # -------------------------------------------------

    return jsonify({
        "status": "success",
        "message": "Delivery account created successfully",
        "user": user_to_dict(delivery_user),
        "created_by": admin.id,
    }), 201


# =====================================================
# DELETE DELIVERY ACCOUNT
# =====================================================

@auth_bp.delete("/admin/delivery-accounts/<int:delivery_user_id>")
@jwt_required()
def delete_delivery_account(delivery_user_id):
    admin, error_response = require_admin_user()

    if error_response:
        return error_response

    delivery_user = (
        db.session.query(User)
        .filter(
            User.id == delivery_user_id,
            User.role == "delivery_person",
        )
        .first()
    )

    if not delivery_user:
        return jsonify({
            "status": "error",
            "message": "Delivery account not found",
        }), 404

    try:
        db.session.delete(delivery_user)
        db.session.commit()

    except Exception:
        db.session.rollback()

        return jsonify({
            "status": "error",
            "message": "Unable to delete delivery account",
        }), 500

    return jsonify({
        "status": "success",
        "message": "Delivery account deleted successfully",
        "deleted_user_id": delivery_user_id,
        "deleted_by": admin.id,
    }), 200


# =====================================================
# LOGIN
# =====================================================

@auth_bp.post("/login")
def login():
    data = request.get_json(silent=True)

    if not data:
        return jsonify({
            "status": "error",
            "message": "Request body must contain JSON data",
        }), 400

    email = str(data.get("email", "")).strip().lower()
    password = str(data.get("password", ""))

    if not email:
        return jsonify({
            "status": "error",
            "message": "Email is required",
        }), 400

    if not password:
        return jsonify({
            "status": "error",
            "message": "Password is required",
        }), 400

    user = (
        db.session.query(User)
        .filter(User.email == email)
        .first()
    )

    if not user:
        return jsonify({
            "status": "error",
            "message": "Invalid email or password",
        }), 401

    if not user.is_active:
        return jsonify({
            "status": "error",
            "message": "This account is inactive",
        }), 403

    if not user.check_password(password):
        return jsonify({
            "status": "error",
            "message": "Invalid email or password",
        }), 401

    access_token = create_access_token(
        identity=str(user.id)
    )

    return jsonify({
        "status": "success",
        "message": "Login successful",
        "user": user_to_dict(user),
        "access_token": access_token,
    }), 200


# =====================================================
# FORGOT PASSWORD - SEND OTP
# =====================================================

@auth_bp.post("/forgot-password")
def forgot_password():
    data = request.get_json(silent=True)

    if not data:
        return jsonify({
            "status": "error",
            "message": "Request body must contain JSON data",
        }), 400

    email = str(
        data.get("email", "")
    ).strip().lower()

    if not email:
        return jsonify({
            "status": "error",
            "message": "Email is required",
        }), 400

    user = (
        db.session.query(User)
        .filter(User.email == email)
        .first()
    )

    # Do not reveal whether an email exists.
    if not user:
        return jsonify({
            "status": "success",
            "message": (
                "If an account exists for this email, "
                "an OTP has been sent."
            ),
        }), 200

    if not user.is_active:
        return jsonify({
            "status": "success",
            "message": (
                "If an account exists for this email, "
                "an OTP has been sent."
            ),
        }), 200

    # Generate a six-digit OTP.
    otp = f"{random.randint(0, 999999):06d}"

    # OTP expires after 10 minutes.
    expires_at = datetime.utcnow() + timedelta(minutes=10)

    password_reset_otps[email] = {
        "otp": otp,
        "expires_at": expires_at,
        "verified": False,
    }

    try:
        message = Message(
            subject="Shop To Door - Password Reset OTP",
            recipients=[email],
        )

        message.body = f"""
Hello {user.name},

We received a request to reset your Shop To Door password.

Your password reset OTP is:

{otp}

This OTP will expire in 10 minutes.

If you did not request a password reset, you can safely ignore this email.

Regards,
Shop To Door
"""

        mail.send(message)

    except Exception as error:
        print("Password reset email error:", error)

        password_reset_otps.pop(email, None)

        return jsonify({
            "status": "error",
            "message": (
                "Unable to send the password reset email. "
                "Please try again later."
            ),
        }), 500

    return jsonify({
        "status": "success",
        "message": (
            "If an account exists for this email, "
            "an OTP has been sent."
        ),
    }), 200


# =====================================================
# VERIFY PASSWORD RESET OTP
# =====================================================

@auth_bp.post("/verify-reset-otp")
def verify_reset_otp():
    data = request.get_json(silent=True)

    if not data:
        return jsonify({
            "status": "error",
            "message": "Request body must contain JSON data",
        }), 400

    email = str(
        data.get("email", "")
    ).strip().lower()

    otp = str(
        data.get("otp", "")
    ).strip()

    if not email:
        return jsonify({
            "status": "error",
            "message": "Email is required",
        }), 400

    if not otp:
        return jsonify({
            "status": "error",
            "message": "OTP is required",
        }), 400

    reset_data = password_reset_otps.get(email)

    if not reset_data:
        return jsonify({
            "status": "error",
            "message": "OTP is invalid or has expired",
        }), 400

    if datetime.utcnow() > reset_data["expires_at"]:
        password_reset_otps.pop(email, None)

        return jsonify({
            "status": "error",
            "message": (
                "OTP has expired. Please request a new OTP."
            ),
        }), 400

    if reset_data["otp"] != otp:
        return jsonify({
            "status": "error",
            "message": "Invalid OTP",
        }), 400

    reset_data["verified"] = True

    return jsonify({
        "status": "success",
        "message": "OTP verified successfully",
    }), 200


# =====================================================
# RESET PASSWORD
# =====================================================

@auth_bp.post("/reset-password")
def reset_password():
    data = request.get_json(silent=True)

    if not data:
        return jsonify({
            "status": "error",
            "message": "Request body must contain JSON data",
        }), 400

    email = str(
        data.get("email", "")
    ).strip().lower()

    new_password = str(
        data.get("new_password", "")
    )

    confirm_password = str(
        data.get("confirm_password", "")
    )

    if not email:
        return jsonify({
            "status": "error",
            "message": "Email is required",
        }), 400

    if not new_password:
        return jsonify({
            "status": "error",
            "message": "New password is required",
        }), 400

    if len(new_password) < 6:
        return jsonify({
            "status": "error",
            "message": (
                "Password must contain at least 6 characters"
            ),
        }), 400

    if new_password != confirm_password:
        return jsonify({
            "status": "error",
            "message": "Passwords do not match",
        }), 400

    reset_data = password_reset_otps.get(email)

    if not reset_data:
        return jsonify({
            "status": "error",
            "message": (
                "Password reset session is invalid or expired"
            ),
        }), 400

    if datetime.utcnow() > reset_data["expires_at"]:
        password_reset_otps.pop(email, None)

        return jsonify({
            "status": "error",
            "message": (
                "Password reset session has expired. "
                "Please request a new OTP."
            ),
        }), 400

    if not reset_data.get("verified"):
        return jsonify({
            "status": "error",
            "message": "Please verify the OTP first",
        }), 400

    user = (
        db.session.query(User)
        .filter(User.email == email)
        .first()
    )

    if not user:
        password_reset_otps.pop(email, None)

        return jsonify({
            "status": "error",
            "message": "Unable to reset password",
        }), 400

    if not user.is_active:
        password_reset_otps.pop(email, None)

        return jsonify({
            "status": "error",
            "message": "This account is inactive",
        }), 403

    user.set_password(new_password)

    try:
        db.session.commit()

    except Exception:
        db.session.rollback()

        return jsonify({
            "status": "error",
            "message": "Unable to reset password",
        }), 500

    # OTP can only be used once.
    password_reset_otps.pop(email, None)

    return jsonify({
        "status": "success",
        "message": (
            "Password reset successful. "
            "You can now log in with your new password."
        ),
    }), 200


# =====================================================
# CURRENT USER
# =====================================================

@auth_bp.get("/me")
@jwt_required()
def get_current_user():
    user = get_current_user_from_token()

    if not user:
        return jsonify({
            "status": "error",
            "message": "User not found",
        }), 404

    if not user.is_active:
        return jsonify({
            "status": "error",
            "message": "This account is inactive",
        }), 403

    return jsonify({
        "status": "success",
        "user": user_to_dict(user),
    }), 200


# =====================================================
# LOGOUT
# =====================================================

@auth_bp.post("/logout")
@jwt_required()
def logout():
    return jsonify({
        "status": "success",
        "message": (
            "Logout successful. "
            "Remove the access token from the client."
        ),
    }), 200