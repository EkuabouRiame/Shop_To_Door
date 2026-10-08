import hashlib
import os
import secrets
from datetime import datetime, timedelta, timezone

from flask import Blueprint, jsonify
from flask_jwt_extended import get_jwt_identity, jwt_required
from sqlalchemy import text

from ..extensions import db
from ..models.order import Order
from ..models.user import User


delivery_confirmation_bp = Blueprint(
    "delivery_confirmation",
    __name__,
    url_prefix="/api/orders",
)


QR_EXPIRY_MINUTES = 10


# =========================================================
# HELPERS
# =========================================================

def get_current_user_id():
    try:
        identity = get_jwt_identity()
        return int(identity)
    except (TypeError, ValueError):
        return None


def get_current_user():
    user_id = get_current_user_id()

    if not user_id:
        return None

    return db.session.get(User, user_id)


def get_delivery_person():
    user = get_current_user()

    if not user:
        return None

    if str(user.role).lower() != "delivery_person":
        return None

    return user


def hash_token(token):
    return hashlib.sha256(
        token.encode("utf-8")
    ).hexdigest()


def utc_now():
    return datetime.now(timezone.utc)


# =========================================================
# GENERATE DELIVERY QR
# =========================================================

@delivery_confirmation_bp.post(
    "/delivery/<int:order_id>/confirmation-qr"
)
@jwt_required()
def generate_confirmation_qr(order_id):

    delivery_person = get_delivery_person()

    if not delivery_person:
        return jsonify({
            "status": "error",
            "message": "Delivery person access required.",
        }), 403

    order = db.session.get(
        Order,
        order_id
    )

    if not order:
        return jsonify({
            "status": "error",
            "message": "Order not found.",
        }), 404

    # Only the delivery person assigned to this
    # order can generate the QR.
    if order.delivery_person_id != delivery_person.id:
        return jsonify({
            "status": "error",
            "message": (
                "You are not assigned to this order."
            ),
        }), 403

    # QR can only be generated when the order is
    # out for delivery.
    if order.status != "out_for_delivery":
        return jsonify({
            "status": "error",
            "message": (
                "Delivery QR can only be generated "
                "for an out-for-delivery order."
            ),
        }), 400

    # -----------------------------------------------------
    # Remove previous unused QR codes for this order.
    # -----------------------------------------------------

    db.session.execute(
        text("""
            DELETE FROM delivery_confirmation_challenges
            WHERE order_id = :order_id
              AND confirmed_at IS NULL
        """),
        {
            "order_id": order.id,
        },
    )

    # -----------------------------------------------------
    # Generate secure random token.
    # -----------------------------------------------------

    token = secrets.token_urlsafe(32)

    token_hash = hash_token(token)

    created_at = utc_now()

    expires_at = (
        created_at
        + timedelta(
            minutes=QR_EXPIRY_MINUTES
        )
    )

    # -----------------------------------------------------
    # Save only the token hash.
    # -----------------------------------------------------

    db.session.execute(
        text("""
            INSERT INTO delivery_confirmation_challenges (
                order_id,
                delivery_person_id,
                customer_id,
                token_hash,
                created_at,
                expires_at,
                confirmed_at
            )
            VALUES (
                :order_id,
                :delivery_person_id,
                :customer_id,
                :token_hash,
                :created_at,
                :expires_at,
                NULL
            )
        """),
        {
            "order_id": order.id,
            "delivery_person_id": delivery_person.id,
            "customer_id": order.user_id,
            "token_hash": token_hash,
            "created_at": created_at,
            "expires_at": expires_at,
        },
    )

    db.session.commit()

    # -----------------------------------------------------
    # Frontend URL
    # -----------------------------------------------------

    frontend_url = os.getenv(
        "FRONTEND_URL",
        "http://localhost:5173"
    )

    confirmation_url = (
        f"{frontend_url.rstrip('/')}"
        f"/delivery-confirmation/{token}"
    )

    return jsonify({
        "status": "success",
        "message": (
            "Delivery confirmation QR generated."
        ),
        "order_id": order.id,
        "confirmation_url": confirmation_url,
        "expires_at": expires_at.isoformat(),
        "expires_in_minutes": QR_EXPIRY_MINUTES,
    }), 200


# =========================================================
# CHECK DELIVERY QR
# =========================================================

@delivery_confirmation_bp.get(
    "/delivery-confirmation/<token>"
)
def get_confirmation_details(token):

    token_hash = hash_token(token)

    challenge = db.session.execute(
        text("""
            SELECT
                id,
                order_id,
                delivery_person_id,
                customer_id,
                expires_at,
                confirmed_at
            FROM delivery_confirmation_challenges
            WHERE token_hash = :token_hash
        """),
        {
            "token_hash": token_hash,
        },
    ).mappings().first()

    # -----------------------------------------------------
    # Token does not exist.
    # -----------------------------------------------------

    if not challenge:
        return jsonify({
            "status": "error",
            "message": "Invalid delivery QR code.",
        }), 404

    # -----------------------------------------------------
    # Token already used.
    # -----------------------------------------------------

    if challenge["confirmed_at"] is not None:
        return jsonify({
            "status": "error",
            "message": (
                "This delivery QR code has already been used."
            ),
        }), 409

    # -----------------------------------------------------
    # Check expiration.
    # -----------------------------------------------------

    expires_at = challenge["expires_at"]

    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(
            tzinfo=timezone.utc
        )

    if expires_at <= utc_now():
        return jsonify({
            "status": "error",
            "message": (
                "This delivery QR code has expired."
            ),
        }), 410

    # -----------------------------------------------------
    # Find order.
    # -----------------------------------------------------

    order = db.session.get(
        Order,
        challenge["order_id"]
    )

    if not order:
        return jsonify({
            "status": "error",
            "message": "Order not found.",
        }), 404

    # -----------------------------------------------------
    # Order must still be out for delivery.
    # -----------------------------------------------------

    if order.status != "out_for_delivery":
        return jsonify({
            "status": "error",
            "message": (
                "This order is no longer available "
                "for delivery confirmation."
            ),
        }), 409

    # -----------------------------------------------------
    # Return safe order information.
    # -----------------------------------------------------

    return jsonify({
        "status": "success",
        "order_id": order.id,
        "total_amount": float(
            order.total_amount
        ),
        "payment_method": order.payment_method,
        "payment_status": order.payment_status,
        "order_status": order.status,
        "expires_at": expires_at.isoformat(),
    }), 200


# =========================================================
# CONFIRM DELIVERY
# =========================================================
#
# Customer login is NOT required.
#
# The valid QR token itself is the temporary
# authorization.
#
# QR protection:
#
# 1. Random cryptographic token
# 2. Token stored only as SHA-256 hash
# 3. Expires after 10 minutes
# 4. Can only be used once
# 5. Connected to one specific order
# 6. Order must still be out_for_delivery
#
# =========================================================

@delivery_confirmation_bp.post(
    "/delivery-confirmation/<token>/confirm"
)
def confirm_delivery(token):

    token_hash = hash_token(token)

    try:

        # -------------------------------------------------
        # Lock the QR record.
        #
        # This prevents two simultaneous requests from
        # confirming the same QR code.
        # -------------------------------------------------

        challenge = db.session.execute(
            text("""
                SELECT
                    id,
                    order_id,
                    delivery_person_id,
                    customer_id,
                    expires_at,
                    confirmed_at
                FROM delivery_confirmation_challenges
                WHERE token_hash = :token_hash
                FOR UPDATE
            """),
            {
                "token_hash": token_hash,
            },
        ).mappings().first()

        # -------------------------------------------------
        # Invalid token.
        # -------------------------------------------------

        if not challenge:
            return jsonify({
                "status": "error",
                "message": (
                    "Invalid delivery QR code."
                ),
            }), 404

        # -------------------------------------------------
        # Already confirmed.
        # -------------------------------------------------

        if challenge["confirmed_at"] is not None:
            return jsonify({
                "status": "error",
                "message": (
                    "This delivery has already been confirmed."
                ),
            }), 409

        # -------------------------------------------------
        # Check expiration.
        # -------------------------------------------------

        expires_at = challenge["expires_at"]

        if expires_at.tzinfo is None:
            expires_at = expires_at.replace(
                tzinfo=timezone.utc
            )

        if expires_at <= utc_now():
            return jsonify({
                "status": "error",
                "message": (
                    "This delivery QR code has expired."
                ),
            }), 410

        # -------------------------------------------------
        # Find order.
        # -------------------------------------------------

        order = db.session.get(
            Order,
            challenge["order_id"]
        )

        if not order:
            return jsonify({
                "status": "error",
                "message": "Order not found.",
            }), 404

        # -------------------------------------------------
        # Order must still be out for delivery.
        # -------------------------------------------------

        if order.status != "out_for_delivery":
            return jsonify({
                "status": "error",
                "message": (
                    "This order is no longer "
                    "out for delivery."
                ),
            }), 409

        # -------------------------------------------------
        # Confirm delivery.
        # -------------------------------------------------

        order.status = "delivered"

        # -------------------------------------------------
        # COD becomes paid after confirmation.
        # -------------------------------------------------

        if (
            str(order.payment_method).lower()
            == "cod"
        ):
            order.payment_status = "paid"

        # -------------------------------------------------
        # Permanently mark QR as used.
        # -------------------------------------------------

        db.session.execute(
            text("""
                UPDATE delivery_confirmation_challenges
                SET confirmed_at = :confirmed_at
                WHERE id = :challenge_id
            """),
            {
                "confirmed_at": utc_now(),
                "challenge_id": challenge["id"],
            },
        )

        # -------------------------------------------------
        # Save everything together.
        # -------------------------------------------------

        db.session.commit()

        return jsonify({
            "status": "success",
            "message": (
                "Delivery confirmed successfully."
            ),
            "order_id": order.id,
            "order_status": order.status,
            "payment_status": order.payment_status,
        }), 200

    except Exception as error:

        db.session.rollback()

        print(
            "Delivery confirmation error:",
            error,
        )

        return jsonify({
            "status": "error",
            "message": (
                "Unable to confirm delivery."
            ),
        }), 500