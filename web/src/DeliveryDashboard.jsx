import React, { useEffect, useState } from "react";
import { QRCodeSVG } from "qrcode.react";
import { getDeliveryToken } from "./auth";
import "./DeliveryDashboard.css";

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL ||
  "https://shop-to-door-backend-294288480400.asia-south2.run.app/api";

const DELIVERY_ACTIONS = {
  assigned: {
    nextStatus: "picked_up",
    label: "Mark as Picked Up",
  },
  picked_up: {
    nextStatus: "out_for_delivery",
    label: "Start Delivery",
  },
};

const STATUS_LABELS = {
  pending: "Pending",
  assigned: "Assigned",
  packed: "Packed",
  shipped: "Shipped",
  picked_up: "Picked Up",
  out_for_delivery: "Out for Delivery",
  delivered: "Delivered",
  delivery_failed: "Delivery Failed",
  cancelled: "Cancelled",
};

function DeliveryDashboard() {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [updatingId, setUpdatingId] = useState(null);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  // QR state
  const [qrLoadingId, setQrLoadingId] = useState(null);
  const [qrData, setQrData] = useState({});

  // =========================================================
  // FETCH DELIVERY ORDERS
  // =========================================================

  const fetchOrders = async () => {
    try {
      setLoading(true);
      setError("");

      const token = getDeliveryToken();

      if (!token) {
        throw new Error(
          "Delivery person is not logged in."
        );
      }

      const response = await fetch(
        `${API_BASE_URL}/orders/delivery/my-orders`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        }
      );

      const data = await response.json();

      if (!response.ok) {
        throw new Error(
          data?.message ||
            data?.error ||
            "Failed to load delivery orders."
        );
      }

      setOrders(
        Array.isArray(data)
          ? data
          : data.orders || []
      );
    } catch (err) {
      setError(
        err.message ||
          "Failed to load delivery orders."
      );
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchOrders();
  }, []);

  // =========================================================
  // UPDATE ORDER STATUS
  // =========================================================

  const updateStatus = async (orderId, status) => {
    try {
      setUpdatingId(orderId);
      setError("");
      setMessage("");

      const token = getDeliveryToken();

      if (!token) {
        throw new Error(
          "Delivery person is not logged in."
        );
      }

      const response = await fetch(
        `${API_BASE_URL}/orders/delivery/${orderId}/status`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({
            status,
          }),
        }
      );

      const data = await response.json();

      if (!response.ok) {
        throw new Error(
          data?.message ||
            data?.error ||
            "Failed to update order status."
        );
      }

      setMessage(
        `Order #${orderId} updated to ${
          STATUS_LABELS[status] || status
        }.`
      );

      await fetchOrders();
    } catch (err) {
      setError(
        err.message ||
          "Failed to update order status."
      );
    } finally {
      setUpdatingId(null);
    }
  };

  // =========================================================
  // MARK DELIVERY FAILED
  // =========================================================

  const markFailed = async (orderId) => {
    const confirmed = window.confirm(
      `Mark order #${orderId} as delivery failed?`
    );

    if (!confirmed) return;

    await updateStatus(
      orderId,
      "delivery_failed"
    );
  };

  // =========================================================
  // GENERATE DELIVERY QR
  // =========================================================

  const generateDeliveryQR = async (orderId) => {
    try {
      setQrLoadingId(orderId);
      setError("");
      setMessage("");

      const token = getDeliveryToken();

      if (!token) {
        throw new Error(
          "Delivery person is not logged in."
        );
      }

      const response = await fetch(
        `${API_BASE_URL}/orders/delivery/${orderId}/confirmation-qr`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${token}`,
          },
        }
      );

      const data = await response.json();

      if (!response.ok) {
        throw new Error(
          data?.message ||
            data?.error ||
            "Failed to generate delivery QR."
        );
      }

      setQrData((previous) => ({
        ...previous,
        [orderId]: {
          orderId:
            data.order_id || orderId,
          confirmationUrl:
            data.confirmation_url,
          expiresAt:
            data.expires_at,
          totalAmount:
            data.total_amount,
          paymentMethod:
            data.payment_method,
        },
      }));

      setMessage(
        `Delivery QR generated for Order #${orderId}.`
      );
    } catch (err) {
      setError(
        err.message ||
          "Failed to generate delivery QR."
      );
    } finally {
      setQrLoadingId(null);
    }
  };

  // =========================================================
  // LOADING
  // =========================================================

  if (loading) {
    return (
      <div className="delivery-page">
        <div className="delivery-loading">
          <div className="delivery-spinner"></div>

          <p>
            Loading your delivery orders...
          </p>
        </div>
      </div>
    );
  }

  // =========================================================
  // MAIN UI
  // =========================================================

  return (
    <div className="delivery-page">
      <div className="delivery-container">

        {/* =====================================================
            HEADER
        ====================================================== */}

        <div className="delivery-header">
          <div>
            <h1>Delivery Dashboard</h1>

            <p>
              Manage the orders assigned to you
              and update their delivery status.
            </p>
          </div>

          <button
            className="delivery-refresh-btn"
            onClick={fetchOrders}
            disabled={loading}
          >
            ↻ Refresh
          </button>
        </div>

        {/* =====================================================
            MESSAGES
        ====================================================== */}

        {error && (
          <div className="delivery-alert delivery-alert-error">
            <strong>Error:</strong> {error}
          </div>
        )}

        {message && (
          <div className="delivery-alert delivery-alert-success">
            {message}
          </div>
        )}

        {/* =====================================================
            STATISTICS
        ====================================================== */}

        <div className="delivery-stats">

          <div className="delivery-stat-card">
            <span>Total Assigned</span>

            <strong>
              {orders.length}
            </strong>
          </div>

          <div className="delivery-stat-card">
            <span>Picked Up</span>

            <strong>
              {
                orders.filter(
                  (order) =>
                    order.status === "picked_up"
                ).length
              }
            </strong>
          </div>

          <div className="delivery-stat-card">
            <span>Out for Delivery</span>

            <strong>
              {
                orders.filter(
                  (order) =>
                    order.status ===
                    "out_for_delivery"
                ).length
              }
            </strong>
          </div>

          <div className="delivery-stat-card">
            <span>Delivered</span>

            <strong>
              {
                orders.filter(
                  (order) =>
                    order.status === "delivered"
                ).length
              }
            </strong>
          </div>

        </div>

        {/* =====================================================
            ORDERS
        ====================================================== */}

        {orders.length === 0 ? (
          <div className="delivery-empty">

            <div className="delivery-empty-icon">
              📦
            </div>

            <h2>
              No Orders Assigned
            </h2>

            <p>
              You currently have no orders
              assigned for delivery.
            </p>

          </div>
        ) : (
          <div className="delivery-orders">

            {orders.map((order) => {

              const action =
                DELIVERY_ACTIONS[
                  order.status
                ];

              const isUpdating =
                updatingId === order.id;

              const isGeneratingQR =
                qrLoadingId === order.id;

              const currentQR =
                qrData[order.id];

              return (
                <div
                  className={`delivery-order-card ${
                    currentQR
                      ? "delivery-order-card-with-qr"
                      : ""
                  }`}
                  key={order.id}
                >

                  {/* =================================================
                      LEFT SIDE
                  ================================================== */}

                  <div className="delivery-order-main">

                    {/* ORDER HEADER */}

                    <div className="delivery-order-top">

                      <div>

                        <h2>
                          Order #{order.id}
                        </h2>

                        <span className="delivery-order-date">
                          {order.created_at
                            ? new Date(
                                order.created_at
                              ).toLocaleString()
                            : ""}
                        </span>

                      </div>

                      <span
                        className={`delivery-status status-${order.status}`}
                      >
                        {STATUS_LABELS[
                          order.status
                        ] ||
                          order.status}
                      </span>

                    </div>

                    {/* CUSTOMER */}

                    <div className="delivery-section">

                      <h3>
                        Customer
                      </h3>

                      <div className="delivery-customer">

                        <p>
                          <strong>
                            {order.shipping?.name ||
                              "Customer"}
                          </strong>
                        </p>

                        <p>
                          📞{" "}
                          {order.shipping?.phone ||
                            "Phone not available"}
                        </p>

                        <p>
                          📍{" "}
                          {order.shipping?.address ||
                            "Address not available"}
                        </p>

                        <p>
                          {[
                            order.shipping?.city,
                            order.shipping?.state,
                            order.shipping?.pincode,
                          ]
                            .filter(Boolean)
                            .join(", ")}
                        </p>

                      </div>

                    </div>

                    {/* ITEMS */}

                    <div className="delivery-section">

                      <h3>
                        Order Items
                      </h3>

                      <div className="delivery-items">

                        {order.items?.map(
                          (item) => (
                            <div
                              className="delivery-item"
                              key={item.id}
                            >

                              <div className="delivery-item-info">

                                <strong>
                                  {
                                    item.product_name
                                  }
                                </strong>

                                {item.product_sku && (
                                  <small>
                                    SKU:{" "}
                                    {
                                      item.product_sku
                                    }
                                  </small>
                                )}

                              </div>

                              <div className="delivery-item-right">

                                <span>
                                  ×{" "}
                                  {
                                    item.quantity
                                  }
                                </span>

                                <strong>
                                  ₹
                                  {Number(
                                    item.total_price ||
                                      0
                                  ).toFixed(2)}
                                </strong>

                              </div>

                            </div>
                          )
                        )}

                      </div>

                    </div>

                    {/* PAYMENT */}

                    <div className="delivery-payment">

                      <div>
                        <span>
                          Payment
                        </span>

                        <strong>
                          {order.payment_method ||
                            "N/A"}
                        </strong>
                      </div>

                      <div>
                        <span>
                          Payment Status
                        </span>

                        <strong>
                          {order.payment_status ||
                            "N/A"}
                        </strong>
                      </div>

                      <div>
                        <span>
                          Total
                        </span>

                        <strong>
                          ₹
                          {Number(
                            order.total_amount ||
                              0
                          ).toFixed(2)}
                        </strong>
                      </div>

                    </div>

                    {/* NOTES */}

                    {order.notes && (
                      <div className="delivery-notes">

                        <strong>
                          Customer Note:
                        </strong>

                        <p>
                          {order.notes}
                        </p>

                      </div>
                    )}

                    {/* ACTIONS */}

                    <div className="delivery-actions">

                      {/* Picked Up / Start Delivery */}

                      {action && (
                        <button
                          className="delivery-primary-btn"
                          disabled={isUpdating}
                          onClick={() =>
                            updateStatus(
                              order.id,
                              action.nextStatus
                            )
                          }
                        >
                          {isUpdating
                            ? "Updating..."
                            : action.label}
                        </button>
                      )}

                      {/* Generate QR */}

                      {order.status ===
                        "out_for_delivery" && (
                        <button
                          className="delivery-primary-btn"
                          disabled={
                            isGeneratingQR
                          }
                          onClick={() =>
                            generateDeliveryQR(
                              order.id
                            )
                          }
                        >
                          {isGeneratingQR
                            ? "Generating QR..."
                            : currentQR
                            ? "↻ Generate New QR"
                            : "📱 Generate Delivery QR"}
                        </button>
                      )}

                      {/* Delivery Failed */}

                      {![
                        "delivered",
                        "cancelled",
                      ].includes(
                        order.status
                      ) && (
                        <button
                          className="delivery-failed-btn"
                          disabled={
                            isUpdating ||
                            isGeneratingQR
                          }
                          onClick={() =>
                            markFailed(
                              order.id
                            )
                          }
                        >
                          Delivery Failed
                        </button>
                      )}

                    </div>

                  </div>

                  {/* =================================================
                      RIGHT SIDE — DELIVERY QR
                  ================================================== */}

                  {currentQR && (
                    <div className="delivery-qr-panel">

                      <div className="delivery-qr-panel-header">

                        <div>
                          <span className="delivery-qr-icon">
                            📱
                          </span>

                          <h3>
                            Delivery Confirmation
                          </h3>
                        </div>

                        <span className="delivery-qr-live">
                          ACTIVE
                        </span>

                      </div>

                      <p className="delivery-qr-order">
                        Order #{currentQR.orderId}
                      </p>

                      <div className="delivery-qr-code">

                        <QRCodeSVG
                          value={
                            currentQR.confirmationUrl
                          }
                          size={230}
                          level="M"
                          includeMargin={true}
                        />

                      </div>

                      <div className="delivery-qr-scan-text">

                        <strong>
                          Scan to Confirm Delivery
                        </strong>

                        <p>
                          Ask the customer to scan
                          this QR code using their
                          phone.
                        </p>

                        <p>
                          The customer must log in
                          and confirm the delivery.
                        </p>

                      </div>

                      {/* PAYMENT */}

                      {currentQR.paymentMethod && (
                        <div className="delivery-qr-info">

                          <span>
                            Payment
                          </span>

                          <strong>
                            {currentQR.paymentMethod}
                          </strong>

                        </div>
                      )}

                      {/* TOTAL */}

                      {currentQR.totalAmount !==
                        undefined &&
                        currentQR.totalAmount !== null && (
                          <div className="delivery-qr-info">

                            <span>
                              Order Total
                            </span>

                            <strong>
                              ₹
                              {Number(
                                currentQR.totalAmount
                              ).toFixed(2)}
                            </strong>

                          </div>
                        )}

                      {/* EXPIRY */}

                      {currentQR.expiresAt && (
                        <div className="delivery-qr-expiry">

                          QR expires at{" "}

                          {new Date(
                            currentQR.expiresAt
                          ).toLocaleString()}

                        </div>
                      )}

                      {/* CONFIRMATION URL */}

                      <div className="delivery-qr-url">

                        <small>
                          Confirmation link
                        </small>

                        <div>
                          {currentQR.confirmationUrl}
                        </div>

                      </div>

                      {/* QR ACTION */}

                      <button
                        className="delivery-qr-regenerate-btn"
                        onClick={() =>
                          generateDeliveryQR(
                            order.id
                          )
                        }
                        disabled={
                          isGeneratingQR
                        }
                      >
                        {isGeneratingQR
                          ? "Generating..."
                          : "↻ Generate New QR"}
                      </button>

                    </div>
                  )}

                </div>
              );
            })}

          </div>
        )}

      </div>
    </div>
  );
}

export default DeliveryDashboard;
