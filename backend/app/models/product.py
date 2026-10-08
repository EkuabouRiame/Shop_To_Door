from datetime import datetime

from ..extensions import db


class Product(db.Model):
    __tablename__ = "products"

    # =========================================================
    # PRIMARY KEY
    # =========================================================

    id = db.Column(
        db.Integer,
        primary_key=True
    )

    # =========================================================
    # PRODUCT INFORMATION
    # =========================================================

    name = db.Column(
        db.String(255),
        nullable=False,
        index=True
    )

    slug = db.Column(
        db.String(300),
        unique=True,
        nullable=False,
        index=True
    )

    sku = db.Column(
        db.String(100),
        unique=True,
        nullable=False,
        index=True
    )

    description = db.Column(
        db.Text,
        nullable=True
    )

    brand = db.Column(
        db.String(120),
        nullable=True
    )

    # =========================================================
    # PRICE
    # =========================================================

    price = db.Column(
        db.Numeric(12, 2),
        nullable=False
    )

    discount_price = db.Column(
        db.Numeric(12, 2),
        nullable=True
    )

    # =========================================================
    # INVENTORY
    # =========================================================

    stock = db.Column(
        db.Integer,
        nullable=False,
        default=0
    )

    # =========================================================
    # CATEGORY
    # =========================================================

    category_id = db.Column(
        db.Integer,
        db.ForeignKey("categories.id"),
        nullable=False,
        index=True
    )

    # =========================================================
    # MAIN PRODUCT IMAGE
    # =========================================================

    image = db.Column(
        db.String(500),
        nullable=True
    )

    # =========================================================
    # STATUS
    # =========================================================

    is_active = db.Column(
        db.Boolean,
        default=True,
        nullable=False
    )

    is_featured = db.Column(
        db.Boolean,
        default=False,
        nullable=False
    )

    # =========================================================
    # RATINGS & REVIEWS
    # =========================================================

    rating = db.Column(
        db.Numeric(3, 2),
        default=0,
        nullable=False
    )

    review_count = db.Column(
        db.Integer,
        default=0,
        nullable=False
    )

    # =========================================================
    # TIMESTAMPS
    # =========================================================

    created_at = db.Column(
        db.DateTime,
        default=datetime.utcnow,
        nullable=False
    )

    updated_at = db.Column(
        db.DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
        nullable=False
    )

    # =========================================================
    # CATEGORY RELATIONSHIP
    # =========================================================

    category = db.relationship(
        "Category",
        backref=db.backref(
            "products",
            lazy=True
        )
    )

    # =========================================================
    # PRODUCT IMAGES RELATIONSHIP
    # =========================================================

    images = db.relationship(
        "ProductImage",
        back_populates="product",
        cascade="all, delete-orphan",
        lazy=True
    )

    # =========================================================
    # REPRESENTATION
    # =========================================================

    def __repr__(self):
        return f"<Product {self.name}>"