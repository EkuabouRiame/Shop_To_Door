from datetime import datetime

from ..extensions import db


class OrderItem(db.Model):
    __tablename__ = "order_items"

    id = db.Column(
        db.Integer,
        primary_key=True
    )

    order_id = db.Column(
        db.Integer,
        db.ForeignKey("orders.id"),
        nullable=False,
        index=True
    )

    product_id = db.Column(
    db.Integer,
    db.ForeignKey(
        "products.id",
        ondelete="SET NULL"
    ),
    nullable=True,
    index=True
    )

    product_name = db.Column(
        db.String(255),
        nullable=False
    )

    product_sku = db.Column(
        db.String(100),
        nullable=True
    )

    quantity = db.Column(
        db.Integer,
        nullable=False
    )

    unit_price = db.Column(
        db.Numeric(12, 2),
        nullable=False
    )

    total_price = db.Column(
        db.Numeric(12, 2),
        nullable=False
    )

    created_at = db.Column(
        db.DateTime,
        default=datetime.utcnow,
        nullable=False
    )

    # =========================================
    # RELATIONSHIPS
    # =========================================

    order = db.relationship(
        "Order",
        back_populates="items"
    )

    product = db.relationship(
        "Product"
    )

    def __repr__(self):
        return f"<OrderItem {self.id}>"