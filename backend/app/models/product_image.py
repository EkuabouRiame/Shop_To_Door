from datetime import datetime

from ..extensions import db


class ProductImage(db.Model):
    __tablename__ = "product_images"

    # =========================================================
    # PRIMARY KEY
    # =========================================================

    id = db.Column(
        db.Integer,
        primary_key=True
    )

    # =========================================================
    # PRODUCT RELATIONSHIP
    # =========================================================

    product_id = db.Column(
        db.Integer,
        db.ForeignKey(
            "products.id",
            ondelete="CASCADE"
        ),
        nullable=False,
        index=True
    )

    # =========================================================
    # IMAGE INFORMATION
    # =========================================================

    image_url = db.Column(
        db.String(500),
        nullable=False
    )

    alt_text = db.Column(
        db.String(255),
        nullable=True
    )

    # =========================================================
    # IMAGE STATUS
    # =========================================================

    is_primary = db.Column(
        db.Boolean,
        default=False,
        nullable=False
    )

    display_order = db.Column(
        db.Integer,
        default=0,
        nullable=False
    )

    # =========================================================
    # TIMESTAMP
    # =========================================================

    created_at = db.Column(
        db.DateTime,
        default=datetime.utcnow,
        nullable=False
    )

    # =========================================================
    # PRODUCT RELATIONSHIP
    # =========================================================

    product = db.relationship(
        "Product",
        back_populates="images"
    )

    # =========================================================
    # REPRESENTATION
    # =========================================================

    def __repr__(self):
        return f"<ProductImage {self.id}>"