from datetime import datetime

from ..extensions import db


class CartItem(db.Model):

    __tablename__ = "cart_items"

    # =========================================
    # PRIMARY KEY
    # =========================================

    id = db.Column(
        db.Integer,
        primary_key=True
    )

    # =========================================
    # CART
    # =========================================

    cart_id = db.Column(
        db.Integer,
        db.ForeignKey("carts.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # =========================================
    # PRODUCT
    # =========================================

    product_id = db.Column(
        db.Integer,
        db.ForeignKey("products.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # =========================================
    # QUANTITY
    # =========================================

    quantity = db.Column(
        db.Integer,
        nullable=False,
        default=1
    )

    # =========================================
    # TIMESTAMP
    # =========================================

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

    # =========================================
    # RELATIONSHIPS
    # =========================================

    cart = db.relationship(
        "Cart",
        back_populates="items"
    )

    product = db.relationship(
        "Product"
    )

    # =========================================
    # REPRESENTATION
    # =========================================

    def __repr__(self):

        return f"<CartItem {self.id}>"