from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from werkzeug.utils import secure_filename

import os
import uuid
import re

from sqlalchemy import text

from ..config import Config
from ..extensions import db
from ..models import (
    Category,
    Product,
    ProductImage,
    User,
    Order
)


# =========================================================
# ADMIN BLUEPRINT
# =========================================================

admin_bp = Blueprint(
    "admin",
    __name__,
    url_prefix="/api/admin"
)


# =========================================================
# HELPER FUNCTIONS
# =========================================================

def allowed_image(filename):
    """
    Check whether the uploaded file has
    an allowed image extension.
    """

    if not filename:
        return False

    if "." not in filename:
        return False

    extension = filename.rsplit(".", 1)[1].lower()

    return extension in Config.ALLOWED_IMAGE_EXTENSIONS


# =========================================================
# ADMIN AUTHENTICATION
# =========================================================

def get_current_admin():
    """
    Get the currently authenticated user.

    Returns the User object only when the
    authenticated user has the admin role.
    """

    identity = get_jwt_identity()

    try:
        user_id = int(identity)

    except (
        TypeError,
        ValueError
    ):
        return None

    user = db.session.get(
        User,
        user_id
    )

    if not user:
        return None

    if str(
        user.role or ""
    ).strip().lower() != "admin":
        return None

    return user


# =========================================================
# PRODUCT IMAGE SERIALIZER
# =========================================================

def product_image_to_dict(image):
    """
    Convert ProductImage model to JSON-friendly dictionary.
    """

    return {
        "id": image.id,

        "product_id": image.product_id,

        "image_url": image.image_url,

        "alt_text": image.alt_text,

        "is_primary": image.is_primary,

        "display_order": image.display_order,

        "created_at": (
            image.created_at.isoformat()
            if image.created_at
            else None
        )
    }


# =========================================================
# PRODUCT SERIALIZER
# =========================================================

def product_to_dict(product):
    """
    Convert Product model to JSON-friendly dictionary.

    Includes:
    - Main product image
    - All ProductImage records
    """

    images = (
        ProductImage.query
        .filter_by(
            product_id=product.id
        )
        .order_by(
            ProductImage.display_order.asc(),
            ProductImage.id.asc()
        )
        .all()
    )

    return {
        "id": product.id,

        "name": product.name,

        "slug": product.slug,

        "sku": product.sku,

        "description": product.description,

        "brand": product.brand,

        "price": (
            float(product.price)
            if product.price is not None
            else None
        ),

        "discount_price": (
            float(product.discount_price)
            if product.discount_price is not None
            else None
        ),

        "stock": product.stock,

        "category_id": product.category_id,

        "image": product.image,

        "images": [
            product_image_to_dict(image)
            for image in images
        ],

        "is_active": product.is_active,

        "is_featured": product.is_featured,

        "rating": (
            float(product.rating)
            if product.rating is not None
            else 0
        ),

        "review_count": product.review_count,

        "created_at": (
            product.created_at.isoformat()
            if product.created_at
            else None
        ),

        "updated_at": (
            product.updated_at.isoformat()
            if product.updated_at
            else None
        )
    }


# =========================================================
# CATEGORY SERIALIZER
# =========================================================

def category_to_dict(category):
    """
    Convert Category model to JSON-friendly dictionary.
    """

    return {
        "id": category.id,

        "name": category.name,

        "slug": category.slug,

        "description": category.description,

        "image": category.image,

        "is_active": category.is_active,

        "created_at": (
            category.created_at.isoformat()
            if category.created_at
            else None
        ),

        "updated_at": (
            category.updated_at.isoformat()
            if category.updated_at
            else None
        )
    }


# =========================================================
# ADMIN ORDER ITEM SERIALIZER
# =========================================================

def admin_order_item_to_dict(item):
    """
    Convert OrderItem to JSON-friendly dictionary.
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
        )
    }


# =========================================================
# ADMIN ORDER SERIALIZER
# =========================================================

def admin_order_to_dict(order):
    """
    Convert Order model to JSON-friendly dictionary
    for the administrator dashboard.
    """

    return {

        "id": order.id,

        "user_id": order.user_id,

        "status": order.status,

        "payment_status": order.payment_status,

        "payment_method": order.payment_method,

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

        "customer": {

            "name": order.shipping_name,

            "phone": order.shipping_phone,

            "address": order.shipping_address,

            "city": order.shipping_city,

            "state": order.shipping_state,

            "pincode": order.shipping_pincode
        },

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
            admin_order_item_to_dict(item)
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
# ADMIN HOME
# =========================================================

@admin_bp.get("/")
def admin_home():

    return jsonify({

        "app": "Shop To Door",

        "section": "Admin",

        "message": "Shop To Door Admin API is running",

        "status": "success"
    })


# =========================================================
# ADMIN DASHBOARD
# =========================================================

@admin_bp.get("/dashboard")
def dashboard():

    user_count = (
        db.session.query(User).count()
    )

    category_count = (
        db.session.query(Category).count()
    )

    product_count = (
        db.session.query(Product).count()
    )

    image_count = (
        db.session.query(ProductImage).count()
    )

    return jsonify({

        "status": "success",

        "dashboard": {

            "users": user_count,

            "categories": category_count,

            "products": product_count,

            "product_images": image_count
        }
    })


# =========================================================
# ADMIN ORDERS
# LIST ALL ORDERS
# =========================================================

@admin_bp.get("/orders")
@jwt_required()
def get_admin_orders():

    admin = get_current_admin()

    if not admin:

        return jsonify({

            "status": "error",

            "message": "Administrator access required"

        }), 403

    orders = (
        Order.query
        .order_by(
            Order.created_at.desc()
        )
        .all()
    )

    return jsonify({

        "status": "success",

        "count": len(orders),

        "orders": [
            admin_order_to_dict(order)
            for order in orders
        ]

    }), 200


# =========================================================
# ADMIN ORDERS
# GET ONE ORDER
# =========================================================

@admin_bp.get("/orders/<int:order_id>")
@jwt_required()
def get_admin_order(order_id):

    admin = get_current_admin()

    if not admin:

        return jsonify({

            "status": "error",

            "message": "Administrator access required"

        }), 403

    order = db.session.get(
        Order,
        order_id
    )

    if not order:

        return jsonify({

            "status": "error",

            "message": "Order not found"

        }), 404

    return jsonify({

        "status": "success",

        "order": admin_order_to_dict(order)

    }), 200


# =========================================================
# ADMIN ORDERS
# UPDATE ORDER STATUS
# =========================================================

@admin_bp.put(
    "/orders/<int:order_id>/status"
)
@jwt_required()
def update_admin_order_status(order_id):

    admin = get_current_admin()

    if not admin:

        return jsonify({

            "status": "error",

            "message": "Administrator access required"

        }), 403

    order = db.session.get(
        Order,
        order_id
    )

    if not order:

        return jsonify({

            "status": "error",

            "message": "Order not found"

        }), 404

    data = (
        request.get_json(
            silent=True
        )
        or {}
    )

    new_status = str(
        data.get(
            "status",
            ""
        )
    ).strip().lower()

    allowed_statuses = {

        "pending",

        "assigned",

        "packed",

        "shipped",

        "picked_up",

        "out_for_delivery",

        "delivered",

        "delivery_failed",

        "cancelled"
    }

    if new_status not in allowed_statuses:

        return jsonify({

            "status": "error",

            "message": "Invalid order status",

            "allowed_statuses": [
                "pending",
                "assigned",
                "packed",
                "shipped",
                "picked_up",
                "out_for_delivery",
                "delivered",
                "delivery_failed",
                "cancelled"
            ]

        }), 400

    old_status = order.status

    order.status = new_status

    try:

        db.session.commit()

    except Exception as error:

        db.session.rollback()

        return jsonify({

            "status": "error",

            "message": "Failed to update order status",

            "error": str(error)

        }), 500

    return jsonify({

        "status": "success",

        "message": "Order status updated successfully",

        "order": {

            "id": order.id,

            "old_status": old_status,

            "status": order.status,

            "payment_status": order.payment_status,

            "updated_at": (
                order.updated_at.isoformat()
                if order.updated_at
                else None
            )
        }

    }), 200


# =========================================================
# CATEGORY
# LIST ALL
# =========================================================

@admin_bp.get("/categories")
def get_categories():

    categories = (
        Category.query
        .order_by(
            Category.id.asc()
        )
        .all()
    )

    return jsonify({

        "status": "success",

        "count": len(categories),

        "categories": [
            category_to_dict(category)
            for category in categories
        ]
    })


# =========================================================
# CATEGORY
# GET ONE
# =========================================================

@admin_bp.get(
    "/categories/<int:category_id>"
)
def get_category(category_id):

    category = db.session.get(
        Category,
        category_id
    )

    if not category:

        return jsonify({

            "status": "error",

            "message": "Category not found"

        }), 404

    return jsonify({

        "status": "success",

        "category": category_to_dict(category)

    })


# =========================================================
# CATEGORY
# UPLOAD IMAGE
# =========================================================

@admin_bp.post(
    "/categories/<int:category_id>/image"
)
def upload_category_image(category_id):

    # -----------------------------------------------------
    # FIND CATEGORY
    # -----------------------------------------------------

    category = db.session.get(
        Category,
        category_id
    )

    if not category:

        return jsonify({

            "status": "error",

            "message": "Category not found"

        }), 404

    # -----------------------------------------------------
    # CHECK FILE
    # -----------------------------------------------------

    if "image" not in request.files:

        return jsonify({

            "status": "error",

            "message": "Image file is required"

        }), 400

    image_file = request.files["image"]

    if (
        not image_file
        or not image_file.filename
    ):

        return jsonify({

            "status": "error",

            "message": "No image selected"

        }), 400

    # -----------------------------------------------------
    # VALIDATE IMAGE FORMAT
    # -----------------------------------------------------

    if not allowed_image(
        image_file.filename
    ):

        return jsonify({

            "status": "error",

            "message": (
                "Invalid image format. "
                "Allowed formats: png, jpg, jpeg, webp"
            )

        }), 400

    # -----------------------------------------------------
    # CREATE CATEGORY UPLOAD DIRECTORY
    # -----------------------------------------------------

    os.makedirs(
        Config.CATEGORY_UPLOAD_FOLDER,
        exist_ok=True
    )

    # -----------------------------------------------------
    # SECURE ORIGINAL FILENAME
    # -----------------------------------------------------

    original_filename = secure_filename(
        image_file.filename
    )

    if not original_filename:

        return jsonify({

            "status": "error",

            "message": "Invalid image filename"

        }), 400

    # -----------------------------------------------------
    # CREATE UNIQUE FILENAME
    # -----------------------------------------------------

    unique_filename = (
        f"{category_id}_"
        f"{uuid.uuid4().hex}_"
        f"{original_filename}"
    )

    file_path = os.path.join(
        Config.CATEGORY_UPLOAD_FOLDER,
        unique_filename
    )

    # -----------------------------------------------------
    # SAVE NEW IMAGE
    # -----------------------------------------------------

    try:

        image_file.save(
            file_path
        )

    except Exception as error:

        return jsonify({

            "status": "error",

            "message": "Unable to save category image",

            "error": str(error)

        }), 500

    # -----------------------------------------------------
    # REMEMBER OLD IMAGE
    # -----------------------------------------------------

    old_image = category.image

    # -----------------------------------------------------
    # PUBLIC IMAGE URL
    # -----------------------------------------------------

    image_url = (
        f"/uploads/categories/"
        f"{unique_filename}"
    )

    # -----------------------------------------------------
    # UPDATE DATABASE
    # -----------------------------------------------------

    category.image = image_url

    try:

        db.session.commit()

    except Exception as error:

        db.session.rollback()

        # Remove newly uploaded file
        if os.path.isfile(file_path):

            try:
                os.remove(file_path)

            except OSError:
                pass

        return jsonify({

            "status": "error",

            "message": (
                "Unable to save category "
                "image information"
            ),

            "error": str(error)

        }), 500

    # -----------------------------------------------------
    # DELETE OLD IMAGE AFTER DATABASE SUCCESS
    # -----------------------------------------------------

    if (
        old_image
        and old_image.startswith(
            "/uploads/categories/"
        )
    ):

        old_filename = os.path.basename(
            old_image
        )

        old_file_path = os.path.join(
            Config.CATEGORY_UPLOAD_FOLDER,
            old_filename
        )

        if (
            os.path.isfile(
                old_file_path
            )
            and os.path.abspath(old_file_path)
            != os.path.abspath(file_path)
        ):

            try:

                os.remove(
                    old_file_path
                )

            except OSError:

                pass

    # -----------------------------------------------------
    # SUCCESS
    # -----------------------------------------------------

    return jsonify({

        "status": "success",

        "message": (
            "Category image uploaded "
            "successfully"
        ),

        "category": category_to_dict(
            category
        ),

        "image": category.image

    }), 201


# =========================================================
# CATEGORY
# CREATE
# =========================================================

@admin_bp.post("/categories")
def create_category():

    data = request.get_json(
        silent=True
    ) or {}

    name = str(
        data.get(
            "name",
            ""
        )
    ).strip()

    description = data.get(
        "description"
    )

    image = data.get(
        "image"
    )

    is_active = data.get(
        "is_active",
        True
    )

    # -----------------------------------------------------
    # VALIDATE NAME
    # -----------------------------------------------------

    if not name:

        return jsonify({

            "status": "error",

            "message": "Category name is required"

        }), 400

    # -----------------------------------------------------
    # GENERATE SLUG
    # -----------------------------------------------------

    slug = str(
        data.get(
            "slug",
            ""
        )
    ).strip()

    if not slug:

        slug = name.lower()

        slug = re.sub(
            r"[\s_]+",
            "-",
            slug
        )

        slug = re.sub(
            r"[^a-z0-9-]",
            "",
            slug
        )

        slug = re.sub(
            r"-+",
            "-",
            slug
        )

        slug = slug.strip("-")

    if not slug:

        return jsonify({

            "status": "error",

            "message": (
                "Category slug could not be generated"
            )

        }), 400

    # -----------------------------------------------------
    # DUPLICATE NAME
    # -----------------------------------------------------

    existing_name = Category.query.filter(
        Category.name.ilike(
            name
        )
    ).first()

    if existing_name:

        return jsonify({

            "status": "error",

            "message": (
                "A category with this name "
                "already exists"
            )

        }), 409

    # -----------------------------------------------------
    # DUPLICATE SLUG
    # -----------------------------------------------------

    existing_slug = Category.query.filter(
        Category.slug.ilike(
            slug
        )
    ).first()

    if existing_slug:

        return jsonify({

            "status": "error",

            "message": (
                "A category with this slug "
                "already exists"
            )

        }), 409

    # -----------------------------------------------------
    # CREATE CATEGORY
    # -----------------------------------------------------

    category = Category(

        name=name,

        slug=slug,

        description=description,

        image=image,

        is_active=is_active
    )

    try:

        db.session.add(
            category
        )

        db.session.commit()

    except Exception as error:

        db.session.rollback()

        return jsonify({

            "status": "error",

            "message": "Unable to create category",

            "error": str(error)

        }), 409

    return jsonify({

        "status": "success",

        "message": "Category created successfully",

        "category": category_to_dict(
            category
        )

    }), 201


# =========================================================
# CATEGORY
# UPDATE
# =========================================================

@admin_bp.put(
    "/categories/<int:category_id>"
)
def update_category(category_id):

    category = db.session.get(
        Category,
        category_id
    )

    if not category:

        return jsonify({

            "status": "error",

            "message": "Category not found"

        }), 404

    data = request.get_json(
        silent=True
    ) or {}

    # -----------------------------------------------------
    # NAME
    # -----------------------------------------------------

    if "name" in data:

        name = str(
            data["name"]
        ).strip()

        if not name:

            return jsonify({

                "status": "error",

                "message": (
                    "Category name cannot be empty"
                )

            }), 400

        duplicate = Category.query.filter(

            Category.name.ilike(
                name
            ),

            Category.id != category_id

        ).first()

        if duplicate:

            return jsonify({

                "status": "error",

                "message": (
                    "A category with this name "
                    "already exists"
                )

            }), 409

        category.name = name

    # -----------------------------------------------------
    # SLUG
    # -----------------------------------------------------

    if "slug" in data:

        slug = str(
            data["slug"]
        ).strip()

        if not slug:

            return jsonify({

                "status": "error",

                "message": (
                    "Category slug cannot be empty"
                )

            }), 400

        duplicate = Category.query.filter(

            Category.slug.ilike(
                slug
            ),

            Category.id != category_id

        ).first()

        if duplicate:

            return jsonify({

                "status": "error",

                "message": (
                    "A category with this slug "
                    "already exists"
                )

            }), 409

        category.slug = slug

    # -----------------------------------------------------
    # DESCRIPTION
    # -----------------------------------------------------

    if "description" in data:

        category.description = (
            data["description"]
        )

    # -----------------------------------------------------
    # IMAGE URL
    # -----------------------------------------------------

    if "image" in data:

        category.image = (
            data["image"]
        )

    # -----------------------------------------------------
    # ACTIVE STATUS
    # -----------------------------------------------------

    if "is_active" in data:

        category.is_active = bool(
            data["is_active"]
        )

    db.session.commit()

    return jsonify({

        "status": "success",

        "message": "Category updated successfully",

        "category": category_to_dict(
            category
        )

    })


# =========================================================
# CATEGORY
# DELETE
# =========================================================

@admin_bp.delete(
    "/categories/<int:category_id>"
)
def delete_category(category_id):

    category = db.session.get(
        Category,
        category_id
    )

    if not category:

        return jsonify({

            "status": "error",

            "message": "Category not found"

        }), 404

    # -----------------------------------------------------
    # FIND ALL PRODUCTS IN CATEGORY
    # -----------------------------------------------------

    products = (
        Product.query
        .filter_by(
            category_id=category_id
        )
        .all()
    )

    deleted_product_count = 0
    deleted_image_count = 0

    try:

        # -------------------------------------------------
        # DELETE CATEGORY IMAGE
        # -------------------------------------------------

        if (
            category.image
            and category.image.startswith(
                "/uploads/categories/"
            )
        ):

            category_filename = os.path.basename(
                category.image
            )

            category_image_file = os.path.join(
                Config.CATEGORY_UPLOAD_FOLDER,
                category_filename
            )

            if os.path.isfile(
                category_image_file
            ):

                try:

                    os.remove(
                        category_image_file
                    )

                except OSError:

                    pass

        # -------------------------------------------------
        # DELETE PRODUCTS AND THEIR IMAGES
        # -------------------------------------------------

        for product in products:

            images = (
                ProductImage.query
                .filter_by(
                    product_id=product.id
                )
                .all()
            )

            # ---------------------------------------------
            # DELETE PHYSICAL PRODUCT IMAGE FILES
            # ---------------------------------------------

            for image in images:

                if (
                    image.image_url
                    and image.image_url.startswith(
                        "/uploads/products/"
                    )
                ):

                    filename = os.path.basename(
                        image.image_url
                    )

                    physical_file = os.path.join(
                        Config.PRODUCT_UPLOAD_FOLDER,
                        filename
                    )

                    if os.path.isfile(
                        physical_file
                    ):

                        try:

                            os.remove(
                                physical_file
                            )

                        except OSError:

                            pass

                db.session.delete(
                    image
                )

                deleted_image_count += 1

            db.session.flush()

            db.session.delete(
                product
            )

            deleted_product_count += 1

        db.session.flush()

        db.session.delete(
            category
        )

        db.session.commit()

    except Exception as error:

        db.session.rollback()

        return jsonify({

            "status": "error",

            "message": "Unable to delete category",

            "error": str(error)

        }), 409

    return jsonify({

        "status": "success",

        "message": "Category deleted successfully",

        "deleted_products": deleted_product_count,

        "deleted_product_images": deleted_image_count

    }), 200


# =========================================================
# PRODUCT
# LIST ALL
# =========================================================

@admin_bp.get("/products")
def get_products():

    products = (
        Product.query
        .order_by(
            Product.id.asc()
        )
        .all()
    )

    return jsonify({

        "status": "success",

        "count": len(products),

        "products": [
            product_to_dict(product)
            for product in products
        ]
    })


# =========================================================
# PRODUCT
# GET ONE
# =========================================================

@admin_bp.get(
    "/products/<int:product_id>"
)
def get_product(product_id):

    product = db.session.get(
        Product,
        product_id
    )

    if not product:

        return jsonify({

            "status": "error",

            "message": "Product not found"

        }), 404

    return jsonify({

        "status": "success",

        "product": product_to_dict(
            product
        )

    })


# =========================================================
# PRODUCT
# CREATE
# =========================================================

@admin_bp.post("/products")
def create_product():

    # -----------------------------------------------------
    # READ FORM DATA
    # -----------------------------------------------------

    if (
        request.content_type
        and request.content_type.startswith(
            "multipart/form-data"
        )
    ):

        data = request.form.to_dict()

    else:

        data = (
            request.get_json(
                silent=True
            )
            or {}
        )

    # -----------------------------------------------------
    # OPTIONAL PRODUCT IMAGE
    # -----------------------------------------------------

    image_file = request.files.get(
        "image"
    )

    if image_file and not image_file.filename:

        image_file = None

    # -----------------------------------------------------
    # VALIDATE IMAGE FORMAT WHEN PROVIDED
    # -----------------------------------------------------

    if image_file:

        if not allowed_image(
            image_file.filename
        ):

            return jsonify({

                "status": "error",

                "message": (
                    "Invalid image format. "
                    "Allowed formats: png, jpg, jpeg, webp"
                )

            }), 400

    # -----------------------------------------------------
    # BASIC INFORMATION
    # -----------------------------------------------------

    name = str(
        data.get(
            "name",
            ""
        )
    ).strip()

    brand = str(
        data.get(
            "brand",
            ""
        )
    ).strip()

    description = data.get(
        "description"
    )

    sku = str(
        data.get(
            "sku",
            ""
        )
    ).strip()

    if not name:

        return jsonify({

            "status": "error",

            "message": "Product name is required"

        }), 400

    # -----------------------------------------------------
    # SLUG
    # -----------------------------------------------------

    slug = str(
        data.get(
            "slug",
            ""
        )
    ).strip()

    if not slug:

        slug = name.lower()

        slug = slug.replace(
            " ",
            "-"
        )

        slug = "".join(

            character

            for character in slug

            if character.isalnum()
            or character == "-"
        )

    if not slug:

        return jsonify({

            "status": "error",

            "message": (
                "Product slug could not be generated"
            )

        }), 400

    # -----------------------------------------------------
    # SKU
    # -----------------------------------------------------

    if not sku:

        sku = (
            f"{slug.upper()}-"
            f"{uuid.uuid4().hex[:8].upper()}"
        )

    # -----------------------------------------------------
    # DUPLICATE SLUG
    # -----------------------------------------------------

    if Product.query.filter_by(
        slug=slug
    ).first():

        slug = (
            f"{slug}-"
            f"{uuid.uuid4().hex[:6]}"
        )

    # -----------------------------------------------------
    # DUPLICATE SKU
    # -----------------------------------------------------

    if Product.query.filter_by(
        sku=sku
    ).first():

        sku = (
            f"{sku}-"
            f"{uuid.uuid4().hex[:6].upper()}"
        )

    # -----------------------------------------------------
    # CATEGORY
    # -----------------------------------------------------

    category_id = data.get(
        "category_id"
    )

    if category_id is None:

        return jsonify({

            "status": "error",

            "message": "category_id is required"

        }), 400

    try:

        category_id = int(
            category_id
        )

    except (
        TypeError,
        ValueError
    ):

        return jsonify({

            "status": "error",

            "message": "Invalid category_id"

        }), 400

    category = db.session.get(
        Category,
        category_id
    )

    if not category:

        return jsonify({

            "status": "error",

            "message": "Category not found"

        }), 404

    # -----------------------------------------------------
    # PRICE
    # -----------------------------------------------------

    try:

        price = float(
            data.get(
                "price",
                0
            )
        )

    except (
        TypeError,
        ValueError
    ):

        return jsonify({

            "status": "error",

            "message": "Invalid price"

        }), 400

    if price < 0:

        return jsonify({

            "status": "error",

            "message": "Price cannot be negative"

        }), 400

    # -----------------------------------------------------
    # DISCOUNT PRICE
    # -----------------------------------------------------

    discount_price = data.get(
        "discount_price"
    )

    if discount_price in (
        "",
        None
    ):

        discount_price = None

    else:

        try:

            discount_price = float(
                discount_price
            )

        except (
            TypeError,
            ValueError
        ):

            return jsonify({

                "status": "error",

                "message": "Invalid discount price"

            }), 400

        if discount_price < 0:

            return jsonify({

                "status": "error",

                "message": (
                    "Discount price cannot be negative"
                )

            }), 400

        if discount_price > price:

            return jsonify({

                "status": "error",

                "message": (
                    "Discount price cannot be greater "
                    "than the original price"
                )

            }), 400

    # -----------------------------------------------------
    # STOCK
    # -----------------------------------------------------

    try:

        stock = int(
            data.get(
                "stock",
                0
            )
        )

    except (
        TypeError,
        ValueError
    ):

        return jsonify({

            "status": "error",

            "message": "Invalid stock"

        }), 400

    if stock < 0:

        return jsonify({

            "status": "error",

            "message": "Stock cannot be negative"

        }), 400

    # -----------------------------------------------------
    # BOOLEAN HELPER
    # -----------------------------------------------------

    def parse_bool(
        value,
        default=False
    ):

        if value is None:
            return default

        if isinstance(
            value,
            bool
        ):
            return value

        if isinstance(
            value,
            str
        ):

            return (
                value.lower()
                in (
                    "true",
                    "1",
                    "yes",
                    "on"
                )
            )

        return bool(value)

    is_featured = parse_bool(
        data.get(
            "is_featured",
            False
        )
    )

    is_active = parse_bool(
        data.get(
            "is_active",
            True
        )
    )

    # -----------------------------------------------------
    # IMAGE VARIABLES
    # -----------------------------------------------------

    image_url = None
    file_path = None

    # -----------------------------------------------------
    # SAVE IMAGE ONLY WHEN PROVIDED
    # -----------------------------------------------------

    if image_file:

        # -------------------------------------------------
        # CREATE UPLOAD DIRECTORY
        # -------------------------------------------------

        os.makedirs(
            Config.PRODUCT_UPLOAD_FOLDER,
            exist_ok=True
        )

        # -------------------------------------------------
        # SECURE ORIGINAL FILENAME
        # -------------------------------------------------

        original_filename = secure_filename(
            image_file.filename
        )

        if not original_filename:

            return jsonify({

                "status": "error",

                "message": "Invalid image filename"

            }), 400

        # -------------------------------------------------
        # UNIQUE IMAGE FILENAME
        # -------------------------------------------------

        unique_filename = (
            f"new_product_"
            f"{uuid.uuid4().hex}_"
            f"{original_filename}"
        )

        file_path = os.path.join(
            Config.PRODUCT_UPLOAD_FOLDER,
            unique_filename
        )

        # -------------------------------------------------
        # SAVE IMAGE FILE
        # -------------------------------------------------

        try:

            image_file.save(
                file_path
            )

        except Exception as error:

            return jsonify({

                "status": "error",

                "message": "Unable to save product image",

                "error": str(error)

            }), 500

        # -------------------------------------------------
        # PUBLIC IMAGE URL
        # -------------------------------------------------

        image_url = (
            f"/uploads/products/"
            f"{unique_filename}"
        )

    # -----------------------------------------------------
    # CREATE PRODUCT
    # -----------------------------------------------------

    product = Product(

        name=name,

        slug=slug,

        sku=sku,

        description=description,

        brand=brand,

        price=price,

        discount_price=discount_price,

        stock=stock,

        category_id=category_id,

        image=image_url,

        is_active=is_active,

        is_featured=is_featured,

        rating=data.get(
            "rating",
            0
        ),

        review_count=data.get(
            "review_count",
            0
        )
    )

    try:

        db.session.add(
            product
        )

        db.session.flush()

        # -------------------------------------------------
        # CREATE PRIMARY PRODUCT IMAGE ONLY IF PROVIDED
        # -------------------------------------------------

        if image_url:

            product_image = ProductImage(

                product_id=product.id,

                image_url=image_url,

                alt_text=name,

                is_primary=True,

                display_order=0
            )

            db.session.add(
                product_image
            )

        db.session.commit()

    except Exception as error:

        db.session.rollback()

        if (
            file_path
            and os.path.isfile(
                file_path
            )
        ):

            try:

                os.remove(
                    file_path
                )

            except OSError:

                pass

        return jsonify({

            "status": "error",

            "message": "Unable to create product",

            "error": str(error)

        }), 409

    return jsonify({

        "status": "success",

        "message": "Product created successfully",

        "product": product_to_dict(
            product
        )

    }), 201


# =========================================================
# PRODUCT
# UPDATE
# =========================================================

@admin_bp.put(
    "/products/<int:product_id>"
)
def update_product(product_id):

    product = db.session.get(
        Product,
        product_id
    )

    if not product:

        return jsonify({

            "status": "error",

            "message": "Product not found"

        }), 404

    data = request.get_json(
        silent=True
    ) or {}

    # -----------------------------------------------------
    # NAME
    # -----------------------------------------------------

    if "name" in data:

        name = str(
            data["name"]
        ).strip()

        if not name:

            return jsonify({

                "status": "error",

                "message": (
                    "Product name cannot be empty"
                )

            }), 400

        product.name = name

    # -----------------------------------------------------
    # SLUG
    # -----------------------------------------------------

    if "slug" in data:

        slug = str(
            data["slug"]
        ).strip()

        if not slug:

            return jsonify({

                "status": "error",

                "message": (
                    "Product slug cannot be empty"
                )

            }), 400

        duplicate = Product.query.filter(

            Product.slug == slug,

            Product.id != product_id

        ).first()

        if duplicate:

            return jsonify({

                "status": "error",

                "message": (
                    "A product with this slug "
                    "already exists"
                )

            }), 409

        product.slug = slug

    # -----------------------------------------------------
    # SKU
    # -----------------------------------------------------

    if "sku" in data:

        sku = str(
            data["sku"]
        ).strip()

        if not sku:

            return jsonify({

                "status": "error",

                "message": (
                    "Product SKU cannot be empty"
                )

            }), 400

        duplicate = Product.query.filter(

            Product.sku == sku,

            Product.id != product_id

        ).first()

        if duplicate:

            return jsonify({

                "status": "error",

                "message": (
                    "A product with this SKU "
                    "already exists"
                )

            }), 409

        product.sku = sku

    # -----------------------------------------------------
    # OTHER FIELDS
    # -----------------------------------------------------

    if "description" in data:

        product.description = (
            data["description"]
        )

    if "brand" in data:

        product.brand = (
            data["brand"]
        )

    if "price" in data:

        try:

            product.price = float(
                data["price"]
            )

        except (
            TypeError,
            ValueError
        ):

            return jsonify({

                "status": "error",

                "message": "Invalid price"

            }), 400

    if "discount_price" in data:

        value = data[
            "discount_price"
        ]

        if value in (
            "",
            None
        ):

            product.discount_price = None

        else:

            try:

                product.discount_price = float(
                    value
                )

            except (
                TypeError,
                ValueError
            ):

                return jsonify({

                    "status": "error",

                    "message": "Invalid discount price"

                }), 400

    if "stock" in data:

        try:

            product.stock = int(
                data["stock"]
            )

        except (
            TypeError,
            ValueError
        ):

            return jsonify({

                "status": "error",

                "message": "Invalid stock"

            }), 400

    # -----------------------------------------------------
    # CATEGORY
    # -----------------------------------------------------

    if "category_id" in data:

        try:

            category_id = int(
                data["category_id"]
            )

        except (
            TypeError,
            ValueError
        ):

            return jsonify({

                "status": "error",

                "message": "Invalid category_id"

            }), 400

        category = db.session.get(
            Category,
            category_id
        )

        if not category:

            return jsonify({

                "status": "error",

                "message": "Category not found"

            }), 404

        product.category_id = category_id

    # -----------------------------------------------------
    # IMAGE
    # -----------------------------------------------------

    if "image" in data:

        product.image = (
            data["image"]
        )

    # -----------------------------------------------------
    # BOOLEAN
    # -----------------------------------------------------

    if "is_active" in data:

        product.is_active = (

            data["is_active"]

            if isinstance(
                data["is_active"],
                bool
            )

            else str(
                data["is_active"]
            ).lower()
            in (
                "true",
                "1",
                "yes",
                "on"
            )
        )

    if "is_featured" in data:

        product.is_featured = (

            data["is_featured"]

            if isinstance(
                data["is_featured"],
                bool
            )

            else str(
                data["is_featured"]
            ).lower()
            in (
                "true",
                "1",
                "yes",
                "on"
            )
        )

    db.session.commit()

    return jsonify({

        "status": "success",

        "message": "Product updated successfully",

        "product": product_to_dict(
            product
        )

    })


# =========================================================
# PRODUCT
# DELETE
# =========================================================

@admin_bp.delete(
    "/products/<int:product_id>"
)
def delete_product(product_id):

    product = db.session.get(
        Product,
        product_id
    )

    if not product:

        return jsonify({

            "status": "error",

            "message": "Product not found"

        }), 404

    try:

        # -------------------------------------------------
        # CHECK ORDER HISTORY
        # -------------------------------------------------

        order_item = db.session.execute(

            text(
                """
                SELECT 1
                FROM order_items
                WHERE product_id = :product_id
                LIMIT 1
                """
            ),

            {
                "product_id": product_id
            }

        ).first()

        # -------------------------------------------------
        # PRODUCT HAS ORDER HISTORY
        # -------------------------------------------------

        if order_item:

            product.is_active = False

            db.session.commit()

            return jsonify({

                "status": "success",

                "message": (
                    "Product has existing order history "
                    "and was deactivated instead of "
                    "permanently deleted."
                ),

                "deleted": False,

                "deactivated": True,

                "product": product_to_dict(
                    product
                )

            }), 200

        # -------------------------------------------------
        # NO ORDER HISTORY
        # -------------------------------------------------

        images = (
            ProductImage.query
            .filter_by(
                product_id=product_id
            )
            .all()
        )

        deleted_image_count = 0

        # -------------------------------------------------
        # DELETE PHYSICAL IMAGE FILES
        # -------------------------------------------------

        for image in images:

            if (
                image.image_url
                and image.image_url.startswith(
                    "/uploads/products/"
                )
            ):

                filename = os.path.basename(
                    image.image_url
                )

                physical_file = os.path.join(
                    Config.PRODUCT_UPLOAD_FOLDER,
                    filename
                )

                if os.path.isfile(
                    physical_file
                ):

                    try:

                        os.remove(
                            physical_file
                        )

                    except OSError:

                        pass

        # -------------------------------------------------
        # DELETE IMAGE DATABASE RECORDS
        # -------------------------------------------------

        for image in images:

            db.session.delete(
                image
            )

            deleted_image_count += 1

        db.session.flush()

        # -------------------------------------------------
        # DELETE PRODUCT
        # -------------------------------------------------

        db.session.delete(
            product
        )

        db.session.commit()

    except Exception as error:

        db.session.rollback()

        return jsonify({

            "status": "error",

            "message": "Unable to delete product",

            "error": str(error)

        }), 409

    return jsonify({

        "status": "success",

        "message": "Product deleted successfully",

        "deleted": True,

        "deactivated": False,

        "deleted_product_images": deleted_image_count

    }), 200


# =========================================================
# PRODUCT IMAGES
# LIST
# =========================================================

@admin_bp.get(
    "/products/<int:product_id>/images"
)
def get_product_images(product_id):

    product = db.session.get(
        Product,
        product_id
    )

    if not product:

        return jsonify({

            "status": "error",

            "message": "Product not found"

        }), 404

    images = (
        ProductImage.query
        .filter_by(
            product_id=product_id
        )
        .order_by(
            ProductImage.display_order.asc(),
            ProductImage.id.asc()
        )
        .all()
    )

    return jsonify({

        "status": "success",

        "product_id": product_id,

        "count": len(images),

        "images": [

            product_image_to_dict(
                image
            )

            for image in images
        ]
    })


# =========================================================
# PRODUCT IMAGES
# ADD IMAGE URL
# =========================================================

@admin_bp.post(
    "/products/<int:product_id>/images"
)
def add_product_image(product_id):

    product = db.session.get(
        Product,
        product_id
    )

    if not product:

        return jsonify({

            "status": "error",

            "message": "Product not found"

        }), 404

    data = request.get_json(
        silent=True
    ) or {}

    image_url = str(
        data.get(
            "image_url",
            ""
        )
    ).strip()

    if not image_url:

        return jsonify({

            "status": "error",

            "message": "image_url is required"

        }), 400

    existing_image_count = (
        ProductImage.query
        .filter_by(
            product_id=product_id
        )
        .count()
    )

    is_primary = data.get(
        "is_primary",
        existing_image_count == 0
    )

    if isinstance(
        is_primary,
        str
    ):

        is_primary = (
            is_primary.lower()
            in (
                "true",
                "1",
                "yes",
                "on"
            )
        )

    if is_primary:

        ProductImage.query.filter_by(

            product_id=product_id

        ).update({

            "is_primary": False
        })

        product.image = image_url

    image = ProductImage(

        product_id=product_id,

        image_url=image_url,

        alt_text=data.get(
            "alt_text",
            product.name
        ),

        is_primary=is_primary,

        display_order=data.get(
            "display_order",
            existing_image_count
        )
    )

    db.session.add(
        image
    )

    db.session.commit()

    return jsonify({

        "status": "success",

        "message": (
            "Product image added successfully"
        ),

        "image": product_image_to_dict(
            image
        )

    }), 201


# =========================================================
# PRODUCT IMAGE
# REAL FILE UPLOAD
# =========================================================

@admin_bp.post(
    "/products/<int:product_id>/images/upload"
)
def upload_product_image(product_id):

    # -----------------------------------------------------
    # FIND PRODUCT
    # -----------------------------------------------------

    product = db.session.get(
        Product,
        product_id
    )

    if not product:

        return jsonify({

            "status": "error",

            "message": "Product not found"

        }), 404

    # -----------------------------------------------------
    # CHECK FILE
    # -----------------------------------------------------

    if "image" not in request.files:

        return jsonify({

            "status": "error",

            "message": "Image file is required"

        }), 400

    file = request.files["image"]

    if (
        not file
        or not file.filename
    ):

        return jsonify({

            "status": "error",

            "message": "No image selected"

        }), 400

    # -----------------------------------------------------
    # VALIDATE IMAGE
    # -----------------------------------------------------

    if not allowed_image(
        file.filename
    ):

        return jsonify({

            "status": "error",

            "message": (
                "Invalid image format. "
                "Allowed formats: png, jpg, jpeg, webp"
            )

        }), 400

    # -----------------------------------------------------
    # CREATE UPLOAD DIRECTORY
    # -----------------------------------------------------

    os.makedirs(
        Config.PRODUCT_UPLOAD_FOLDER,
        exist_ok=True
    )

    # -----------------------------------------------------
    # SECURE FILENAME
    # -----------------------------------------------------

    original_filename = secure_filename(
        file.filename
    )

    if not original_filename:

        return jsonify({

            "status": "error",

            "message": "Invalid filename"

        }), 400

    # -----------------------------------------------------
    # UNIQUE FILENAME
    # -----------------------------------------------------

    unique_filename = (

        f"{product_id}_"

        f"{uuid.uuid4().hex}_"

        f"{original_filename}"
    )

    file_path = os.path.join(

        Config.PRODUCT_UPLOAD_FOLDER,

        unique_filename
    )

    # -----------------------------------------------------
    # SAVE FILE
    # -----------------------------------------------------

    try:

        file.save(
            file_path
        )

    except Exception as error:

        return jsonify({

            "status": "error",

            "message": "Unable to save image",

            "error": str(error)

        }), 500

    # -----------------------------------------------------
    # PUBLIC URL
    # -----------------------------------------------------

    image_url = (

        f"/uploads/products/"
        f"{unique_filename}"
    )

    # -----------------------------------------------------
    # EXISTING IMAGES
    # -----------------------------------------------------

    existing_image_count = (

        ProductImage.query
        .filter_by(
            product_id=product_id
        )
        .count()
    )

    # -----------------------------------------------------
    # FIRST IMAGE = PRIMARY
    # -----------------------------------------------------

    is_primary = (

        existing_image_count == 0
    )

    if is_primary:

        ProductImage.query.filter_by(

            product_id=product_id

        ).update({

            "is_primary": False
        })

        product.image = image_url

    # -----------------------------------------------------
    # ALT TEXT
    # -----------------------------------------------------

    alt_text = request.form.get(

        "alt_text",

        product.name
    )

    # -----------------------------------------------------
    # CREATE IMAGE RECORD
    # -----------------------------------------------------

    image = ProductImage(

        product_id=product_id,

        image_url=image_url,

        alt_text=alt_text,

        is_primary=is_primary,

        display_order=existing_image_count
    )

    db.session.add(
        image
    )

    db.session.commit()

    return jsonify({

        "status": "success",

        "message": (
            "Product image uploaded successfully"
        ),

        "image": product_image_to_dict(
            image
        ),

        "product": product_to_dict(
            product
        )

    }), 201


# =========================================================
# PRODUCT IMAGE
# SET PRIMARY
# =========================================================

@admin_bp.put(
    "/products/<int:product_id>/images/<int:image_id>/primary"
)
def set_primary_product_image(
    product_id,
    image_id
):

    product = db.session.get(
        Product,
        product_id
    )

    if not product:

        return jsonify({

            "status": "error",

            "message": "Product not found"

        }), 404

    image = ProductImage.query.filter_by(

        id=image_id,

        product_id=product_id

    ).first()

    if not image:

        return jsonify({

            "status": "error",

            "message": "Product image not found"

        }), 404

    # -----------------------------------------------------
    # REMOVE PRIMARY FROM OTHER IMAGES
    # -----------------------------------------------------

    ProductImage.query.filter_by(

        product_id=product_id

    ).update({

        "is_primary": False
    })

    # -----------------------------------------------------
    # SET PRIMARY
    # -----------------------------------------------------

    image.is_primary = True

    product.image = image.image_url

    db.session.commit()

    return jsonify({

        "status": "success",

        "message": (
            "Primary product image updated successfully"
        ),

        "image": product_image_to_dict(
            image
        )

    })


# =========================================================
# PRODUCT IMAGE
# DELETE
# =========================================================

@admin_bp.delete(
    "/products/<int:product_id>/images/<int:image_id>"
)
def delete_product_image(
    product_id,
    image_id
):

    product = db.session.get(
        Product,
        product_id
    )

    if not product:

        return jsonify({

            "status": "error",

            "message": "Product not found"

        }), 404

    image = ProductImage.query.filter_by(

        id=image_id,

        product_id=product_id

    ).first()

    if not image:

        return jsonify({

            "status": "error",

            "message": "Product image not found"

        }), 404

    was_primary = image.is_primary

    image_url = image.image_url

    # -----------------------------------------------------
    # DELETE DATABASE RECORD
    # -----------------------------------------------------

    db.session.delete(
        image
    )

    # -----------------------------------------------------
    # IF PRIMARY, SELECT NEW PRIMARY
    # -----------------------------------------------------

    if was_primary:

        remaining_images = (

            ProductImage.query
            .filter(

                ProductImage.product_id
                == product_id,

                ProductImage.id
                != image_id

            )
            .order_by(

                ProductImage.display_order.asc(),

                ProductImage.id.asc()

            )
            .all()
        )

        if remaining_images:

            new_primary = (
                remaining_images[0]
            )

            new_primary.is_primary = True

            product.image = (
                new_primary.image_url
            )

        else:

            product.image = None

    db.session.commit()

    # -----------------------------------------------------
    # DELETE PHYSICAL FILE
    # -----------------------------------------------------

    if (
        image_url
        and image_url.startswith(
            "/uploads/products/"
        )
    ):

        filename = os.path.basename(
            image_url
        )

        physical_file = os.path.join(

            Config.PRODUCT_UPLOAD_FOLDER,

            filename
        )

        if os.path.isfile(
            physical_file
        ):

            try:

                os.remove(
                    physical_file
                )

            except OSError:

                pass

    return jsonify({

        "status": "success",

        "message": (
            "Product image deleted successfully"
        )

    })