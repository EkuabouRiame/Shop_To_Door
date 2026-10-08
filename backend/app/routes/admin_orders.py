from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity

from ..extensions import db
from ..models import Order


# =========================================================
# BLUEPRINT
# =========================================================

admin_orders_bp = Blueprint(
    "admin_orders",
    __name__,
    url_prefix="/api/admin/orders"
)


# =========================================================
# ALLOWED ORDER STATUSES
# =========================================================

ALLOWED_ORDER_STATUSES = {
    "pending",
    "confirmed",
    "packed",
    "shipped",
    "out_for_delivery",
    "delivered",
    "cancelled"
}


# =========================================================
# ORDER STATUS FLOW
# =========================================================

ORDER_STATUS_FLOW = [
    "pending",
    "packed",
    "shipped",
    "out_for_delivery",
    "delivered"
]


# =========================================================
# ALLOWED PAYMENT STATUSES
# =========================================================

ALLOWED_PAYMENT_STATUSES = {
    "pending",
    "paid",
    "failed",
    "refunded"
}


# =========================================================
# GET CURRENT USER ID
# =========================================================

def get_current_user_id():

    identity = get_jwt_identity()

    try:
        return int(identity)

    except (TypeError, ValueError):
        return None


# =========================================================
# ORDER TO DICT
# =========================================================

def order_to_dict(order):

    return {
        "id": order.id,

        "user_id": order.user_id,

        "status": order.status,

        "payment_status": order.payment_status,

        "payment_method": order.payment_method,

        "subtotal": float(
            order.subtotal or 0
        ),

        "shipping_fee": float(
            order.shipping_fee or 0
        ),

        "discount": float(
            order.discount or 0
        ),

        "total_amount": float(
            order.total_amount or 0
        ),

        "shipping": {
            "name": order.shipping_name,

            "phone": order.shipping_phone,

            "address": order.shipping_address,

            "city": order.shipping_city,

            "state": order.shipping_state,

            "pincode": order.shipping_pincode
        },

        "notes": order.notes,

        "items": [
            {
                "id": item.id,

                "product_id": item.product_id,

                "product_name": item.product_name,

                "product_sku": item.product_sku,

                "quantity": item.quantity,

                "unit_price": float(
                    item.unit_price or 0
                ),

                "total_price": float(
                    item.total_price or 0
                ),

                "created_at": (
                    item.created_at.isoformat()
                    if item.created_at
                    else None
                )
            }

            for item in order.items
        ],

        "created_at": (
            order.created_at.isoformat()
            if order.created_at
            else None
        ),

        "updated_at": (
            order.updated_at.isoformat()
            if order.updated_at
            else None
        )
    }


# =========================================================
# GET ALL ORDERS
# =========================================================

@admin_orders_bp.get("/")
@jwt_required()
def get_all_orders():

    user_id = get_current_user_id()

    if user_id is None:

        return jsonify({
            "status": "error",
            "message": "Invalid authentication token"
        }), 401

    orders = (
        db.session
        .query(Order)
        .order_by(
            Order.created_at.desc()
        )
        .all()
    )

    return jsonify({
        "status": "success",

        "count": len(orders),

        "orders": [
            order_to_dict(order)
            for order in orders
        ]
    }), 200


# =========================================================
# GET SINGLE ORDER
# =========================================================

@admin_orders_bp.get("/<int:order_id>")
@jwt_required()
def get_single_order(order_id):

    order = (
        db.session
        .query(Order)
        .filter(
            Order.id == order_id
        )
        .first()
    )

    if not order:

        return jsonify({
            "status": "error",
            "message": "Order not found"
        }), 404

    return jsonify({
        "status": "success",

        "order": order_to_dict(order)
    }), 200


# =========================================================
# UPDATE ORDER STATUS
# =========================================================

@admin_orders_bp.put(
    "/<int:order_id>/status"
)
@jwt_required()
def update_order_status(order_id):

    # -----------------------------------------------------
    # READ REQUEST DATA
    # -----------------------------------------------------

    data = request.get_json(
        silent=True
    ) or {}

    status = data.get(
        "status"
    )

    # -----------------------------------------------------
    # CHECK STATUS
    # -----------------------------------------------------

    if not status:

        return jsonify({
            "status": "error",
            "message": "status is required",

            "allowed_statuses":
                ORDER_STATUS_FLOW + [
                    "cancelled"
                ]
        }), 400

    # -----------------------------------------------------
    # NORMALIZE STATUS
    # -----------------------------------------------------

    status = (
        str(status)
        .strip()
        .lower()
        .replace("-", "_")
        .replace(" ", "_")
    )

    # -----------------------------------------------------
    # CHECK ALLOWED STATUS
    # -----------------------------------------------------

    if status not in ALLOWED_ORDER_STATUSES:

        return jsonify({
            "status": "error",

            "message":
                "Invalid order status",

            "allowed_statuses":
                ORDER_STATUS_FLOW + [
                    "cancelled"
                ]
        }), 400

    # -----------------------------------------------------
    # FIND ORDER
    # -----------------------------------------------------

    order = (
        db.session
        .query(Order)
        .filter(
            Order.id == order_id
        )
        .first()
    )

    if not order:

        return jsonify({
            "status": "error",
            "message": "Order not found"
        }), 404

    # -----------------------------------------------------
    # CURRENT STATUS
    # -----------------------------------------------------

    old_status = (
        str(order.status)
        .strip()
        .lower()
        .replace("-", "_")
        .replace(" ", "_")
        if order.status
        else "pending"
    )

    # -----------------------------------------------------
    # CANCELLED ORDER
    # -----------------------------------------------------

    if status == "cancelled":

        if old_status == "delivered":

            return jsonify({
                "status": "error",

                "message":
                    "Delivered orders cannot be cancelled"
            }), 400

        if old_status == "cancelled":

            return jsonify({
                "status": "error",

                "message":
                    "Order is already cancelled"
            }), 400

        order.status = "cancelled"

    # -----------------------------------------------------
    # NORMAL STATUS FLOW
    # -----------------------------------------------------

    else:

        # -------------------------------------------------
        # CANCELLED → ACTIVE NOT ALLOWED
        # -------------------------------------------------

        if old_status == "cancelled":

            return jsonify({
                "status": "error",

                "message":
                    "Cancelled orders cannot be moved back to active status"
            }), 400

        # -------------------------------------------------
        # UNKNOWN OLD STATUS
        # -------------------------------------------------

        if old_status not in ORDER_STATUS_FLOW:

            old_status = "pending"

        # -------------------------------------------------
        # GET STATUS INDEX
        # -------------------------------------------------

        old_index = (
            ORDER_STATUS_FLOW.index(
                old_status
            )
        )

        new_index = (
            ORDER_STATUS_FLOW.index(
                status
            )
        )

        # -------------------------------------------------
        # PREVENT MOVING BACKWARD
        # -------------------------------------------------

        if new_index < old_index:

            return jsonify({
                "status": "error",

                "message": (
                    "Order cannot move backward "
                    f"from {old_status} "
                    f"to {status}"
                ),

                "current_status":
                    old_status,

                "requested_status":
                    status
            }), 400

        # -------------------------------------------------
        # UPDATE STATUS
        # -------------------------------------------------

        order.status = status

    # =====================================================
    # SAVE DATABASE
    # =====================================================

    try:

        db.session.commit()

    except Exception as error:

        db.session.rollback()

        print(
            "Order status update error:",
            error
        )

        return jsonify({
            "status": "error",

            "message":
                "Unable to update order status"
        }), 500

    # =====================================================
    # RESPONSE
    # =====================================================

    return jsonify({

        "status": "success",

        "message":
            "Order status updated successfully",

        "old_status":
            old_status,

        "new_status":
            order.status,

        "order":
            order_to_dict(order)

    }), 200


# =========================================================
# UPDATE PAYMENT STATUS
# =========================================================

@admin_orders_bp.put(
    "/<int:order_id>/payment-status"
)
@jwt_required()
def update_payment_status(order_id):

    # -----------------------------------------------------
    # READ REQUEST DATA
    # -----------------------------------------------------

    data = request.get_json(
        silent=True
    ) or {}

    payment_status = data.get(
        "payment_status"
    )

    # -----------------------------------------------------
    # CHECK PAYMENT STATUS
    # -----------------------------------------------------

    if not payment_status:

        return jsonify({
            "status": "error",

            "message":
                "payment_status is required",

            "allowed_payment_statuses":
                sorted(
                    ALLOWED_PAYMENT_STATUSES
                )
        }), 400

    # -----------------------------------------------------
    # NORMALIZE PAYMENT STATUS
    # -----------------------------------------------------

    payment_status = (
        str(payment_status)
        .strip()
        .lower()
    )

    # -----------------------------------------------------
    # CHECK ALLOWED PAYMENT STATUS
    # -----------------------------------------------------

    if (
        payment_status
        not in ALLOWED_PAYMENT_STATUSES
    ):

        return jsonify({
            "status": "error",

            "message":
                "Invalid payment status",

            "allowed_payment_statuses":
                sorted(
                    ALLOWED_PAYMENT_STATUSES
                )
        }), 400

    # -----------------------------------------------------
    # FIND ORDER
    # -----------------------------------------------------

    order = (
        db.session
        .query(Order)
        .filter(
            Order.id == order_id
        )
        .first()
    )

    if not order:

        return jsonify({
            "status": "error",

            "message":
                "Order not found"
        }), 404

    # -----------------------------------------------------
    # UPDATE PAYMENT STATUS
    # -----------------------------------------------------

    order.payment_status = (
        payment_status
    )

    # -----------------------------------------------------
    # SAVE DATABASE
    # -----------------------------------------------------

    try:

        db.session.commit()

    except Exception as error:

        db.session.rollback()

        print(
            "Payment status update error:",
            error
        )

        return jsonify({
            "status": "error",

            "message":
                "Unable to update payment status"
        }), 500

    # -----------------------------------------------------
    # RESPONSE
    # -----------------------------------------------------

    return jsonify({

        "status": "success",

        "message":
            "Payment status updated successfully",

        "payment_status":
            order.payment_status,

        "order":
            order_to_dict(order)

    }), 200