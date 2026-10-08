from flask import Blueprint, jsonify, request

from ..extensions import db
from ..models import Product


products_bp = Blueprint(
    "products",
    __name__,
    url_prefix="/api/products"
)


# =========================================================
# PRODUCT SERIALIZER
# =========================================================

def product_to_dict(product):

    return {
        "id": product.id,
        "name": product.name,
        "slug": product.slug,
        "sku": product.sku,
        "description": product.description,
        "brand": product.brand,

        # =================================================
        # PRICE
        # =================================================

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

        # =================================================
        # INVENTORY
        # =================================================

        "stock": product.stock,

        # =================================================
        # CATEGORY
        # =================================================

        "category_id": product.category_id,

        "category": (
            {
                "id": product.category.id,
                "name": product.category.name,
                "slug": product.category.slug
            }
            if product.category
            else None
        ),

        # =================================================
        # IMAGE
        # =================================================

        "image": product.image,

        # =================================================
        # STATUS
        # =================================================

        "is_active": product.is_active,
        "is_featured": product.is_featured,

        # =================================================
        # RATING
        # =================================================

        "rating": (
            float(product.rating)
            if product.rating is not None
            else 0
        ),

        "review_count": product.review_count,

        # =================================================
        # TIMESTAMPS
        # =================================================

        "created_at": (
            product.created_at.isoformat()
            if product.created_at
            else None
        ),

        "updated_at": (
            product.updated_at.isoformat()
            if product.updated_at
            else None
        ),

        # =================================================
        # PRODUCT IMAGES
        # =================================================

        "images": [
            {
                "id": image.id,
                "image_url": image.image_url,
                "alt_text": image.alt_text,
                "is_primary": image.is_primary,
                "display_order": image.display_order
            }
            for image in sorted(
                product.images,
                key=lambda x: x.display_order
            )
        ]
    }


# =========================================================
# GET ALL PRODUCTS
# =========================================================

@products_bp.get("/")
def get_products():

    # =====================================================
    # QUERY PARAMETERS
    # =====================================================

    search = request.args.get(
        "search",
        "",
        type=str
    ).strip()

    category_id = request.args.get(
        "category_id",
        type=int
    )

    brand = request.args.get(
        "brand",
        "",
        type=str
    ).strip()

    featured = request.args.get(
        "featured",
        type=str
    )

    in_stock = request.args.get(
        "in_stock",
        type=str
    )

    min_price = request.args.get(
        "min_price",
        type=float
    )

    max_price = request.args.get(
        "max_price",
        type=float
    )

    sort = request.args.get(
        "sort",
        "newest",
        type=str
    ).strip().lower()

    page = request.args.get(
        "page",
        1,
        type=int
    )

    per_page = request.args.get(
        "per_page",
        20,
        type=int
    )

    # =====================================================
    # SAFETY LIMITS
    # =====================================================

    if page < 1:
        page = 1

    if per_page < 1:
        per_page = 20

    if per_page > 100:
        per_page = 100

    # =====================================================
    # BASE QUERY
    # =====================================================

    query = (
        db.session.query(Product)
        .filter(
            Product.is_active.is_(True)
        )
    )

    # =====================================================
    # SEARCH FILTER
    # =====================================================

    if search:

        search_pattern = f"%{search}%"

        query = query.filter(
            db.or_(
                Product.name.ilike(search_pattern),
                Product.description.ilike(search_pattern),
                Product.brand.ilike(search_pattern),
                Product.sku.ilike(search_pattern)
            )
        )

    # =====================================================
    # CATEGORY FILTER
    # =====================================================

    if category_id is not None:

        query = query.filter(
            Product.category_id == category_id
        )

    # =====================================================
    # BRAND FILTER
    # =====================================================

    if brand:

        query = query.filter(
            Product.brand.ilike(brand)
        )

    # =====================================================
    # FEATURED FILTER
    # =====================================================

    if featured is not None:

        if featured.lower() == "true":

            query = query.filter(
                Product.is_featured.is_(True)
            )

        elif featured.lower() == "false":

            query = query.filter(
                Product.is_featured.is_(False)
            )

    # =====================================================
    # STOCK FILTER
    # =====================================================

    if in_stock is not None:

        if in_stock.lower() == "true":

            query = query.filter(
                Product.stock > 0
            )

        elif in_stock.lower() == "false":

            query = query.filter(
                Product.stock <= 0
            )

    # =====================================================
    # MINIMUM PRICE FILTER
    # =====================================================

    if min_price is not None:

        query = query.filter(
            Product.price >= min_price
        )

    # =====================================================
    # MAXIMUM PRICE FILTER
    # =====================================================

    if max_price is not None:

        query = query.filter(
            Product.price <= max_price
        )

    # =====================================================
    # TOTAL COUNT
    # =====================================================

    total = query.count()

    # =====================================================
    # SORTING
    # =====================================================

    if sort == "price_low":

        query = query.order_by(
            Product.price.asc()
        )

    elif sort == "price_high":

        query = query.order_by(
            Product.price.desc()
        )

    elif sort == "name":

        query = query.order_by(
            Product.name.asc()
        )

    elif sort == "oldest":

        query = query.order_by(
            Product.created_at.asc()
        )

    else:

        # Default: newest first
        query = query.order_by(
            Product.created_at.desc()
        )

    # =====================================================
    # PAGINATION
    # =====================================================

    products = (
        query
        .offset(
            (page - 1) * per_page
        )
        .limit(per_page)
        .all()
    )

    # =====================================================
    # TOTAL PAGES
    # =====================================================

    total_pages = (
        (total + per_page - 1) // per_page
        if total > 0
        else 0
    )

    # =====================================================
    # RESPONSE
    # =====================================================

    return jsonify({
        "status": "success",

        "pagination": {
            "page": page,
            "per_page": per_page,
            "total": total,
            "total_pages": total_pages
        },

        "products": [
            product_to_dict(product)
            for product in products
        ]
    }), 200


# =========================================================
# GET SINGLE PRODUCT
# =========================================================

@products_bp.get("/<int:product_id>")
def get_product(product_id):

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

    return jsonify({
        "status": "success",
        "product": product_to_dict(product)
    }), 200