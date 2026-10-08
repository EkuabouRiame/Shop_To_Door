from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity

from app.extensions import db
from app.models import Order
from app.services.razorpay_service import get_razorpay_client

import razorpay


payments_bp = Blueprint(
    "payments",
    __name__,
    url_prefix="/api/payments"
)


# =========================================================
# CREATE RAZORPAY ORDER
# =========================================================

@payments_bp.post("/create/<int:order_id>")
@jwt_required()
def create_razorpay_order(order_id):
    user_id = get_jwt_identity()

    # Find the order belonging to the logged-in user
    order = Order.query.filter_by(
        id=order_id,
        user_id=user_id
    ).first()

    if not order:
        return jsonify({
            "success": False,
            "message": "Order not found."
        }), 404

    # Only Razorpay/online orders are allowed
    if order.payment_method not in {"razorpay", "online"}:
        return jsonify({
            "success": False,
            "message": "This order is not an online payment order."
        }), 400

    # Don't create another payment order for an already-paid order
    if order.payment_status == "paid":
        return jsonify({
            "success": False,
            "message": "Order is already paid."
        }), 400

    try:
        client = get_razorpay_client()

        # Convert INR to paise
        amount_paise = int(
            round(float(order.total_amount) * 100)
        )

        if amount_paise <= 0:
            return jsonify({
                "success": False,
                "message": "Invalid order amount."
            }), 400

        # Create Razorpay order
        razorpay_order = client.order.create({
            "amount": amount_paise,
            "currency": "INR",
            "receipt": f"order_{order.id}",
            "notes": {
                "internal_order_id": str(order.id)
            }
        })

        # Save Razorpay Order ID
        order.razorpay_order_id = razorpay_order["id"]

        db.session.commit()

        return jsonify({
            "success": True,
            "order_id": order.id,
            "razorpay_order_id": razorpay_order["id"],
            "amount": amount_paise,
            "currency": "INR",
            "key_id": client.auth[0]
        }), 200

    except Exception as e:
        db.session.rollback()

        print("Razorpay order creation error:", str(e))

        return jsonify({
            "success": False,
            "message": "Unable to create Razorpay order."
        }), 500


# =========================================================
# VERIFY RAZORPAY PAYMENT
# =========================================================

@payments_bp.post("/verify")
@jwt_required()
def verify_razorpay_payment():
    user_id = get_jwt_identity()

    data = request.get_json() or {}

    order_id = data.get("order_id")
    razorpay_order_id = data.get("razorpay_order_id")
    razorpay_payment_id = data.get("razorpay_payment_id")
    razorpay_signature = data.get("razorpay_signature")

    # -----------------------------------------------------
    # Validate request
    # -----------------------------------------------------

    if not all([
        order_id,
        razorpay_order_id,
        razorpay_payment_id,
        razorpay_signature
    ]):
        return jsonify({
            "success": False,
            "message": "Missing payment verification details."
        }), 400

    # -----------------------------------------------------
    # Find user's order
    # -----------------------------------------------------

    order = Order.query.filter_by(
        id=order_id,
        user_id=user_id
    ).first()

    if not order:
        return jsonify({
            "success": False,
            "message": "Order not found."
        }), 404

    # -----------------------------------------------------
    # Make sure Razorpay order matches our order
    # -----------------------------------------------------

    if order.razorpay_order_id != razorpay_order_id:
        return jsonify({
            "success": False,
            "message": "Razorpay order mismatch."
        }), 400

    # -----------------------------------------------------
    # Prevent duplicate verification
    # -----------------------------------------------------

    if order.payment_status == "paid":
        return jsonify({
            "success": True,
            "message": "Payment has already been verified.",
            "order_id": order.id,
            "payment_status": "paid"
        }), 200

    # -----------------------------------------------------
    # Verify Razorpay signature
    # -----------------------------------------------------

    try:
        client = get_razorpay_client()

        client.utility.verify_payment_signature({
            "razorpay_order_id": razorpay_order_id,
            "razorpay_payment_id": razorpay_payment_id,
            "razorpay_signature": razorpay_signature
        })

    except razorpay.errors.SignatureVerificationError:
        return jsonify({
            "success": False,
            "message": "Payment signature verification failed."
        }), 400

    except Exception as e:
        print("Razorpay verification error:", str(e))

        return jsonify({
            "success": False,
            "message": "Unable to verify payment."
        }), 500

    # -----------------------------------------------------
    # Payment successfully verified
    # -----------------------------------------------------

    try:
        order.razorpay_payment_id = razorpay_payment_id
        order.razorpay_signature = razorpay_signature
        order.payment_status = "paid"

        db.session.commit()

        return jsonify({
            "success": True,
            "message": "Payment verified successfully.",
            "order_id": order.id,
            "payment_status": "paid"
        }), 200

    except Exception as e:
        db.session.rollback()

        print("Database payment update error:", str(e))

        return jsonify({
            "success": False,
            "message": "Payment was verified but could not be saved."
        }), 500