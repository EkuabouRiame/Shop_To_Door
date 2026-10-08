import razorpay
from flask import current_app


def get_razorpay_client():
    key_id = current_app.config.get("RAZORPAY_KEY_ID")
    key_secret = current_app.config.get("RAZORPAY_KEY_SECRET")

    if not key_id or not key_secret:
        raise RuntimeError(
            "Razorpay credentials are not configured."
        )

    return razorpay.Client(
        auth=(key_id, key_secret)
    )