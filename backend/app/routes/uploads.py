import os

from flask import (
    Blueprint,
    send_from_directory,
    jsonify
)

from ..config import Config


# =========================================================
# UPLOADS BLUEPRINT
# =========================================================

uploads_bp = Blueprint(
    "uploads",
    __name__,
    url_prefix="/uploads"
)


# =========================================================
# PRODUCT IMAGE
# =========================================================

@uploads_bp.get("/products/<path:filename>")
def product_image(filename):

    upload_folder = Config.PRODUCT_UPLOAD_FOLDER

    os.makedirs(
        upload_folder,
        exist_ok=True
    )

    file_path = os.path.join(
        upload_folder,
        filename
    )

    upload_folder_abs = os.path.abspath(
        upload_folder
    )

    file_path_abs = os.path.abspath(
        file_path
    )

    if not file_path_abs.startswith(
        upload_folder_abs + os.sep
    ):
        return jsonify({
            "status": "error",
            "message": "Invalid image path"
        }), 400

    if not os.path.isfile(file_path_abs):
        return jsonify({
            "status": "error",
            "message": "Image not found",
            "filename": filename
        }), 404

    return send_from_directory(
        upload_folder,
        filename
    )


# =========================================================
# CATEGORY IMAGE
# =========================================================

@uploads_bp.get("/categories/<path:filename>")
def category_image(filename):

    upload_folder = Config.CATEGORY_UPLOAD_FOLDER

    os.makedirs(
        upload_folder,
        exist_ok=True
    )

    file_path = os.path.join(
        upload_folder,
        filename
    )

    upload_folder_abs = os.path.abspath(
        upload_folder
    )

    file_path_abs = os.path.abspath(
        file_path
    )

    if not file_path_abs.startswith(
        upload_folder_abs + os.sep
    ):
        return jsonify({
            "status": "error",
            "message": "Invalid category image path"
        }), 400

    if not os.path.isfile(file_path_abs):
        return jsonify({
            "status": "error",
            "message": "Category image not found",
            "filename": filename
        }), 404

    return send_from_directory(
        upload_folder,
        filename
    )