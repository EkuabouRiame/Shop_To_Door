from flask import Flask
from flask_cors import CORS

from .config import Config
from .extensions import db, migrate, jwt, mail


def create_app():
    app = Flask(__name__)

    # =====================================================
    # LOAD CONFIGURATION
    # =====================================================

    app.config.from_object(Config)

    # =====================================================
    # INITIALIZE DATABASE
    # =====================================================

    db.init_app(app)

    # =====================================================
    # INITIALIZE DATABASE MIGRATIONS
    # =====================================================

    migrate.init_app(app, db)

    # =====================================================
    # INITIALIZE JWT AUTHENTICATION
    # =====================================================

    jwt.init_app(app)

    # =====================================================
    # INITIALIZE EMAIL
    # =====================================================

    mail.init_app(app)

    # =====================================================
    # ENABLE CORS
    # Allow React frontend to communicate with Flask API
    # =====================================================

    CORS(
        app,
        resources={
            r"/api/*": {
                "origins": [
                    "http://localhost:5173",
                    "http://127.0.0.1:5173",
                    "http://localhost:5174",
                    "http://127.0.0.1:5174",
                    "http://localhost:3000",
                ],
                "methods": [
                    "GET",
                    "POST",
                    "PUT",
                    "PATCH",
                    "DELETE",
                    "OPTIONS",
                ],
                "allow_headers": [
                    "Content-Type",
                    "Authorization",
                ],
                "supports_credentials": True,
            }
        },
    )

    # =====================================================
    # IMPORT ROUTE BLUEPRINTS
    # =====================================================

    from .routes.products import products_bp
    from .routes.categories import categories_bp
    from .routes.cart import cart_bp
    from .routes.orders import orders_bp
    from .routes.auth import auth_bp
    from .routes.admin import admin_bp
    from .routes.admin_orders import admin_orders_bp
    from .routes.users import users_bp
    from .routes.uploads import uploads_bp
    from app.routes.payments import payments_bp

    # QR DELIVERY CONFIRMATION
    from .routes.delivery_confirmation import delivery_confirmation_bp

    # =====================================================
    # REGISTER ROUTE BLUEPRINTS
    # =====================================================

    app.register_blueprint(products_bp)
    app.register_blueprint(categories_bp)
    app.register_blueprint(cart_bp)
    app.register_blueprint(orders_bp)
    app.register_blueprint(auth_bp)
    app.register_blueprint(admin_bp)
    app.register_blueprint(admin_orders_bp)
    app.register_blueprint(users_bp)
    app.register_blueprint(uploads_bp)
    app.register_blueprint(payments_bp)

    # QR DELIVERY CONFIRMATION
    app.register_blueprint(delivery_confirmation_bp)

    # =====================================================
    # RETURN APPLICATION
    # =====================================================

    return app