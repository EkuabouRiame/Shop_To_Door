import React, {
  useEffect,
  useRef,
  useState,
} from "react";

import { Html5Qrcode } from "html5-qrcode";

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL ||
  "https://shop-to-door-backend-294288480400.asia-south2.run.app/api";

function DeliveryConfirmation() {
  const scannerInstanceRef = useRef(null);
  const scanLockedRef = useRef(false);

  const [qrToken, setQrToken] = useState("");
  const [loading, setLoading] = useState(false);
  const [confirming, setConfirming] = useState(false);

  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  const [order, setOrder] = useState(null);
  const [scanning, setScanning] = useState(false);

  // =========================================================
  // STOP SCANNER
  // =========================================================

  async function stopScanner() {
    const scanner =
      scannerInstanceRef.current;

    if (!scanner) {
      setScanning(false);
      return;
    }

    try {
      const state = scanner.getState();

      if (state === 2 || state === 3) {
        await scanner.stop();
      }
    } catch (err) {
      console.log(
        "Scanner stop:",
        err
      );
    }

    try {
      await scanner.clear();
    } catch (err) {
      console.log(
        "Scanner clear:",
        err
      );
    }

    scannerInstanceRef.current = null;

    setScanning(false);
  }

  // =========================================================
  // EXTRACT TOKEN FROM QR
  // =========================================================

  function extractToken(decodedText) {
    let token = "";

    try {
      const url = new URL(decodedText);

      const match =
        url.pathname.match(
          /\/delivery-confirmation\/([^/]+)/
        );

      if (match) {
        token = match[1];
      }
    } catch {
      // QR may contain only the token.
      token = decodedText.trim();
    }

    return token;
  }

  // =========================================================
  // CHECK QR WITH BACKEND
  // =========================================================

  async function processQrToken(token) {
    if (!token) {
      throw new Error(
        "Invalid delivery QR code."
      );
    }

    console.log(
      "Delivery token:",
      token
    );

    setQrToken(token);

    const response = await fetch(
      `${API_BASE_URL}/orders/delivery-confirmation/${encodeURIComponent(
        token
      )}`
    );

    const data =
      await response.json();

    console.log(
      "Delivery QR response:",
      data
    );

    if (!response.ok) {
      throw new Error(
        data.message ||
          "This delivery QR code is invalid or expired."
      );
    }

    setOrder(data);

    return data;
  }

  // =========================================================
  // PROCESS QR CODE
  // =========================================================

  async function processQrCode(decodedText) {
    setLoading(true);
    setError("");
    setMessage("");

    try {
      const token =
        extractToken(decodedText);

      if (!token) {
        throw new Error(
          "Invalid delivery QR code."
        );
      }

      await processQrToken(token);

    } catch (err) {
      console.error(
        "QR processing error:",
        err
      );

      setError(
        err.message ||
          "Unable to read the delivery QR code."
      );
    } finally {
      setLoading(false);
    }
  }

  // =========================================================
  // START SCANNER
  // =========================================================

  async function startScanner() {
    setError("");
    setMessage("");

    setOrder(null);
    setQrToken("");

    scanLockedRef.current = false;

    await stopScanner();

    const scanner =
      new Html5Qrcode(
        "delivery-qr-reader"
      );

    scannerInstanceRef.current =
      scanner;

    try {
      await scanner.start(
        {
          facingMode: "environment",
        },
        {
          fps: 10,
          qrbox: {
            width: 250,
            height: 250,
          },
        },

        async (decodedText) => {
          if (
            scanLockedRef.current
          ) {
            return;
          }

          scanLockedRef.current = true;

          console.log(
            "QR scanned:",
            decodedText
          );

          await stopScanner();

          await processQrCode(
            decodedText
          );
        },

        () => {
          // Ignore normal camera scanning errors.
        }
      );

      setScanning(true);

    } catch (err) {
      console.error(
        "Unable to start QR scanner:",
        err
      );

      scannerInstanceRef.current =
        null;

      setScanning(false);

      setError(
        "Unable to access the camera. Please allow camera permission and try again."
      );
    }
  }

  // =========================================================
  // CONFIRM DELIVERY
  // =========================================================

  async function confirmDelivery() {
    if (!qrToken) {
      setError(
        "No delivery QR code found."
      );
      return;
    }

    setConfirming(true);
    setError("");
    setMessage("");

    try {
      const response = await fetch(
        `${API_BASE_URL}/orders/delivery-confirmation/${encodeURIComponent(
          qrToken
        )}/confirm`,
        {
          method: "POST",

          headers: {
            "Content-Type":
              "application/json",
            Accept:
              "application/json",
          },
        }
      );

      const data =
        await response.json();

      console.log(
        "Delivery confirmation response:",
        data
      );

      if (!response.ok) {
        throw new Error(
          data.message ||
            "Delivery confirmation failed."
        );
      }

      // -----------------------------------------------------
      // Update order on screen
      // -----------------------------------------------------

      setOrder((previous) => ({
        ...previous,

        status:
          data.order_status ||
          "delivered",

        order_status:
          data.order_status ||
          "delivered",

        payment_status:
          data.payment_status ||
          previous?.payment_status,
      }));

      setMessage(
        `Delivery confirmed successfully for Order #${data.order_id}.`
      );

    } catch (err) {
      console.error(
        "Confirmation error:",
        err
      );

      setError(
        err.message ||
          "Unable to confirm delivery."
      );

    } finally {
      setConfirming(false);
    }
  }

  // =========================================================
  // SCAN ANOTHER QR
  // =========================================================

  function scanAnotherQr() {
    setOrder(null);
    setQrToken("");

    setError("");
    setMessage("");

    scanLockedRef.current = false;
  }

  // =========================================================
  // CLEANUP
  // =========================================================

  useEffect(() => {
    return () => {
      stopScanner();
    };
  }, []);

  // =========================================================
  // UI
  // =========================================================

  return (
    <div
      style={{
        maxWidth: "700px",
        margin: "30px auto",
        padding: "20px",
      }}
    >

      {/* ===================================================
          TITLE
      =================================================== */}

      <h2>
        📷 Delivery Confirmation
      </h2>

      <p>
        Scan the QR code provided by
        the delivery person to confirm
        your order.
      </p>

      {/* ===================================================
          CAMERA
      =================================================== */}

      {!order && (
        <>
          <div
            id="delivery-qr-reader"
            style={{
              width: "100%",
              marginTop: "20px",
            }}
          />

          {!scanning && (
            <button
              type="button"
              onClick={startScanner}
              style={{
                marginTop: "15px",
                padding: "12px 20px",
                cursor: "pointer",
              }}
            >
              📷 Start Camera
            </button>
          )}
        </>
      )}

      {/* ===================================================
          LOADING
      =================================================== */}

      {loading && (
        <p>
          Checking delivery QR code...
        </p>
      )}

      {/* ===================================================
          ERROR
      =================================================== */}

      {error && (
        <div
          style={{
            marginTop: "15px",
            padding: "12px",
            background: "#fee2e2",
            color: "#991b1b",
            borderRadius: "8px",
          }}
        >
          {error}
        </div>
      )}

      {/* ===================================================
          SUCCESS MESSAGE
      =================================================== */}

      {message && (
        <div
          style={{
            marginTop: "15px",
            padding: "12px",
            background: "#dcfce7",
            color: "#166534",
            borderRadius: "8px",
          }}
        >
          {message}
        </div>
      )}

      {/* ===================================================
          ORDER DETAILS
      =================================================== */}

      {order && (
        <div
          style={{
            marginTop: "25px",
            padding: "20px",
            border:
              "1px solid #ddd",
            borderRadius: "10px",
          }}
        >

          <h3>
            Order #{order.order_id}
          </h3>

          <p>
            <strong>
              Total:
            </strong>{" "}
            ₹{order.total_amount}
          </p>

          <p>
            <strong>
              Payment:
            </strong>{" "}
            {order.payment_method}
          </p>

          <p>
            <strong>
              Status:
            </strong>{" "}
            {order.order_status ||
              order.status}
          </p>

          {order.expires_at && (
            <p>
              <strong>
                QR expires:
              </strong>{" "}
              {new Date(
                order.expires_at
              ).toLocaleString()}
            </p>
          )}

          {/* =================================================
              CONFIRM BUTTON
          ================================================= */}

          {!message && (
            <button
              type="button"
              onClick={
                confirmDelivery
              }
              disabled={confirming}
              style={{
                marginTop: "15px",
                padding:
                  "12px 20px",
                cursor: confirming
                  ? "not-allowed"
                  : "pointer",
              }}
            >
              {confirming
                ? "Confirming..."
                : "✅ Confirm Delivery"}
            </button>
          )}

          {/* =================================================
              AFTER CONFIRMATION
          ================================================= */}

          {message && (
            <p
              style={{
                marginTop: "15px",
                fontWeight: "bold",
              }}
            >
              ✅ This order has
              been successfully
              delivered.
            </p>
          )}

          {/* =================================================
              SCAN ANOTHER QR
          ================================================= */}

          <button
            type="button"
            onClick={
              scanAnotherQr
            }
            style={{
              marginTop: "15px",
              marginLeft: "10px",
              padding:
                "12px 20px",
            }}
          >
            📷 Scan Another QR
          </button>

        </div>
      )}

    </div>
  );
}

export default DeliveryConfirmation;
