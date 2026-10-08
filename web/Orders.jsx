import { useEffect, useState } from "react";
import { getToken } from "./auth";

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL ||
  "http://127.0.0.1:5000/api";

const STATUS_STEPS = [
  {
    key: "placed",
    label: "Order Placed",
    icon: "🛒",
  },
  {
    key: "packed",
    label: "Packed",
    icon: "📦",
  },
  {
    key: "shipped",
    label: "Shipped",
    icon: "🚚",
  },
  {
    key: "out_for_delivery",
    label: "Out for Delivery",
    icon: "🛵",
  },
  {
    key: "delivered",
    label: "Delivered",
    icon: "✅",
  },
];

function getStatusIndex(status) {
  const index = STATUS_STEPS.findIndex(
    (step) => step.key === status
  );

  return index >= 0 ? index : 0;
}

function formatDate(dateString) {
  if (!dateString) {
    return "Date unavailable";
  }

  try {
    return new Date(dateString).toLocaleString("en-IN", {
      day: "2-digit",
      month: "short",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  } catch {
    return dateString;
  }
}

function formatStatus(status) {
  if (!status) {
    return "Order Placed";
  }

  return status
    .replaceAll("_", " ")
    .replace(/\b\w/g, (letter) =>
      letter.toUpperCase()
    );
}

function Orders({ onBack }) {
  const [orders, setOrders] = useState([]);

  const [loading, setLoading] =
    useState(true);

  const [error, setError] =
    useState("");

  const [selectedOrder, setSelectedOrder] =
    useState(null);

  const [cancellingId, setCancellingId] =
    useState(null);

  // =====================================================
  // LOAD ORDERS
  // =====================================================

  async function loadOrders() {
    const token = getToken();

    if (!token) {
      setError("Please login again.");
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setError("");

      const response = await fetch(
        `${API_BASE_URL}/orders/`,
        {
          method: "GET",

          headers: {
            Accept:
              "application/json",

            Authorization:
              `Bearer ${token}`,
          },
        }
      );

      let data;

      try {
        data = await response.json();
      } catch {
        throw new Error(
          `Invalid server response. HTTP ${response.status}`
        );
      }

      if (!response.ok) {
        throw new Error(
          data.message ||
            "Failed to load orders."
        );
      }

      setOrders(
        Array.isArray(data.orders)
          ? data.orders
          : []
      );
    } catch (err) {
      console.error(
        "Load orders failed:",
        err
      );

      setError(
        err.message ||
          "Unable to load your orders."
      );
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadOrders();
  }, []);

  // =====================================================
  // CANCEL ORDER
  // =====================================================

  async function handleCancelOrder(orderId) {
    const confirmed =
      window.confirm(
        "Are you sure you want to cancel this order?"
      );

    if (!confirmed) {
      return;
    }

    const token = getToken();

    if (!token) {
      alert("Please login again.");
      return;
    }

    try {
      setCancellingId(orderId);

      const response = await fetch(
        `${API_BASE_URL}/orders/${orderId}/cancel`,
        {
          method: "POST",

          headers: {
            Accept:
              "application/json",

            Authorization:
              `Bearer ${token}`,

            "Content-Type":
              "application/json",
          },
        }
      );

      let data;

      try {
        data = await response.json();
      } catch {
        throw new Error(
          `Invalid server response. HTTP ${response.status}`
        );
      }

      if (!response.ok) {
        throw new Error(
          data.message ||
            "Unable to cancel order."
        );
      }

      alert(
        "Order cancelled successfully."
      );

      await loadOrders();

      setSelectedOrder(null);
    } catch (err) {
      console.error(
        "Cancel order failed:",
        err
      );

      alert(
        err.message ||
          "Unable to cancel order."
      );
    } finally {
      setCancellingId(null);
    }
  }

  // =====================================================
  // LOADING
  // =====================================================

  if (loading) {
    return (
      <main
        style={{
          maxWidth: "1000px",
          margin: "0 auto",
          padding: "25px 20px",
        }}
      >
        <div
          style={{
            background: "#ffffff",
            borderRadius: "16px",
            padding: "40px",
            textAlign: "center",
            boxShadow:
              "0 4px 20px rgba(0,0,0,0.06)",
          }}
        >
          <div
            style={{
              fontSize: "40px",
              marginBottom: "15px",
            }}
          >
            📦
          </div>

          <h2
            style={{
              margin: "0 0 8px",
              color: "#111827",
            }}
          >
            Loading your orders...
          </h2>

          <p
            style={{
              margin: 0,
              color: "#6b7280",
            }}
          >
            Please wait.
          </p>
        </div>
      </main>
    );
  }

  // =====================================================
  // ERROR
  // =====================================================

  if (error) {
    return (
      <main
        style={{
          maxWidth: "1000px",
          margin: "0 auto",
          padding: "25px 20px",
        }}
      >
        <button
          type="button"
          onClick={onBack}
          style={{
            border: "none",
            background: "transparent",
            cursor: "pointer",
            color: "#2563eb",
            fontWeight: "600",
            marginBottom: "15px",
          }}
        >
          ← Back to Account
        </button>

        <div
          style={{
            background: "#ffffff",
            borderRadius: "16px",
            padding: "30px",
            textAlign: "center",
            boxShadow:
              "0 4px 20px rgba(0,0,0,0.06)",
          }}
        >
          <div
            style={{
              fontSize: "40px",
              marginBottom: "10px",
            }}
          >
            ⚠️
          </div>

          <h2
            style={{
              color: "#111827",
            }}
          >
            Unable to load orders
          </h2>

          <p
            style={{
              color: "#6b7280",
            }}
          >
            {error}
          </p>

          <button
            type="button"
            onClick={loadOrders}
            style={{
              border: "none",
              background: "#2563eb",
              color: "#ffffff",
              padding: "10px 18px",
              borderRadius: "8px",
              cursor: "pointer",
              fontWeight: "600",
            }}
          >
            Try Again
          </button>
        </div>
      </main>
    );
  }

  // =====================================================
  // ORDER DETAILS
  // =====================================================

  if (selectedOrder) {
    const status =
      selectedOrder.status ||
      "placed";

    const currentStatusIndex =
      getStatusIndex(status);

    const canCancel =
      [
        "placed",
        "pending",
        "confirmed",
        "processing",
      ].includes(status);

    return (
      <main
        style={{
          maxWidth: "1000px",
          margin: "0 auto",
          padding: "25px 20px",
        }}
      >
        <button
          type="button"
          onClick={() =>
            setSelectedOrder(null)
          }
          style={{
            border: "none",
            background: "transparent",
            cursor: "pointer",
            color: "#2563eb",
            fontWeight: "600",
            marginBottom: "15px",
          }}
        >
          ← Back to My Orders
        </button>

        <div
          style={{
            background: "#ffffff",
            borderRadius: "16px",
            padding: "25px",
            boxShadow:
              "0 4px 20px rgba(0,0,0,0.06)",
          }}
        >
          {/* HEADER */}

          <div
            style={{
              display: "flex",
              justifyContent:
                "space-between",
              alignItems: "flex-start",
              gap: "15px",
              flexWrap: "wrap",
              marginBottom: "25px",
            }}
          >
            <div>
              <h1
                style={{
                  margin: "0 0 8px",
                  color: "#111827",
                  fontSize: "26px",
                }}
              >
                Order #{selectedOrder.id}
              </h1>

              <p
                style={{
                  margin: 0,
                  color: "#6b7280",
                }}
              >
                Placed on{" "}
                {formatDate(
                  selectedOrder.created_at
                )}
              </p>
            </div>

            <div
              style={{
                background:
                  status === "cancelled"
                    ? "#fee2e2"
                    : "#ecfdf5",

                color:
                  status === "cancelled"
                    ? "#991b1b"
                    : "#065f46",

                padding:
                  "8px 14px",

                borderRadius:
                  "999px",

                fontWeight:
                  "700",
              }}
            >
              {formatStatus(status)}
            </div>
          </div>

          {/* TRACKING */}

          {status !== "cancelled" && (
            <div
              style={{
                marginBottom: "30px",
                overflowX: "auto",
              }}
            >
              <div
                style={{
                  minWidth: "650px",
                  display: "flex",
                  alignItems: "flex-start",
                  justifyContent:
                    "space-between",
                }}
              >
                {STATUS_STEPS.map(
                  (step, index) => {
                    const completed =
                      index <=
                      currentStatusIndex;

                    return (
                      <div
                        key={step.key}
                        style={{
                          flex: 1,
                          textAlign:
                            "center",
                          position:
                            "relative",
                        }}
                      >
                        {index > 0 && (
                          <div
                            style={{
                              position:
                                "absolute",
                              top: "19px",
                              right:
                                "50%",
                              width: "100%",
                              height:
                                "3px",
                              background:
                                index <=
                                currentStatusIndex
                                  ? "#16a34a"
                                  : "#e5e7eb",
                              zIndex: 0,
                            }}
                          />
                        )}

                        <div
                          style={{
                            width: "40px",
                            height: "40px",
                            margin:
                              "0 auto 8px",
                            borderRadius:
                              "50%",
                            background:
                              completed
                                ? "#16a34a"
                                : "#e5e7eb",
                            color:
                              completed
                                ? "#ffffff"
                                : "#6b7280",
                            display:
                              "flex",
                            alignItems:
                              "center",
                            justifyContent:
                              "center",
                            position:
                              "relative",
                            zIndex: 1,
                            fontSize:
                              "18px",
                          }}
                        >
                          {step.icon}
                        </div>

                        <div
                          style={{
                            fontSize:
                              "12px",
                            fontWeight:
                              completed
                                ? "700"
                                : "500",
                            color:
                              completed
                                ? "#111827"
                                : "#6b7280",
                          }}
                        >
                          {step.label}
                        </div>
                      </div>
                    );
                  }
                )}
              </div>
            </div>
          )}

          {/* CANCELLED */}

          {status === "cancelled" && (
            <div
              style={{
                background: "#fef2f2",
                border:
                  "1px solid #fecaca",
                color: "#991b1b",
                padding: "15px",
                borderRadius: "10px",
                marginBottom: "25px",
              }}
            >
              This order has been
              cancelled.
            </div>
          )}

          {/* ITEMS */}

          <h2
            style={{
              fontSize: "20px",
              color: "#111827",
              marginBottom: "15px",
            }}
          >
            Items
          </h2>

          <div
            style={{
              border:
                "1px solid #e5e7eb",
              borderRadius: "12px",
              overflow: "hidden",
              marginBottom: "25px",
            }}
          >
            {(selectedOrder.items ||
              []).map((item) => (
              <div
                key={item.id}
                style={{
                  display: "flex",
                  justifyContent:
                    "space-between",
                  gap: "15px",
                  padding: "16px",
                  borderBottom:
                    "1px solid #e5e7eb",
                }}
              >
                <div>
                  <strong
                    style={{
                      color: "#111827",
                    }}
                  >
                    {item.product_name}
                  </strong>

                  <p
                    style={{
                      margin:
                        "5px 0 0",
                      color: "#6b7280",
                      fontSize:
                        "14px",
                    }}
                  >
                    Quantity:{" "}
                    {item.quantity}
                  </p>
                </div>

                <strong
                  style={{
                    color: "#111827",
                    whiteSpace:
                      "nowrap",
                  }}
                >
                  ₹
                  {Number(
                    item.total_price ||
                      0
                  ).toFixed(2)}
                </strong>
              </div>
            ))}
          </div>

          {/* DELIVERY */}

          <h2
            style={{
              fontSize: "20px",
              color: "#111827",
              marginBottom: "15px",
            }}
          >
            Delivery Address
          </h2>

          <div
            style={{
              background: "#f9fafb",
              padding: "18px",
              borderRadius: "12px",
              marginBottom: "25px",
            }}
          >
            <strong>
              {
                selectedOrder
                  .shipping?.name
              }
            </strong>

            <p
              style={{
                margin:
                  "7px 0",
                color: "#4b5563",
              }}
            >
              {
                selectedOrder
                  .shipping?.phone
              }
            </p>

            <p
              style={{
                margin: 0,
                color: "#4b5563",
              }}
            >
              {
                selectedOrder
                  .shipping?.address
              }
            </p>

            <p
              style={{
                margin:
                  "5px 0 0",
                color: "#4b5563",
              }}
            >
              {[
                selectedOrder
                  .shipping?.city,
                selectedOrder
                  .shipping?.state,
                selectedOrder
                  .shipping?.pincode,
              ]
                .filter(Boolean)
                .join(", ")}
            </p>
          </div>

          {/* TOTAL */}

          <div
            style={{
              background: "#f9fafb",
              borderRadius: "12px",
              padding: "18px",
              marginBottom: "25px",
            }}
          >
            <div
              style={{
                display: "flex",
                justifyContent:
                  "space-between",
                marginBottom: "8px",
              }}
            >
              <span>
                Subtotal
              </span>

              <span>
                ₹
                {Number(
                  selectedOrder.subtotal ||
                    0
                ).toFixed(2)}
              </span>
            </div>

            <div
              style={{
                display: "flex",
                justifyContent:
                  "space-between",
                marginBottom: "8px",
              }}
            >
              <span>
                Shipping
              </span>

              <span>
                ₹
                {Number(
                  selectedOrder.shipping_fee ||
                    0
                ).toFixed(2)}
              </span>
            </div>

            <div
              style={{
                display: "flex",
                justifyContent:
                  "space-between",
                paddingTop: "12px",
                borderTop:
                  "1px solid #e5e7eb",
                fontWeight: "700",
                fontSize: "18px",
              }}
            >
              <span>
                Total
              </span>

              <span>
                ₹
                {Number(
                  selectedOrder.total_amount ||
                    0
                ).toFixed(2)}
              </span>
            </div>
          </div>

          {/* ACTIONS */}

          <div
            style={{
              display: "flex",
              gap: "10px",
              flexWrap: "wrap",
            }}
          >
            {canCancel && (
              <button
                type="button"
                disabled={
                  cancellingId ===
                  selectedOrder.id
                }
                onClick={() =>
                  handleCancelOrder(
                    selectedOrder.id
                  )
                }
                style={{
                  border:
                    "1px solid #dc2626",
                  background:
                    "#ffffff",
                  color: "#dc2626",
                  padding:
                    "11px 18px",
                  borderRadius: "8px",
                  cursor:
                    cancellingId ===
                    selectedOrder.id
                      ? "not-allowed"
                      : "pointer",
                  fontWeight: "600",
                  opacity:
                    cancellingId ===
                    selectedOrder.id
                      ? 0.6
                      : 1,
                }}
              >
                {cancellingId ===
                selectedOrder.id
                  ? "Cancelling..."
                  : "Cancel Order"}
              </button>
            )}

            <button
              type="button"
              onClick={() =>
                setSelectedOrder(null)
              }
              style={{
                border: "none",
                background: "#111827",
                color: "#ffffff",
                padding:
                  "11px 18px",
                borderRadius: "8px",
                cursor: "pointer",
                fontWeight: "600",
              }}
            >
              Back to Orders
            </button>
          </div>
        </div>
      </main>
    );
  }

  // =====================================================
  // NO ORDERS
  // =====================================================

  if (orders.length === 0) {
    return (
      <main
        style={{
          maxWidth: "1000px",
          margin: "0 auto",
          padding: "25px 20px",
        }}
      >
        <button
          type="button"
          onClick={onBack}
          style={{
            border: "none",
            background: "transparent",
            cursor: "pointer",
            color: "#2563eb",
            fontWeight: "600",
            marginBottom: "15px",
          }}
        >
          ← Back to Account
        </button>

        <div
          style={{
            background: "#ffffff",
            borderRadius: "16px",
            padding: "50px 25px",
            textAlign: "center",
            boxShadow:
              "0 4px 20px rgba(0,0,0,0.06)",
          }}
        >
          <div
            style={{
              fontSize: "60px",
              marginBottom: "15px",
            }}
          >
            📦
          </div>

          <h2
            style={{
              color: "#111827",
              marginBottom: "8px",
            }}
          >
            No Orders Yet
          </h2>

          <p
            style={{
              color: "#6b7280",
              marginBottom: "20px",
            }}
          >
            Your orders will appear here
            after you place an order.
          </p>

          <button
            type="button"
            onClick={onBack}
            style={{
              border: "none",
              background: "#2563eb",
              color: "#ffffff",
              padding:
                "11px 20px",
              borderRadius: "8px",
              cursor: "pointer",
              fontWeight: "600",
            }}
          >
            Continue Shopping
          </button>
        </div>
      </main>
    );
  }

  // =====================================================
  // ORDER LIST
  // =====================================================

  return (
    <main
      style={{
        maxWidth: "1000px",
        margin: "0 auto",
        padding: "25px 20px",
      }}
    >
      <button
        type="button"
        onClick={onBack}
        style={{
          border: "none",
          background: "transparent",
          cursor: "pointer",
          color: "#2563eb",
          fontWeight: "600",
          marginBottom: "15px",
        }}
      >
        ← Back to Account
      </button>

      <div
        style={{
          display: "flex",
          justifyContent:
            "space-between",
          alignItems: "center",
          marginBottom: "20px",
          gap: "10px",
          flexWrap: "wrap",
        }}
      >
        <div>
          <h1
            style={{
              margin: 0,
              color: "#111827",
              fontSize: "28px",
            }}
          >
            My Orders
          </h1>

          <p
            style={{
              margin:
                "6px 0 0",
              color: "#6b7280",
            }}
          >
            {orders.length}{" "}
            {orders.length === 1
              ? "order"
              : "orders"}
          </p>
        </div>

        <button
          type="button"
          onClick={loadOrders}
          style={{
            border:
              "1px solid #d1d5db",
            background: "#ffffff",
            color: "#374151",
            padding:
              "9px 15px",
            borderRadius: "8px",
            cursor: "pointer",
            fontWeight: "600",
          }}
        >
          ↻ Refresh
        </button>
      </div>

      {/* =================================================
          ORDERS
      ================================================= */}

      <div
        style={{
          display: "grid",
          gap: "18px",
        }}
      >
        {orders.map((order) => {
          const status =
            order.status ||
            "placed";

          const currentStatusIndex =
            getStatusIndex(status);

          const canCancel =
            [
              "placed",
              "pending",
              "confirmed",
              "processing",
            ].includes(status);

          return (
            <div
              key={order.id}
              style={{
                background:
                  "#ffffff",
                border:
                  "1px solid #e5e7eb",
                borderRadius:
                  "14px",
                padding: "20px",
                boxShadow:
                  "0 3px 15px rgba(0,0,0,0.04)",
              }}
            >
              {/* ORDER HEADER */}

              <div
                style={{
                  display: "flex",
                  justifyContent:
                    "space-between",
                  alignItems:
                    "flex-start",
                  gap: "15px",
                  flexWrap:
                    "wrap",
                  marginBottom:
                    "18px",
                }}
              >
                <div>
                  <strong
                    style={{
                      color:
                        "#111827",
                      fontSize:
                        "17px",
                    }}
                  >
                    Order #{order.id}
                  </strong>

                  <p
                    style={{
                      margin:
                        "5px 0 0",
                      color:
                        "#6b7280",
                      fontSize:
                        "14px",
                    }}
                  >
                    {formatDate(
                      order.created_at
                    )}
                  </p>
                </div>

                <div
                  style={{
                    background:
                      status ===
                      "cancelled"
                        ? "#fee2e2"
                        : "#ecfdf5",

                    color:
                      status ===
                      "cancelled"
                        ? "#991b1b"
                        : "#065f46",

                    padding:
                      "7px 12px",

                    borderRadius:
                      "999px",

                    fontSize:
                      "13px",

                    fontWeight:
                      "700",
                  }}
                >
                  {formatStatus(
                    status
                  )}
                </div>
              </div>

              {/* MINI TRACKER */}

              {status !==
                "cancelled" && (
                <div
                  style={{
                    display:
                      "flex",
                    gap: "4px",
                    marginBottom:
                      "18px",
                  }}
                >
                  {STATUS_STEPS.map(
                    (
                      step,
                      index
                    ) => (
                      <div
                        key={
                          step.key
                        }
                        style={{
                          flex: 1,
                          height:
                            "5px",
                          borderRadius:
                            "999px",
                          background:
                            index <=
                            currentStatusIndex
                              ? "#16a34a"
                              : "#e5e7eb",
                        }}
                      />
                    )
                  )}
                </div>
              )}

              {/* ITEMS */}

              <div
                style={{
                  borderTop:
                    "1px solid #f3f4f6",
                  borderBottom:
                    "1px solid #f3f4f6",
                  padding:
                    "12px 0",
                  marginBottom:
                    "15px",
                }}
              >
                {(order.items ||
                  [])
                  .slice(0, 3)
                  .map(
                    (item) => (
                      <div
                        key={
                          item.id
                        }
                        style={{
                          display:
                            "flex",
                          justifyContent:
                            "space-between",
                          gap:
                            "10px",
                          padding:
                            "5px 0",
                        }}
                      >
                        <span
                          style={{
                            color:
                              "#374151",
                          }}
                        >
                          {item.product_name}
                          {" × "}
                          {item.quantity}
                        </span>

                        <strong>
                          ₹
                          {Number(
                            item.total_price ||
                              0
                          ).toFixed(
                            2
                          )}
                        </strong>
                      </div>
                    )
                  )}

                {order.items &&
                  order.items
                    .length >
                    3 && (
                    <p
                      style={{
                        margin:
                          "7px 0 0",
                        color:
                          "#6b7280",
                        fontSize:
                          "13px",
                      }}
                    >
                      +
                      {order
                        .items
                        .length -
                        3}{" "}
                      more item(s)
                    </p>
                  )}
              </div>

              {/* BOTTOM */}

              <div
                style={{
                  display:
                    "flex",
                  justifyContent:
                    "space-between",
                  alignItems:
                    "center",
                  gap:
                    "12px",
                  flexWrap:
                    "wrap",
                }}
              >
                <div>
                  <span
                    style={{
                      color:
                        "#6b7280",
                      fontSize:
                        "13px",
                    }}
                  >
                    Total Amount
                  </span>

                  <div
                    style={{
                      fontSize:
                        "19px",
                      fontWeight:
                        "700",
                      color:
                        "#111827",
                    }}
                  >
                    ₹
                    {Number(
                      order.total_amount ||
                        0
                    ).toFixed(2)}
                  </div>
                </div>

                <div
                  style={{
                    display:
                      "flex",
                    gap:
                      "8px",
                    flexWrap:
                      "wrap",
                  }}
                >
                  {canCancel && (
                    <button
                      type="button"
                      disabled={
                        cancellingId ===
                        order.id
                      }
                      onClick={() =>
                        handleCancelOrder(
                          order.id
                        )
                      }
                      style={{
                        border:
                          "1px solid #dc2626",
                        background:
                          "#ffffff",
                        color:
                          "#dc2626",
                        padding:
                          "9px 13px",
                        borderRadius:
                          "7px",
                        cursor:
                          "pointer",
                        fontWeight:
                          "600",
                        opacity:
                          cancellingId ===
                          order.id
                            ? 0.6
                            : 1,
                      }}
                    >
                      {cancellingId ===
                      order.id
                        ? "Cancelling..."
                        : "Cancel"}
                    </button>
                  )}

                  <button
                    type="button"
                    onClick={() =>
                      setSelectedOrder(
                        order
                      )
                    }
                    style={{
                      border:
                        "none",
                      background:
                        "#2563eb",
                      color:
                        "#ffffff",
                      padding:
                        "9px 15px",
                      borderRadius:
                        "7px",
                      cursor:
                        "pointer",
                      fontWeight:
                        "600",
                    }}
                  >
                    View Details
                  </button>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </main>
  );
}

export default Orders;