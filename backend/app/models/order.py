from datetime import datetime

from ..extensions import db


class Order(db.Model):
    __tablename__ = "orders"

    # =========================================================
    # PRIMARY KEY
    # =========================================================

    id = db.Column(
        db.Integer,
        primary_key=True
    )

    # =========================================================
    # CUSTOMER
    # =========================================================

    user_id = db.Column(
        db.Integer,
        db.ForeignKey("users.id"),
        nullable=False,
        index=True
    )

    # =========================================================
    # DELIVERY PERSON
    # =========================================================

    delivery_person_id = db.Column(
        db.Integer,
        db.ForeignKey("users.id"),
        nullable=True,
        index=True
    )

    # =========================================================
    # ORDER STATUS
    # =========================================================

    status = db.Column(
        db.String(30),
        nullable=False,
        default="pending"
    )

    # =========================================================
    # PAYMENT
    # =========================================================

    payment_status = db.Column(
        db.String(30),
        nullable=False,
        default="pending"
    )

    payment_method = db.Column(
        db.String(30),
        nullable=False,
        default="cod"
    )
    # =========================================================
    # RAZORPAY
    # =========================================================

    razorpay_order_id = db.Column(
        db.String(100),
        nullable=True,
        unique=True,
        index=True
    )

    razorpay_payment_id = db.Column(
        db.String(100),
        nullable=True,
        unique=True,
        index=True
    )

    razorpay_signature = db.Column(
        db.String(255),
        nullable=True
    )
    # =========================================================
    # PRICE
    # =========================================================

    subtotal = db.Column(
        db.Numeric(12, 2),
        nullable=False,
        default=0
    )

    shipping_fee = db.Column(
        db.Numeric(12, 2),
        nullable=False,
        default=0
    )

    discount = db.Column(
        db.Numeric(12, 2),
        nullable=False,
        default=0
    )

    total_amount = db.Column(
        db.Numeric(12, 2),
        nullable=False,
        default=0
    )

    # =========================================================
    # SHIPPING / DELIVERY ADDRESS
    # =========================================================

    shipping_name = db.Column(
        db.String(120),
        nullable=False
    )

    shipping_phone = db.Column(
        db.String(20),
        nullable=False
    )

    shipping_address = db.Column(
        db.Text,
        nullable=False
    )

    shipping_city = db.Column(
        db.String(100),
        nullable=False
    )

    shipping_state = db.Column(
        db.String(100),
        nullable=False
    )

    shipping_pincode = db.Column(
        db.String(10),
        nullable=False
    )

    # =========================================================
    # NOTES
    # =========================================================

    notes = db.Column(
        db.Text,
        nullable=True
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
    # CUSTOMER RELATIONSHIP
    # =========================================================

    user = db.relationship(
        "User",
        foreign_keys=[user_id],
        backref=db.backref(
            "orders",
            lazy=True
        )
    )

    # =========================================================
    # DELIVERY PERSON RELATIONSHIP
    # =========================================================

    delivery_person = db.relationship(
        "User",
        foreign_keys=[delivery_person_id],
        backref=db.backref(
            "assigned_orders",
            lazy=True
        )
    )

    # =========================================================
    # ORDER ITEMS
    # =========================================================

    items = db.relationship(
        "OrderItem",
        back_populates="order",
        cascade="all, delete-orphan",
        lazy=True
    )

    # =========================================================
    # REPRESENTATION
    # =========================================================

    def __repr__(self):
        return f"<Order {self.id}>"