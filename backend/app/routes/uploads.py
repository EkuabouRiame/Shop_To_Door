from io import BytesIO

from flask import Blueprint, jsonify, send_file
from werkzeug.utils import secure_filename

from ..media_storage import download_image


uploads_bp = Blueprint(
    "uploads",
    __name__,
    url_prefix="/uploads",
)

ALLOWED_IMAGE_TYPES = {
    "image/jpeg",
    "image/png",
    "image/webp",
    "image/gif",
}


def serve_image(folder, filename):
    safe_filename = secure_filename(filename)

    if not safe_filename or safe_filename != filename:
        return jsonify({
            "status": "error",
            "message": "Invalid image filename",
        }), 400

    try:
        result = download_image(folder, safe_filename)
    except Exception:
        from flask import current_app
        current_app.logger.exception(
            "Unable to read image from Cloud Storage"
        )
        return jsonify({
            "status": "error",
            "message": "Unable to load image",
        }), 500

    if result is None:
        return jsonify({
            "status": "error",
            "message": "Image not found",
            "filename": safe_filename,
        }), 404

    data, content_type = result
    content_type = content_type.lower().split(";")[0].strip()

    if content_type not in ALLOWED_IMAGE_TYPES:
        return jsonify({
            "status": "error",
            "message": "Unsupported image type",
        }), 415

    response = send_file(
        BytesIO(data),
        mimetype=content_type,
        max_age=3600,
    )
    response.headers["X-Content-Type-Options"] = "nosniff"

    return response


@uploads_bp.get("/products/<path:filename>")
def product_image(filename):
    return serve_image("products", filename)


@uploads_bp.get("/categories/<path:filename>")
def category_image(filename):
    return serve_image("categories", filename)
