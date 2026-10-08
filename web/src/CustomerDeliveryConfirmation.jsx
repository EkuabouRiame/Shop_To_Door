import React, { useEffect, useRef, useState } from "react";
import { Html5Qrcode } from "html5-qrcode";
import { getToken } from "./auth";
import "./CustomerDeliveryConfirmation.css";

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL ||
  "https://shop-to-door-backend-294288480400.asia-south2.run.app/api";

function CustomerDeliveryConfirmation() {
  const scannerRef = useRef(null);
  const scannerRunningRef = useRef(false);

  const [scanning, setScanning] = useState(false);
  const [token, setToken] = useState("");
  const [order, setOrder] = useState(null);

  const [loadingOrder, setLoadingOrder] = useState(false);
  const [confirming, setConfirming] = useState(false);

  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  // =====================================================
  // GET TOKEN FROM URL
  // =====================================================

  useEffect(() => {
    const pathParts = window.location.pathname.split("/").filter(Boolean);

    const confirmationIndex = pathParts.indexOf(
      "delivery-confirmation"
    );

    if (
      confirmationIndex !== -1 &&
      pathParts[confirmationIndex + 1]
    ) {
      const urlToken = pathParts[confirmationIndex + 1];

      setToken(urlToken);
      loadOrderDetails(urlToken);
    }

    return () => {
      stopScanner();
    };
  }, []);

  // =====================================================
  // START QR SCANNER
  // =====================================================

  const startScanner = async () => {
    setError("");
    setMessage("");

    try {
      if (scannerRunningRef.current) {
        return;
      }

      const scanner = new Html5Qrcode("delivery-qr-reader");

      scannerRef.current = scanner;

      await scanner.start(
        { facingMode: "environment" },
        {
          fps: 10,
          qrbox: {
            width: 250,
            height: 250,
          },
        },
        async (decodedText) => {
          await handleScannedValue(decodedText);
        },
        () => {
          // Ignore normal scan failures while camera is searching.
        }
      );

      scannerRunningRef.current = true;
      setScanning(true);
    } catch (err) {
      console.error("QR scanner error:", err);

      setError(
        "Unable to access the camera. Please allow camera permission and try again."
      );

      scannerRef.current = null;
      scannerRunningRef.current = false;
      setScanning(false);
    }
  };

  // =====================================================
  // STOP QR SCANNER
  // =====================================================

  const stopScanner = async () => {
    const scanner = scannerRef.current;

    if (!scanner) {
      setScanning(false);
      return;
    }

    try {
      if (scannerRunningRef.current) {
        await scanner.stop();
      }
    } catch (err) {
      console.error("Error stopping QR scanner:", err);
    }

    try {
      scanner.clear();
    } catch (err) {
      console.error("Error clearing QR scanner:", err);
    }

    scannerRef.current = null;
    scannerRunningRef.current = false;
    setScanning(false);
  };

  // =====================================================
  // HANDLE SCANNED QR VALUE
  // =====================================================

  const handleScannedValue = async (decodedText) => {
    await stopScanner();

    let scannedToken = decodedText;

    try {
      const scannedUrl = new URL(decodedText);

      const parts = scannedUrl.pathname
        .split("/")
        .filter(Boolean);

      const index = parts.indexOf("delivery-confirmation");

      if (index !== -1 && parts[index + 1]) {
        scannedToken = parts[index + 1];
      }
    } catch {
      // QR may contain only the token instead of a URL.
    }

    if (!scannedToken) {
      setError("Invalid delivery QR code.");
      return;
    }

    setToken(scannedToken);
    await loadOrderDetails(scannedToken);
  };

  // =====================================================
  // LOAD ORDER DETAILS
  // =====================================================

  const loadOrderDetails = async (qrToken) => {
    if (!qrToken) {
      return;
    }

    setLoadingOrder(true);
    setError("");
    setMessage("");
    setOrder(null);

    try {
      const response = await fetch(
        `${API_BASE_URL}/orders/delivery-confirmation/${encodeURIComponent(
          qrToken
        )}`
      );

      const data = await response.json();

      if (!response.ok) {
        throw new Error(
          data.message || "Unable to load delivery information."
        );
      }

      setOrder(data);
    } catch (err) {
      console.error("Delivery QR details error:", err);

      setError(
        err.message ||
          "Unable to verify this delivery QR code."
      );
    } finally {
      setLoadingOrder(false);
    }
  };

  // =====================================================
  // CONFIRM DELIVERY
  // =====================================================

  const confirmDelivery = async () => {
    const authToken = getToken();

    if (!authToken) {
      setError(
        "Please log in to your customer account before confirming delivery."
      );
      return;
    }

    if (!token) {
      setError("Delivery QR token is missing.");
      return;
    }

    setConfirming(true);
    setError("");
    setMessage("");

    try {
      const response = await fetch(
        `${API_BASE_URL}/orders/delivery-confirmation/${encodeURIComponent(
          token
        )}/confirm`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${authToken}`,
            "Content-Type": "application/json",
          },
        }
      );

      const data = await response.json();

      if (!response.ok) {
        throw new Error(
          data.message || "Unable to confirm delivery."
        );
      }

      setMessage(
        `Delivery confirmed successfully for Order #${data.order_id}.`
      );

      setOrder((previous) => ({
        ...previous,
        order_status: data.order_status,
        payment_status: data.payment_status,
        confirmed: true,
      }));
    } catch (err) {
      console.error("Confirm delivery error:", err);

      setError(
        err.message ||
          "Unable to confirm delivery. Please try again."
      );
    } finally {
      setConfirming(false);
    }
  };

  // =====================================================
  // RESET
  // =====================================================

  const scanAnotherQR = async () => {
    await stopScanner();

    setToken("");
    setOrder(null);
    setError("");
    setMessage("");

    // Remove token from the browser URL.
    window.history.replaceState(
      {},
      "",
      "/delivery-confirmation"
    );
  };

  // =====================================================
  // RENDER
  // =====================================================

  return (
    <div className="customer-delivery-page">
      <div className="customer-delivery-card">

        <div className="customer-delivery-header">
          <div className="customer-delivery-icon">
            📦
          </div>

          <h1>Confirm Delivery</h1>

          <p>
            Scan the delivery QR code provided by the
            delivery person.
          </p>
        </div>

        {/* =================================================
            ERROR
        ================================================= */}

        {error && (
          <div className="delivery-alert delivery-alert-error">
            {error}
          </div>
        )}

        {/* =================================================
            SUCCESS
        ================================================= */}

        {message && (
          <div className="delivery-alert delivery-alert-success">
            {message}
          </div>
        )}

        {/* =================================================
            SCANNER
        ================================================= */}

        {!order && !loadingOrder && (
          <div className="delivery-scanner-section">

            <div
              id="delivery-qr-reader"
              className="delivery-qr-reader"
            />

            {!scanning && (
              <button
                type="button"
                className="delivery-primary-button"
                onClick={startScanner}
              >
                📷 Scan Delivery QR
              </button>
            )}

            {scanning && (
              <button
                type="button"
                className="delivery-secondary-button"
                onClick={stopScanner}
              >
                Stop Scanner
              </button>
            )}

            <p className="delivery-scanner-help">
              Point your camera at the QR code shown by
              the delivery person.
            </p>
          </div>
        )}

        {/* =================================================
            LOADING
        ================================================= */}

        {loadingOrder && (
          <div className="delivery-loading">
            <div className="delivery-spinner" />

            <p>
              Verifying delivery QR code...
            </p>
          </div>
        )}

        {/* =================================================
            ORDER CONFIRMATION
        ================================================= */}

        {order && !order.confirmed && (
          <div className="delivery-confirmation-section">

            <div className="delivery-verified">
              ✓ Delivery QR Verified
            </div>

            <div className="delivery-order-box">

              <div className="delivery-order-row">
                <span>Order</span>
                <strong>
                  #{order.order_id}
                </strong>
              </div>

              <div className="delivery-order-row">
                <span>Total Amount</span>
                <strong>
                  ₹
                  {Number(
                    order.total_amount || 0
                  ).toFixed(2)}
                </strong>
              </div>

              <div className="delivery-order-row">
                <span>Payment Method</span>
                <strong>
                  {String(
                    order.payment_method || ""
                  ).toUpperCase()}
                </strong>
              </div>

              <div className="delivery-order-row">
                <span>Payment Status</span>
                <strong>
                  {order.payment_status || "Pending"}
                </strong>
              </div>

            </div>

            <div className="delivery-warning">
              <strong>Before confirming:</strong>

              <p>
                Please make sure you have received your
                order from the delivery person.
              </p>
            </div>

            <button
              type="button"
              className="delivery-confirm-button"
              onClick={confirmDelivery}
              disabled={confirming}
            >
              {confirming
                ? "Confirming..."
                : "✓ Confirm Delivery"}
            </button>

            <button
              type="button"
              className="delivery-secondary-button"
              onClick={scanAnotherQR}
              disabled={confirming}
            >
              Scan Another QR
            </button>

          </div>
        )}

        {/* =================================================
            CONFIRMED
        ================================================= */}

        {order?.confirmed && (
          <div className="delivery-completed-section">

            <div className="delivery-success-icon">
              ✓
            </div>

            <h2>Delivery Confirmed</h2>

            <p>
              Order #{order.order_id} has been successfully
              marked as delivered.
            </p>

            {order.payment_status === "paid" && (
              <div className="delivery-paid-message">
                ✓ Payment marked as paid
              </div>
            )}

            <button
              type="button"
              className="delivery-primary-button"
              onClick={scanAnotherQR}
            >
              Scan Another Delivery QR
            </button>

          </div>
        )}

      </div>
    </div>
  );
}

export default CustomerDeliveryConfirmation;
