from datetime import datetime

from ..extensions import db


class Category(db.Model):
    __tablename__ = "categories"

    # =========================================
    # PRIMARY KEY
    # =========================================

    id = db.Column(
        db.Integer,
        primary_key=True
    )

    # =========================================
    # CATEGORY INFORMATION
    # =========================================

    name = db.Column(
        db.String(255),
        nullable=False,
        unique=True,
        index=True
    )

    slug = db.Column(
        db.String(300),
        nullable=False,
        unique=True,
        index=True
    )

    description = db.Column(
        db.Text,
        nullable=True
    )

    image = db.Column(
        db.String(500),
        nullable=True
    )

    # =========================================
    # STATUS
    # =========================================

    is_active = db.Column(
        db.Boolean,
        default=True,
        nullable=False
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
    # REPRESENTATION
    # =========================================

    def __repr__(self):
        return f"<Category {self.name}>"