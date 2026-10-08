from datetime import datetime

from werkzeug.security import (
    generate_password_hash,
    check_password_hash
)

from ..extensions import db


class User(db.Model):

    __tablename__ = "users"

    # =========================================================
    # PRIMARY KEY
    # =========================================================

    id = db.Column(
        db.Integer,
        primary_key=True
    )

    # =========================================================
    # USER INFORMATION
    # =========================================================

    name = db.Column(
        db.String(120),
        nullable=False
    )

    email = db.Column(
        db.String(255),
        unique=True,
        nullable=False,
        index=True
    )

    phone = db.Column(
        db.String(20),
        unique=True,
        nullable=True
    )

    # =========================================================
    # PASSWORD
    # =========================================================

    password_hash = db.Column(
        db.String(255),
        nullable=False
    )

    # =========================================================
    # ROLE
    # =========================================================

    role = db.Column(
        db.String(20),
        nullable=False,
        default="customer"
    )

    # =========================================================
    # STATUS
    # =========================================================

    is_active = db.Column(
        db.Boolean,
        default=True,
        nullable=False
    )

    # =========================================================
    # USER LOCATION
    # =========================================================

    latitude = db.Column(
        db.Float,
        nullable=True
    )

    longitude = db.Column(
        db.Float,
        nullable=True
    )

    address = db.Column(
        db.String(500),
        nullable=True
    )

    city = db.Column(
        db.String(120),
        nullable=True
    )

    state = db.Column(
        db.String(120),
        nullable=True
    )

    pincode = db.Column(
        db.String(20),
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
    # PASSWORD METHODS
    # =========================================================

    def set_password(self, password):

        self.password_hash = generate_password_hash(
            password
        )

    def check_password(self, password):

        return check_password_hash(
            self.password_hash,
            password
        )

    # =========================================================
    # REPRESENTATION
    # =========================================================

    def __repr__(self):

        return f"<User {self.email}>"