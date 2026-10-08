import os

from dotenv import load_dotenv


load_dotenv()


class Config:

    # =========================================
    # APPLICATION
    # =========================================

    SECRET_KEY = os.getenv(
        "SECRET_KEY",
        "shop-to-door-development-key"
    )

    # =========================================
    # DATABASE
    # =========================================

    SQLALCHEMY_DATABASE_URI = os.getenv(
        "DATABASE_URL",
    )

    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # =========================================
    # JWT
    # =========================================

    JWT_SECRET_KEY = os.getenv(
        "JWT_SECRET_KEY",
        "shop-to-door-jwt-development-key"
    )

    JWT_ACCESS_TOKEN_EXPIRES = 60 * 60 * 24

    # =========================================
    # RAZORPAY
    # =========================================

    RAZORPAY_KEY_ID = os.getenv(
        "RAZORPAY_KEY_ID",
        ""
    )

    RAZORPAY_KEY_SECRET = os.getenv(
        "RAZORPAY_KEY_SECRET",
        ""
    )
    
    # =========================================
    # EMAIL / PASSWORD RESET
    # =========================================

    MAIL_SERVER = os.getenv(
        "MAIL_SERVER",
        "smtp.gmail.com"
    )

    MAIL_PORT = int(os.getenv(
        "MAIL_PORT",
        "587"
    ))

    MAIL_USE_TLS = os.getenv(
        "MAIL_USE_TLS",
        "true"
    ).lower() == "true"

    MAIL_USERNAME = os.getenv(
        "MAIL_USERNAME",
        ""
    )

    MAIL_PASSWORD = os.getenv(
        "MAIL_PASSWORD",
        ""
    )

    MAIL_DEFAULT_SENDER = os.getenv(
        "MAIL_DEFAULT_SENDER",
        ""
    )
    # =========================================
    # BASE DIRECTORY
    # =========================================

    BASE_DIR = os.path.dirname(
        os.path.dirname(
            os.path.dirname(
                os.path.abspath(__file__)
            )
        )
    )

    # =========================================
    # PRODUCT IMAGE UPLOAD FOLDER
    # =========================================

    PRODUCT_UPLOAD_FOLDER = os.path.join(
        BASE_DIR,
        "uploads",
        "products"
    )

    # =========================================
    # CATEGORY IMAGE UPLOAD FOLDER
    # =========================================

    CATEGORY_UPLOAD_FOLDER = os.path.join(
        BASE_DIR,
        "uploads",
        "categories"
    )

    # =========================================
    # ALLOWED IMAGE TYPES
    # =========================================

    ALLOWED_IMAGE_EXTENSIONS = {
        "jpg",
        "jpeg",
        "png",
        "webp"
    }