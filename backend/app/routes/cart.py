from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity

from ..extensions import db
from ..models import Cart, CartItem, Product


# =========================================================
# CART BLUEPRINT
# =========================================================

cart_bp = Blueprint(
    "cart",
    __name__,
    url_prefix="/api/cart"
)


# =========================================================
# HELPERS
# =========================================================

def get_current_user_id():
    """
    Get the authenticated user's ID from the JWT.
    """

    identity = get_jwt_identity()

    try:
        return int(identity)
    except (TypeError, ValueError):
        return None


# =========================================================
# GET OR CREATE CART
# =========================================================

def get_or_create_cart(user_id):
    """
    Get the user's cart.

    If the user does not have a cart,
    create one automatically.
    """

    cart = (
        db.session.query(Cart)
        .filter(Cart.user_id == user_id)
        .first()
    )

    if cart:
        return cart

    cart = Cart(
        user_id=user_id
    )

    db.session.add(cart)
    db.session.commit()

    return cart


# =========================================================
# CART ITEM SERIALIZER
# =========================================================

def cart_item_to_dict(item):
    """
    Convert one CartItem into JSON-safe data.
    """

    product = item.product

    # -----------------------------------------------------
    # PRODUCT DOES NOT EXIST
    # -----------------------------------------------------

    if product is None:
        return {
            "id": item.id,
            "product_id": item.product_id,
            "quantity": item.quantity,
            "product": None,
            "unit_price": 0,
            "total": 0,
            "created_at": (
                item.created_at.isoformat()
                if item.created_at
                else None
            ),
            "updated_at": (
                item.updated_at.isoformat()
                if item.updated_at
                else None
            )
        }

    # -----------------------------------------------------
    # EFFECTIVE PRICE
    # -----------------------------------------------------

    if product.discount_price is not None:
        unit_price = float(product.discount_price)

    elif product.price is not None:
        unit_price = float(product.price)

    else:
        unit_price = 0.0

    # -----------------------------------------------------
    # ORIGINAL PRICE
    # -----------------------------------------------------

    original_price = (
        float(product.price)
        if product.price is not None
        else 0.0
    )

    # -----------------------------------------------------
    # DISCOUNT PRICE
    # -----------------------------------------------------

    discount_price = (
        float(product.discount_price)
        if product.discount_price is not None
        else None
    )

    # -----------------------------------------------------
    # ITEM TOTAL
    # -----------------------------------------------------

    item_total = unit_price * item.quantity

    # -----------------------------------------------------
    # RETURN ITEM
    # -----------------------------------------------------

    return {
        "id": item.id,

        "product_id": item.product_id,

        "product": {
            "id": product.id,
            "name": product.name,
            "slug": product.slug,
            "sku": product.sku,
            "brand": product.brand,
            "image": product.image,
            "price": original_price,
            "discount_price": discount_price,
            "stock": product.stock,
            "is_active": product.is_active,
            "is_featured": product.is_featured
        },

        "quantity": item.quantity,

        "unit_price": round(
            unit_price,
            2
        ),

        "total": round(
            item_total,
            2
        ),

        "created_at": (
            item.created_at.isoformat()
            if item.created_at
            else None
        ),

        "updated_at": (
            item.updated_at.isoformat()
            if item.updated_at
            else None
        )
    }


# =========================================================
# CART SERIALIZER
# =========================================================

def cart_to_dict(cart):
    """
    Convert Cart into JSON-safe data.
    """

    items = [
        cart_item_to_dict(item)
        for item in cart.items
    ]

    # -----------------------------------------------------
    # SUBTOTAL
    # -----------------------------------------------------

    subtotal = sum(
        item["total"]
        for item in items
    )

    # -----------------------------------------------------
    # TOTAL QUANTITY
    # -----------------------------------------------------

    total_items = sum(
        item["quantity"]
        for item in items
    )

    # -----------------------------------------------------
    # RETURN CART
    # -----------------------------------------------------

    return {
        "id": cart.id,

        "user_id": cart.user_id,

        "items": items,

        "total_items": total_items,

        "item_count": len(items),

        "subtotal": round(
            subtotal,
            2
        ),

        "created_at": (
            cart.created_at.isoformat()
            if cart.created_at
            else None
        ),

        "updated_at": (
            cart.updated_at.isoformat()
            if cart.updated_at
            else None
        )
    }


# =========================================================
# GET CART
# =========================================================

@cart_bp.get("/")
@jwt_required()
def get_cart():

    user_id = get_current_user_id()

    if user_id is None:
        return jsonify({
            "status": "error",
            "message": "Invalid authentication token"
        }), 401

    cart = get_or_create_cart(
        user_id
    )

    return jsonify({
        "status": "success",
        "cart": cart_to_dict(cart)
    }), 200


# =========================================================
# ADD PRODUCT TO CART
# =========================================================

@cart_bp.post("/items")
@jwt_required()
def add_to_cart():

    user_id = get_current_user_id()

    if user_id is None:
        return jsonify({
            "status": "error",
            "message": "Invalid authentication token"
        }), 401

    # -----------------------------------------------------
    # REQUEST DATA
    # -----------------------------------------------------

    data = request.get_json(
        silent=True
    ) or {}

    product_id = data.get(
        "product_id"
    )

    quantity = data.get(
        "quantity",
        1
    )

    # -----------------------------------------------------
    # VALIDATE PRODUCT ID
    # -----------------------------------------------------

    try:
        product_id = int(
            product_id
        )

    except (TypeError, ValueError):

        return jsonify({
            "status": "error",
            "message": "product_id must be a valid integer"
        }), 400

    # -----------------------------------------------------
    # VALIDATE QUANTITY
    # -----------------------------------------------------

    try:
        quantity = int(
            quantity
        )

    except (TypeError, ValueError):

        return jsonify({
            "status": "error",
            "message": "quantity must be a valid integer"
        }), 400

    if quantity < 1:

        return jsonify({
            "status": "error",
            "message": "Quantity must be at least 1"
        }), 400

    # -----------------------------------------------------
    # FIND PRODUCT
    # -----------------------------------------------------

    product = (
        db.session.query(Product)
        .filter(
            Product.id == product_id,
            Product.is_active.is_(True)
        )
        .first()
    )

    if not product:

        return jsonify({
            "status": "error",
            "message": "Product not found"
        }), 404

    # -----------------------------------------------------
    # STOCK CHECK
    # -----------------------------------------------------

    if product.stock <= 0:

        return jsonify({
            "status": "error",
            "message": "Product is out of stock"
        }), 400

    # -----------------------------------------------------
    # GET / CREATE CART
    # -----------------------------------------------------

    cart = get_or_create_cart(
        user_id
    )

    # -----------------------------------------------------
    # FIND EXISTING ITEM
    # -----------------------------------------------------

    cart_item = (
        db.session.query(CartItem)
        .filter(
            CartItem.cart_id == cart.id,
            CartItem.product_id == product.id
        )
        .first()
    )

    # -----------------------------------------------------
    # EXISTING ITEM
    # -----------------------------------------------------

    if cart_item:

        new_quantity = (
            cart_item.quantity
            + quantity
        )

        if new_quantity > product.stock:

            return jsonify({
                "status": "error",
                "message": (
                    f"Only {product.stock} "
                    "item(s) available in stock"
                )
            }), 400

        cart_item.quantity = new_quantity

    # -----------------------------------------------------
    # NEW ITEM
    # -----------------------------------------------------

    else:

        if quantity > product.stock:

            return jsonify({
                "status": "error",
                "message": (
                    f"Only {product.stock} "
                    "item(s) available in stock"
                )
            }), 400

        cart_item = CartItem(
            cart_id=cart.id,
            product_id=product.id,
            quantity=quantity
        )

        db.session.add(
            cart_item
        )

    # -----------------------------------------------------
    # SAVE
    # -----------------------------------------------------

    db.session.commit()

    return jsonify({
        "status": "success",
        "message": "Product added to cart",
        "cart": cart_to_dict(cart)
    }), 201


# =========================================================
# UPDATE CART ITEM
# =========================================================

@cart_bp.put("/items/<int:item_id>")
@jwt_required()
def update_cart_item(item_id):

    user_id = get_current_user_id()

    if user_id is None:
        return jsonify({
            "status": "error",
            "message": "Invalid authentication token"
        }), 401

    data = request.get_json(
        silent=True
    ) or {}

    quantity = data.get(
        "quantity"
    )

    # -----------------------------------------------------
    # VALIDATE QUANTITY
    # -----------------------------------------------------

    try:
        quantity = int(
            quantity
        )

    except (TypeError, ValueError):

        return jsonify({
            "status": "error",
            "message": "quantity must be a valid integer"
        }), 400

    if quantity < 1:

        return jsonify({
            "status": "error",
            "message": "Quantity must be at least 1"
        }), 400

    # -----------------------------------------------------
    # FIND CART
    # -----------------------------------------------------

    cart = (
        db.session.query(Cart)
        .filter(
            Cart.user_id == user_id
        )
        .first()
    )

    if not cart:

        return jsonify({
            "status": "error",
            "message": "Cart not found"
        }), 404

    # -----------------------------------------------------
    # FIND CART ITEM
    # -----------------------------------------------------

    cart_item = (
        db.session.query(CartItem)
        .filter(
            CartItem.id == item_id,
            CartItem.cart_id == cart.id
        )
        .first()
    )

    if not cart_item:

        return jsonify({
            "status": "error",
            "message": "Cart item not found"
        }), 404

    # -----------------------------------------------------
    # GET PRODUCT
    # -----------------------------------------------------

    product = cart_item.product

    if product is None:

        return jsonify({
            "status": "error",
            "message": "Product no longer exists"
        }), 404

    # -----------------------------------------------------
    # ACTIVE CHECK
    # -----------------------------------------------------

    if not product.is_active:

        return jsonify({
            "status": "error",
            "message": "Product is no longer available"
        }), 400

    # -----------------------------------------------------
    # STOCK CHECK
    # -----------------------------------------------------

    if quantity > product.stock:

        return jsonify({
            "status": "error",
            "message": (
                f"Only {product.stock} "
                "item(s) available in stock"
            )
        }), 400

    # -----------------------------------------------------
    # UPDATE
    # -----------------------------------------------------

    cart_item.quantity = quantity

    db.session.commit()

    return jsonify({
        "status": "success",
        "message": "Cart item updated",
        "cart": cart_to_dict(cart)
    }), 200


# =========================================================
# REMOVE CART ITEM
# =========================================================

@cart_bp.delete("/items/<int:item_id>")
@jwt_required()
def remove_cart_item(item_id):

    user_id = get_current_user_id()

    if user_id is None:
        return jsonify({
            "status": "error",
            "message": "Invalid authentication token"
        }), 401

    # -----------------------------------------------------
    # FIND CART
    # -----------------------------------------------------

    cart = (
        db.session.query(Cart)
        .filter(
            Cart.user_id == user_id
        )
        .first()
    )

    if not cart:

        return jsonify({
            "status": "error",
            "message": "Cart not found"
        }), 404

    # -----------------------------------------------------
    # FIND ITEM
    # -----------------------------------------------------

    cart_item = (
        db.session.query(CartItem)
        .filter(
            CartItem.id == item_id,
            CartItem.cart_id == cart.id
        )
        .first()
    )

    if not cart_item:

        return jsonify({
            "status": "error",
            "message": "Cart item not found"
        }), 404

    # -----------------------------------------------------
    # DELETE ITEM
    # -----------------------------------------------------

    db.session.delete(
        cart_item
    )

    db.session.commit()

    return jsonify({
        "status": "success",
        "message": "Product removed from cart",
        "cart": cart_to_dict(cart)
    }), 200


# =========================================================
# CLEAR CART
# =========================================================

@cart_bp.delete("/clear")
@jwt_required()
def clear_cart():

    user_id = get_current_user_id()

    if user_id is None:
        return jsonify({
            "status": "error",
            "message": "Invalid authentication token"
        }), 401

    # -----------------------------------------------------
    # FIND CART
    # -----------------------------------------------------

    cart = (
        db.session.query(Cart)
        .filter(
            Cart.user_id == user_id
        )
        .first()
    )

    if not cart:

        return jsonify({
            "status": "success",
            "message": "Cart is already empty",
            "cart": {
                "items": [],
                "total_items": 0,
                "item_count": 0,
                "subtotal": 0
            }
        }), 200

    # -----------------------------------------------------
    # DELETE ALL ITEMS
    # -----------------------------------------------------

    for item in list(cart.items):
        db.session.delete(item)

    db.session.commit()

    return jsonify({
        "status": "success",
        "message": "Cart cleared",
        "cart": cart_to_dict(cart)
    }), 200