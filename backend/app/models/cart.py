from datetime import datetime

from ..extensions import db


class Cart(db.Model):

    __tablename__ = "carts"

    # =========================================
    # PRIMARY KEY
    # =========================================

    id = db.Column(
        db.Integer,
        primary_key=True
    )

    # =========================================
    # USER
    # =========================================

    user_id = db.Column(
        db.Integer,
        db.ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
        index=True
    )

    # =========================================
    # TIMESTAMPS
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

    user = db.relationship(
        "User",
        backref=db.backref(
            "cart",
            uselist=False,
            cascade="all, delete-orphan"
        )
    )

    items = db.relationship(
        "CartItem",
        back_populates="cart",
        cascade="all, delete-orphan",
        lazy=True
    )

    # =========================================
    # REPRESENTATION
    # =========================================

    def __repr__(self):

        return f"<Cart {self.id}>"