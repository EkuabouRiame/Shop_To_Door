from flask import Blueprint, jsonify

from ..extensions import db
from ..models import Category, Product


categories_bp = Blueprint(
    "categories",
    __name__,
    url_prefix="/api/categories"
)


# =========================================================
# CATEGORY SERIALIZER
# =========================================================

def category_to_dict(category, include_products=False):

    data = {
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

    if include_products:

        products = (
            db.session.query(Product)
            .filter(
                Product.category_id == category.id,
                Product.is_active.is_(True)
            )
            .order_by(Product.created_at.desc())
            .all()
        )

        data["products"] = [
            {
                "id": product.id,
                "name": product.name,
                "slug": product.slug,
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
                "image": product.image,
                "is_featured": product.is_featured,

                "rating": (
                    float(product.rating)
                    if product.rating is not None
                    else 0
                ),

                "review_count": product.review_count
            }
            for product in products
        ]

    return data


# =========================================================
# GET ALL ACTIVE CATEGORIES
# =========================================================

@categories_bp.get("/")
def get_categories():

    categories = (
        db.session.query(Category)
        .filter(Category.is_active.is_(True))
        .order_by(Category.name.asc())
        .all()
    )

    return jsonify({
        "status": "success",
        "count": len(categories),
        "categories": [
            category_to_dict(category)
            for category in categories
        ]
    }), 200


# =========================================================
# GET SINGLE CATEGORY
# =========================================================

@categories_bp.get("/<int:category_id>")
def get_category(category_id):

    category = (
        db.session.query(Category)
        .filter(
            Category.id == category_id,
            Category.is_active.is_(True)
        )
        .first()
    )

    if not category:
        return jsonify({
            "status": "error",
            "message": "Category not found"
        }), 404

    return jsonify({
        "status": "success",
        "category": category_to_dict(category)
    }), 200


# =========================================================
# GET CATEGORY PRODUCTS
# =========================================================

@categories_bp.get("/<int:category_id>/products")
def get_category_products(category_id):

    category = (
        db.session.query(Category)
        .filter(
            Category.id == category_id,
            Category.is_active.is_(True)
        )
        .first()
    )

    if not category:
        return jsonify({
            "status": "error",
            "message": "Category not found"
        }), 404

    return jsonify({
        "status": "success",
        "category": category_to_dict(
            category,
            include_products=True
        )
    }), 200