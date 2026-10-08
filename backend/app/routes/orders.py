from decimal import Decimal

from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity

from ..extensions import db
from ..models import (
    User,
    Order,
    OrderItem,
    Product,
    Cart,
    CartItem,
)


orders_bp = Blueprint(
    "orders",
    __name__,
    url_prefix="/api/orders",
)


# =========================================================
# CONSTANTS
# =========================================================

CUSTOMER_ROLE = "customer"
ADMIN_ROLE = "admin"
DELIVERY_ROLE = "delivery_person"


ORDER_STATUSES = {
    "pending",
    "assigned",
    "packed",
    "shipped",
    "picked_up",
    "out_for_delivery",
    "delivered",
    "delivery_failed",
    "cancelled",
}


DELIVERY_STATUSES = {
    "assigned",
    "picked_up",
    "out_for_delivery",
    "delivered",
    "delivery_failed",
}


PAYMENT_METHODS = {
    "cod",
    "razorpay",
    "online",
}


# =========================================================
# DELIVERY CHARGE
# =========================================================
#
# FREE DELIVERY:
#     subtotal >= ₹2,000
#
# DELIVERY CHARGE:
#     subtotal < ₹2,000
#
# =========================================================

FREE_DELIVERY_THRESHOLD = Decimal("2000.00")
DELIVERY_CHARGE = Decimal("69.00")


# =========================================================
# AUTHENTICATION HELPERS
# =========================================================

def get_current_user_id():
    """
    Get authenticated user ID from JWT.
    """

    identity = get_jwt_identity()

    try:
        return int(identity)
    except (TypeError, ValueError):
        return None


def get_current_user():
    """
    Get currently authenticated user.
    """

    user_id = get_current_user_id()

    if user_id is None:
        return None

    return (
        db.session.query(User)
        .filter(User.id == user_id)
        .first()
    )


def get_user_role(user):
    """
    Return normalized user role.
    """

    if not user:
        return None

    return str(
        user.role or CUSTOMER_ROLE
    ).strip().lower()


def is_admin(user):
    return get_user_role(user) == ADMIN_ROLE


def is_delivery_person(user):
    return get_user_role(user) == DELIVERY_ROLE


def is_customer(user):
    return get_user_role(user) == CUSTOMER_ROLE


def active_user_required():
    """
    Return current active user or None.
    """

    user = get_current_user()

    if not user:
        return None

    if not user.is_active:
        return None

    return user


# =========================================================
# SERIALIZATION HELPERS
# =========================================================

def user_to_delivery_dict(user):
    """
    Convert a delivery person into a safe JSON dictionary.

    Password fields are intentionally never returned.
    """

    if not user:
        return None

    return {
        "id": user.id,
        "name": user.name,
        "email": user.email,
        "phone": user.phone,
        "address": user.address,
        "city": user.city,
        "state": user.state,
        "pincode": user.pincode,
        "is_active": bool(user.is_active),
    }


def order_item_to_dict(item):
    """
    Convert OrderItem to JSON-safe dictionary.
    """

    return {
        "id": item.id,
        "product_id": item.product_id,
        "product_name": item.product_name,
        "product_sku": item.product_sku,
        "quantity": item.quantity,
        "unit_price": (
            float(item.unit_price)
            if item.unit_price is not None
            else 0
        ),
        "total_price": (
            float(item.total_price)
            if item.total_price is not None
            else 0
        ),
        "created_at": (
            item.created_at.isoformat()
            if item.created_at
            else None
        ),
    }


def order_to_dict(order):
    """
    Convert Order to JSON-safe dictionary.
    """

    delivery_person = None

    if order.delivery_person:
        delivery_person = user_to_delivery_dict(
            order.delivery_person
        )

    return {
        "id": order.id,

        "user_id": order.user_id,

        # -------------------------------------------------
        # ORDER STATUS
        # -------------------------------------------------

        "status": order.status,

        # -------------------------------------------------
        # PAYMENT
        # -------------------------------------------------

        "payment_status": order.payment_status,
        "payment_method": order.payment_method,

        # -------------------------------------------------
        # AMOUNTS
        # -------------------------------------------------

        "subtotal": (
            float(order.subtotal)
            if order.subtotal is not None
            else 0
        ),

        "shipping_fee": (
            float(order.shipping_fee)
            if order.shipping_fee is not None
            else 0
        ),

        "discount": (
            float(order.discount)
            if order.discount is not None
            else 0
        ),

        "total_amount": (
            float(order.total_amount)
            if order.total_amount is not None
            else 0
        ),

        # -------------------------------------------------
        # CUSTOMER SHIPPING INFORMATION
        # -------------------------------------------------

        "shipping": {
            "name": order.shipping_name,
            "phone": order.shipping_phone,
            "address": order.shipping_address,
            "city": order.shipping_city,
            "state": order.shipping_state,
            "pincode": order.shipping_pincode,
        },

        # -------------------------------------------------
        # DELIVERY PERSON
        # -------------------------------------------------

        "delivery_person_id": order.delivery_person_id,

        "delivery_person": delivery_person,

        # -------------------------------------------------
        # OTHER
        # -------------------------------------------------

        "notes": order.notes,

        "items": [
            order_item_to_dict(item)
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
        ),
    }


# =========================================================
# CUSTOMER / ADMIN / DELIVERY
# GET ORDERS
# =========================================================

@orders_bp.get("/")
@jwt_required()
def get_orders():

    user = get_current_user()

    if not user:
        return jsonify({
            "status": "error",
            "message": "User not found",
        }), 404

    if not user.is_active:
        return jsonify({
            "status": "error",
            "message": "Your account is inactive.",
        }), 403

    role = get_user_role(user)

    # -----------------------------------------------------
    # ADMIN
    # -----------------------------------------------------

    if role == ADMIN_ROLE:

        orders = (
            db.session.query(Order)
            .order_by(
                Order.created_at.desc()
            )
            .all()
        )

    # -----------------------------------------------------
    # DELIVERY PERSON
    # -----------------------------------------------------

    elif role == DELIVERY_ROLE:

        orders = (
            db.session.query(Order)
            .filter(
                Order.delivery_person_id == user.id
            )
            .order_by(
                Order.created_at.desc()
            )
            .all()
        )

    # -----------------------------------------------------
    # CUSTOMER
    # -----------------------------------------------------

    else:

        orders = (
            db.session.query(Order)
            .filter(
                Order.user_id == user.id
            )
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
        ],
    }), 200


# =========================================================
# GET SINGLE ORDER
# =========================================================

@orders_bp.get("/<int:order_id>")
@jwt_required()
def get_order(order_id):

    user = get_current_user()

    if not user:
        return jsonify({
            "status": "error",
            "message": "User not found",
        }), 404

    if not user.is_active:
        return jsonify({
            "status": "error",
            "message": "Your account is inactive.",
        }), 403

    role = get_user_role(user)

    # -----------------------------------------------------
    # ADMIN
    # -----------------------------------------------------

    if role == ADMIN_ROLE:

        order = (
            db.session.query(Order)
            .filter(
                Order.id == order_id
            )
            .first()
        )

    # -----------------------------------------------------
    # DELIVERY PERSON
    # -----------------------------------------------------

    elif role == DELIVERY_ROLE:

        order = (
            db.session.query(Order)
            .filter(
                Order.id == order_id,
                Order.delivery_person_id == user.id,
            )
            .first()
        )

    # -----------------------------------------------------
    # CUSTOMER
    # -----------------------------------------------------

    else:

        order = (
            db.session.query(Order)
            .filter(
                Order.id == order_id,
                Order.user_id == user.id,
            )
            .first()
        )

    if not order:
        return jsonify({
            "status": "error",
            "message": "Order not found",
        }), 404

    return jsonify({
        "status": "success",
        "order": order_to_dict(order),
    }), 200


# =========================================================
# CREATE ORDER
# CUSTOMER ONLY
# =========================================================

@orders_bp.post("/")
@jwt_required()
def create_order():

    user = get_current_user()

    if not user:
        return jsonify({
            "status": "error",
            "message": "User not found",
        }), 404

    if not user.is_active:
        return jsonify({
            "status": "error",
            "message": "Your account is inactive.",
        }), 403

    if not is_customer(user):
        return jsonify({
            "status": "error",
            "message": (
                "Only customer accounts can place orders."
            ),
        }), 403

    # -----------------------------------------------------
    # REQUEST DATA
    # -----------------------------------------------------

    data = request.get_json(
        silent=True
    ) or {}

    # -----------------------------------------------------
    # PAYMENT METHOD
    # -----------------------------------------------------

    payment_method = str(
        data.get(
            "payment_method",
            "cod",
        )
    ).strip().lower()

    if payment_method not in PAYMENT_METHODS:
        return jsonify({
            "status": "error",
            "message": (
                "Invalid payment_method. "
                "Allowed values: cod, razorpay, online"
            ),
        }), 400

    # -----------------------------------------------------
    # SHIPPING INFORMATION
    # -----------------------------------------------------

    shipping_name = str(
        data.get(
            "shipping_name",
            "",
        )
    ).strip()

    shipping_phone = str(
        data.get(
            "shipping_phone",
            "",
        )
    ).strip()

    shipping_address = str(
        data.get(
            "shipping_address",
            "",
        )
    ).strip()

    shipping_city = str(
        data.get(
            "shipping_city",
            "",
        )
    ).strip()

    shipping_state = str(
        data.get(
            "shipping_state",
            "",
        )
    ).strip()

    shipping_pincode = str(
        data.get(
            "shipping_pincode",
            "",
        )
    ).strip()

    notes = data.get("notes")

    if notes is not None:
        notes = str(notes).strip()

    required_fields = {
        "shipping_name": shipping_name,
        "shipping_phone": shipping_phone,
        "shipping_address": shipping_address,
        "shipping_city": shipping_city,
        "shipping_state": shipping_state,
        "shipping_pincode": shipping_pincode,
    }

    missing_fields = [
        field
        for field, value in required_fields.items()
        if not value
    ]

    if missing_fields:
        return jsonify({
            "status": "error",
            "message": (
                "Required shipping fields are missing"
            ),
            "missing_fields": missing_fields,
        }), 400

    # -----------------------------------------------------
    # CART
    # -----------------------------------------------------

    cart = (
        db.session.query(Cart)
        .filter(
            Cart.user_id == user.id
        )
        .first()
    )

    if not cart:
        return jsonify({
            "status": "error",
            "message": "Cart not found",
        }), 404

    cart_items = (
        db.session.query(CartItem)
        .filter(
            CartItem.cart_id == cart.id
        )
        .all()
    )

    if not cart_items:
        return jsonify({
            "status": "error",
            "message": "Your cart is empty",
        }), 400

    # -----------------------------------------------------
    # VALIDATE CART
    # -----------------------------------------------------

    subtotal = Decimal("0.00")

    validated_items = []

    for cart_item in cart_items:

        product = (
            db.session.query(Product)
            .filter(
                Product.id == cart_item.product_id
            )
            .first()
        )

        if not product:
            return jsonify({
                "status": "error",
                "message": (
                    f"Product {cart_item.product_id} "
                    "was not found"
                ),
            }), 400

        # -------------------------------------------------
        # ACTIVE PRODUCT
        # -------------------------------------------------

        if not product.is_active:
            return jsonify({
                "status": "error",
                "message": (
                    f"Product '{product.name}' "
                    "is no longer available"
                ),
            }), 400

        # -------------------------------------------------
        # STOCK
        # -------------------------------------------------

        if product.stock < cart_item.quantity:
            return jsonify({
                "status": "error",
                "message": (
                    f"Only {product.stock} item(s) "
                    f"of '{product.name}' "
                    "are available in stock"
                ),
            }), 400

        # -------------------------------------------------
        # PRICE
        # -------------------------------------------------

        if product.discount_price is not None:

            unit_price = Decimal(
                str(product.discount_price)
            )

        else:

            unit_price = Decimal(
                str(product.price)
            )

        item_total = (
            unit_price *
            cart_item.quantity
        )

        subtotal += item_total

        validated_items.append({
            "cart_item": cart_item,
            "product": product,
            "unit_price": unit_price,
            "total_price": item_total,
        })

    # -----------------------------------------------------
    # DELIVERY CHARGE
    # -----------------------------------------------------
    #
    # FREE DELIVERY:
    #     subtotal >= ₹2,000
    #
    # DELIVERY CHARGE:
    #     subtotal < ₹2,000
    #
    # -----------------------------------------------------

    if subtotal >= FREE_DELIVERY_THRESHOLD:
        shipping_fee = Decimal("0.00")
    else:
        shipping_fee = DELIVERY_CHARGE

    # -----------------------------------------------------
    # DISCOUNT
    # -----------------------------------------------------

    discount = Decimal("0.00")

    # -----------------------------------------------------
    # TOTAL
    # -----------------------------------------------------

    total_amount = (
        subtotal
        + shipping_fee
        - discount
    )

    if total_amount < 0:
        total_amount = Decimal("0.00")

    # -----------------------------------------------------
    # CREATE ORDER
    # -----------------------------------------------------

    order = Order(
        user_id=user.id,

        delivery_person_id=None,

        status="pending",

        payment_status="pending",

        payment_method=payment_method,

        subtotal=subtotal,

        shipping_fee=shipping_fee,

        discount=discount,

        total_amount=total_amount,

        shipping_name=shipping_name,

        shipping_phone=shipping_phone,

        shipping_address=shipping_address,

        shipping_city=shipping_city,

        shipping_state=shipping_state,

        shipping_pincode=shipping_pincode,

        notes=notes,
    )

    db.session.add(order)

    # Get order ID
    db.session.flush()

    # -----------------------------------------------------
    # CREATE ORDER ITEMS
    # -----------------------------------------------------

    for item_data in validated_items:

        cart_item = item_data["cart_item"]
        product = item_data["product"]

        unit_price = item_data["unit_price"]
        total_price = item_data["total_price"]

        order_item = OrderItem(
            order_id=order.id,

            product_id=product.id,

            product_name=product.name,

            product_sku=product.sku,

            quantity=cart_item.quantity,

            unit_price=unit_price,

            total_price=total_price,
        )

        db.session.add(order_item)

        # Reduce stock
        product.stock -= cart_item.quantity

    # -----------------------------------------------------
    # CLEAR CART
    # -----------------------------------------------------

    for cart_item in cart_items:
        db.session.delete(cart_item)

    # -----------------------------------------------------
    # COMMIT
    # -----------------------------------------------------

    try:

        db.session.commit()

    except Exception as error:

        db.session.rollback()

        return jsonify({
            "status": "error",
            "message": "Failed to create order",
            "error": str(error),
        }), 500

    # -----------------------------------------------------
    # RESPONSE
    # -----------------------------------------------------

    return jsonify({
        "status": "success",
        "message": "Order created successfully",
        "order": order_to_dict(order),
    }), 201


# =========================================================
# CANCEL ORDER
# CUSTOMER ONLY
# =========================================================

@orders_bp.post("/<int:order_id>/cancel")
@jwt_required()
def cancel_order(order_id):

    user = get_current_user()

    if not user:
        return jsonify({
            "status": "error",
            "message": "User not found",
        }), 404

    if not user.is_active:
        return jsonify({
            "status": "error",
            "message": "Your account is inactive.",
        }), 403

    if not is_customer(user):
        return jsonify({
            "status": "error",
            "message": (
                "Only customers can cancel their orders."
            ),
        }), 403

    # -----------------------------------------------------
    # FIND ORDER
    # -----------------------------------------------------

    order = (
        db.session.query(Order)
        .filter(
            Order.id == order_id,
            Order.user_id == user.id,
        )
        .first()
    )

    if not order:
        return jsonify({
            "status": "error",
            "message": "Order not found",
        }), 404

    # -----------------------------------------------------
    # STATUS CHECK
    # -----------------------------------------------------

    if order.status == "cancelled":
        return jsonify({
            "status": "error",
            "message": "Order is already cancelled",
        }), 400

    if order.status not in {
        "pending",
        "assigned",
    }:
        return jsonify({
            "status": "error",
            "message": (
                "This order cannot be cancelled "
                f"because its current status is "
                f"'{order.status}'"
            ),
        }), 400

    # -----------------------------------------------------
    # RESTORE STOCK
    # -----------------------------------------------------

    for item in order.items:

        product = (
            db.session.query(Product)
            .filter(
                Product.id == item.product_id
            )
            .first()
        )

        if product:
            product.stock += item.quantity

    # -----------------------------------------------------
    # UPDATE ORDER
    # -----------------------------------------------------

    order.status = "cancelled"

    # Remove delivery assignment
    order.delivery_person_id = None

    # -----------------------------------------------------
    # PAYMENT
    # -----------------------------------------------------

    if order.payment_status == "paid":
        order.payment_status = "refund_pending"

    # -----------------------------------------------------
    # SAVE
    # -----------------------------------------------------

    try:

        db.session.commit()

    except Exception as error:

        db.session.rollback()

        return jsonify({
            "status": "error",
            "message": "Failed to cancel order",
            "error": str(error),
        }), 500

    return jsonify({
        "status": "success",
        "message": "Order cancelled successfully",
        "order": order_to_dict(order),
    }), 200


# =========================================================
# ADMIN
# GET ALL DELIVERY PERSONS
#
# GET:
# /api/orders/admin/delivery-persons
# =========================================================

@orders_bp.get("/admin/delivery-persons")
@jwt_required()
def get_delivery_persons():

    user = get_current_user()

    if not user:
        return jsonify({
            "status": "error",
            "message": "User not found",
        }), 404

    if not user.is_active:
        return jsonify({
            "status": "error",
            "message": "Your account is inactive.",
        }), 403

    if not is_admin(user):
        return jsonify({
            "status": "error",
            "message": "Administrator access required.",
        }), 403

    delivery_persons = (
        db.session.query(User)
        .filter(
            User.role == DELIVERY_ROLE
        )
        .order_by(
            User.name.asc()
        )
        .all()
    )

    return jsonify({
        "status": "success",
        "count": len(delivery_persons),
        "delivery_persons": [
            user_to_delivery_dict(person)
            for person in delivery_persons
        ],
    }), 200


# =========================================================
# ADMIN
# ASSIGN DELIVERY PERSON
#
# POST:
# /api/orders/admin/<order_id>/assign
#
# BODY:
# {
#     "delivery_person_id": 5
# }
# =========================================================

@orders_bp.post("/admin/<int:order_id>/assign")
@jwt_required()
def assign_delivery_person(order_id):

    user = get_current_user()

    if not user:
        return jsonify({
            "status": "error",
            "message": "User not found",
        }), 404

    if not user.is_active:
        return jsonify({
            "status": "error",
            "message": "Your account is inactive.",
        }), 403

    if not is_admin(user):
        return jsonify({
            "status": "error",
            "message": "Administrator access required.",
        }), 403

    # -----------------------------------------------------
    # REQUEST DATA
    # -----------------------------------------------------

    data = request.get_json(
        silent=True
    ) or {}

    delivery_person_id = data.get(
        "delivery_person_id"
    )

    if delivery_person_id in (
        None,
        "",
        "null",
    ):
        return jsonify({
            "status": "error",
            "message": (
                "delivery_person_id is required"
            ),
        }), 400

    try:

        delivery_person_id = int(
            delivery_person_id
        )

    except (TypeError, ValueError):

        return jsonify({
            "status": "error",
            "message": (
                "delivery_person_id must be "
                "a valid integer"
            ),
        }), 400

    # -----------------------------------------------------
    # FIND ORDER
    # -----------------------------------------------------

    order = (
        db.session.query(Order)
        .filter(
            Order.id == order_id
        )
        .first()
    )

    if not order:
        return jsonify({
            "status": "error",
            "message": "Order not found",
        }), 404

    # -----------------------------------------------------
    # DO NOT ASSIGN CANCELLED/DELIVERED ORDER
    # -----------------------------------------------------

    if order.status in {
        "cancelled",
        "delivered",
    }:
        return jsonify({
            "status": "error",
            "message": (
                "This order cannot be assigned "
                f"because its status is "
                f"'{order.status}'."
            ),
        }), 400

    # -----------------------------------------------------
    # FIND DELIVERY PERSON
    # -----------------------------------------------------

    delivery_person = (
        db.session.query(User)
        .filter(
            User.id == delivery_person_id,
            User.role == DELIVERY_ROLE,
        )
        .first()
    )

    if not delivery_person:
        return jsonify({
            "status": "error",
            "message": (
                "Delivery person not found"
            ),
        }), 404

    if not delivery_person.is_active:
        return jsonify({
            "status": "error",
            "message": (
                "This delivery person's "
                "account is inactive."
            ),
        }), 400

    # -----------------------------------------------------
    # ASSIGN
    # -----------------------------------------------------

    order.delivery_person_id = (
        delivery_person.id
    )

    if order.status == "pending":
        order.status = "assigned"

    # -----------------------------------------------------
    # SAVE
    # -----------------------------------------------------

    try:

        db.session.commit()

    except Exception as error:

        db.session.rollback()

        return jsonify({
            "status": "error",
            "message": (
                "Failed to assign delivery person"
            ),
            "error": str(error),
        }), 500

    return jsonify({
        "status": "success",
        "message": (
            "Delivery person assigned successfully"
        ),
        "order": order_to_dict(order),
    }), 200


# =========================================================
# ADMIN
# UNASSIGN DELIVERY PERSON
#
# POST:
# /api/orders/admin/<order_id>/unassign
# =========================================================

@orders_bp.post("/admin/<int:order_id>/unassign")
@jwt_required()
def unassign_delivery_person(order_id):

    user = get_current_user()

    if not user:
        return jsonify({
            "status": "error",
            "message": "User not found",
        }), 404

    if not user.is_active:
        return jsonify({
            "status": "error",
            "message": "Your account is inactive.",
        }), 403

    if not is_admin(user):
        return jsonify({
            "status": "error",
            "message": "Administrator access required.",
        }), 403

    # -----------------------------------------------------
    # FIND ORDER
    # -----------------------------------------------------

    order = (
        db.session.query(Order)
        .filter(
            Order.id == order_id
        )
        .first()
    )

    if not order:
        return jsonify({
            "status": "error",
            "message": "Order not found",
        }), 404

    # -----------------------------------------------------
    # CANNOT UNASSIGN DELIVERED ORDER
    # -----------------------------------------------------

    if order.status == "delivered":
        return jsonify({
            "status": "error",
            "message": (
                "A delivered order cannot be unassigned."
            ),
        }), 400

    order.delivery_person_id = None

    if order.status == "assigned":
        order.status = "pending"

    try:

        db.session.commit()

    except Exception as error:

        db.session.rollback()

        return jsonify({
            "status": "error",
            "message": (
                "Failed to unassign delivery person"
            ),
            "error": str(error),
        }), 500

    return jsonify({
        "status": "success",
        "message": (
            "Delivery person removed successfully"
        ),
        "order": order_to_dict(order),
    }), 200


# =========================================================
# DELIVERY PERSON
# GET MY ASSIGNED ORDERS
#
# GET:
# /api/orders/delivery/my-orders
# =========================================================

@orders_bp.get("/delivery/my-orders")
@jwt_required()
def delivery_my_orders():

    user = get_current_user()

    if not user:
        return jsonify({
            "status": "error",
            "message": "User not found",
        }), 404

    if not user.is_active:
        return jsonify({
            "status": "error",
            "message": "Your account is inactive.",
        }), 403

    if not is_delivery_person(user):
        return jsonify({
            "status": "error",
            "message": (
                "Delivery person access required."
            ),
        }), 403

    orders = (
        db.session.query(Order)
        .filter(
            Order.delivery_person_id == user.id
        )
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
        ],
    }), 200


# =========================================================
# DELIVERY PERSON
# UPDATE DELIVERY STATUS
#
# POST:
# /api/orders/delivery/<order_id>/status
#
# BODY:
# {
#     "status": "out_for_delivery"
# }
#
# IMPORTANT:
# The delivery person CANNOT directly set:
#
#     status = "delivered"
#
# Delivery completion must happen through the
# customer QR confirmation system.
# =========================================================

@orders_bp.post(
    "/delivery/<int:order_id>/status"
)
@jwt_required()
def update_delivery_status(order_id):

    user = get_current_user()

    if not user:
        return jsonify({
            "status": "error",
            "message": "User not found",
        }), 404

    if not user.is_active:
        return jsonify({
            "status": "error",
            "message": "Your account is inactive.",
        }), 403

    if not is_delivery_person(user):
        return jsonify({
            "status": "error",
            "message": (
                "Delivery person access required."
            ),
        }), 403

    # -----------------------------------------------------
    # REQUEST DATA
    # -----------------------------------------------------

    data = request.get_json(
        silent=True
    ) or {}

    new_status = str(
        data.get(
            "status",
            "",
        )
    ).strip().lower()

    if new_status not in DELIVERY_STATUSES:
        return jsonify({
            "status": "error",
            "message": (
                "Invalid delivery status. "
                "Allowed values: "
                "assigned, picked_up, "
                "out_for_delivery, delivered, "
                "delivery_failed"
            ),
        }), 400

    # =====================================================
    # STEP 1 QR SECURITY
    # =====================================================
    #
    # The delivery person is NOT allowed to directly
    # mark an order as delivered.
    #
    # The customer must confirm delivery through the
    # QR confirmation system.
    #
    # The QR confirmation endpoint is the only endpoint
    # allowed to set:
    #
    #     order.status = "delivered"
    #
    # =====================================================

    if new_status == "delivered":
        return jsonify({
            "status": "error",
            "message": (
                "Delivery must be confirmed by the "
                "customer using the delivery QR code."
            ),
            "qr_confirmation_required": True,
        }), 400

    # -----------------------------------------------------
    # FIND ASSIGNED ORDER
    # -----------------------------------------------------

    order = (
        db.session.query(Order)
        .filter(
            Order.id == order_id,
            Order.delivery_person_id == user.id,
        )
        .first()
    )

    if not order:
        return jsonify({
            "status": "error",
            "message": (
                "Order not found or not assigned to you."
            ),
        }), 404

    # -----------------------------------------------------
    # CANCELLED ORDER
    # -----------------------------------------------------

    if order.status == "cancelled":
        return jsonify({
            "status": "error",
            "message": (
                "Cancelled orders cannot be updated."
            ),
        }), 400

    # -----------------------------------------------------
    # ALREADY DELIVERED
    # -----------------------------------------------------

    if order.status == "delivered":
        return jsonify({
            "status": "error",
            "message": (
                "This order has already been delivered."
            ),
        }), 400

    # -----------------------------------------------------
    # UPDATE STATUS
    # -----------------------------------------------------

    order.status = new_status

    # -----------------------------------------------------
    # IMPORTANT:
    #
    # COD PAYMENT IS NO LONGER MARKED PAID HERE.
    #
    # It will be marked paid only after the customer
    # successfully confirms the delivery through QR.
    # -----------------------------------------------------

    # -----------------------------------------------------
    # SAVE
    # -----------------------------------------------------

    try:

        db.session.commit()

    except Exception as error:

        db.session.rollback()

        return jsonify({
            "status": "error",
            "message": (
                "Failed to update delivery status"
            ),
            "error": str(error),
        }), 500

    return jsonify({
        "status": "success",
        "message": (
            "Delivery status updated successfully"
        ),
        "order": order_to_dict(order),
    }), 200