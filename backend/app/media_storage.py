
import os
import re

from google.cloud import storage
from google.api_core.exceptions import NotFound
from PIL import Image, UnidentifiedImageError


ALLOWED_FOLDERS = {"products", "categories"}

CONTENT_TYPES = {
    "JPEG": "image/jpeg",
    "PNG": "image/png",
    "WEBP": "image/webp",
}


def validate_object_path(folder, filename):
    if folder not in ALLOWED_FOLDERS:
        raise ValueError("Invalid storage folder")

    if (
        not filename
        or filename in {".", ".."}
        or not re.fullmatch(r"[A-Za-z0-9_.-]+", filename)
    ):
        raise ValueError("Invalid image filename")


def get_media_bucket():
    bucket_name = (
        os.getenv("GCS_BUCKET_NAME")
        or "shop-to-door-media-510917"
    )

    return storage.Client().bucket(bucket_name)


def upload_image(file_storage, folder, filename):
    validate_object_path(folder, filename)

    file_storage.stream.seek(0)

    try:
        with Image.open(file_storage.stream) as image:
            image_format = image.format
            image.verify()
    except (UnidentifiedImageError, OSError, ValueError) as error:
        raise ValueError("Invalid or corrupted image") from error
    finally:
        file_storage.stream.seek(0)

    content_type = CONTENT_TYPES.get(image_format)

    if not content_type:
        raise ValueError("Unsupported image format")

    blob = get_media_bucket().blob(f"{folder}/{filename}")

    blob.upload_from_file(
        file_storage.stream,
        content_type=content_type,
    )

    return f"/uploads/{folder}/{filename}"


def download_image(folder, filename):
    validate_object_path(folder, filename)

    blob = get_media_bucket().blob(f"{folder}/{filename}")

    try:
        data = blob.download_as_bytes()
    except NotFound:
        return None

    return data, blob.content_type or "application/octet-stream"


def delete_image(folder, filename):
    validate_object_path(folder, filename)

    blob = get_media_bucket().blob(f"{folder}/{filename}")

    try:
        blob.delete()
    except NotFound:
        pass
