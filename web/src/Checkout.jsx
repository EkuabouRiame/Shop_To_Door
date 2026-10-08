import { useEffect, useState } from "react";
import { getToken } from "./auth";

// =========================================================
// API
// =========================================================

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL ||
  "http://127.0.0.1:5000/api";

// =========================================================
// RAZORPAY SCRIPT LOADER
// =========================================================

function loadRazorpayScript() {
  return new Promise((resolve) => {
    // Already loaded
    if (window.Razorpay) {
      resolve(true);
      return;
    }

    const existingScript = document.querySelector(
      'script[src="https://checkout.razorpay.com/v1/checkout.js"]'
    );

    if (existingScript) {
      existingScript.addEventListener("load", () => resolve(true));
      existingScript.addEventListener("error", () => resolve(false));
      return;
    }

    const script = document.createElement("script");

    script.src = "https://checkout.razorpay.com/v1/checkout.js";
    script.async = true;

    script.onload = () => resolve(true);

    script.onerror = () => resolve(false);

    document.body.appendChild(script);
  });
}

// =========================================================
// CHECKOUT
// =========================================================

function Checkout({
  user,
  checkoutData,
  onBackToCart,
  onOrderPlaced,
}) {
  // =======================================================
  // STATE
  // =======================================================

  const [address, setAddress] = useState({
    fullName: user?.name || "",
    phone: user?.phone || "",
    address: "",
    city: "",
    state: "",
    pincode: "",
    landmark: "",
  });

  const [paymentMethod, setPaymentMethod] =
    useState("cod");

  const [placingOrder, setPlacingOrder] =
    useState(false);

  const [error, setError] = useState("");

  const [success, setSuccess] = useState("");

  // =======================================================
  // LOAD SAVED ADDRESS
  // =======================================================

  useEffect(() => {
    try {
      const savedAddress = localStorage.getItem(
        "shop_to_door_address"
      );

      if (!savedAddress) {
        return;
      }

      const parsed = JSON.parse(savedAddress);

      setAddress({
        fullName:
          parsed.fullName ||
          user?.name ||
          "",

        phone:
          parsed.phone ||
          user?.phone ||
          "",

        address:
          parsed.address || "",

        city:
          parsed.city || "",

        state:
          parsed.state || "",

        pincode:
          parsed.pincode || "",

        landmark:
          parsed.landmark || "",
      });
    } catch (loadError) {
      console.error(
        "Unable to load saved address:",
        loadError
      );
    }
  }, [user]);

  // =======================================================
  // CHECKOUT DATA
  // =======================================================

  const items = Array.isArray(
    checkoutData?.items
  )
    ? checkoutData.items
    : [];

  const total = Number(
    checkoutData?.total || 0
  );

  const quantity = Number(
    checkoutData?.quantity || 0
  );

  // =======================================================
  // HELPERS
  // =======================================================

  function formatPrice(price) {
    return `₹${Number(
      price || 0
    ).toLocaleString("en-IN", {
      minimumFractionDigits: 0,
      maximumFractionDigits: 2,
    })}`;
  }

  function handleAddressChange(event) {
    const {
      name,
      value,
    } = event.target;

    setAddress((previous) => ({
      ...previous,
      [name]: value,
    }));

    setError("");
  }

  function saveAddress() {
    try {
      localStorage.setItem(
        "shop_to_door_address",
        JSON.stringify(address)
      );
    } catch (saveError) {
      console.error(
        "Unable to save address:",
        saveError
      );
    }
  }

  // =======================================================
  // VALIDATION
  // =======================================================

  function validateCheckout() {
    if (items.length === 0) {
      setError(
        "Your cart is empty."
      );

      return false;
    }

    if (!address.fullName.trim()) {
      setError(
        "Please enter your full name."
      );

      return false;
    }

    if (!address.phone.trim()) {
      setError(
        "Please enter your phone number."
      );

      return false;
    }

    const phoneDigits =
      address.phone.replace(/\D/g, "");

    if (phoneDigits.length !== 10) {
      setError(
        "Please enter a valid 10-digit phone number."
      );

      return false;
    }

    if (!address.address.trim()) {
      setError(
        "Please enter your delivery address."
      );

      return false;
    }

    if (!address.city.trim()) {
      setError(
        "Please enter your city."
      );

      return false;
    }

    if (!address.state.trim()) {
      setError(
        "Please enter your state."
      );

      return false;
    }

    if (!address.pincode.trim()) {
      setError(
        "Please enter your PIN code."
      );

      return false;
    }

    if (!/^\d{6}$/.test(address.pincode.trim())) {
      setError(
        "Please enter a valid 6-digit PIN code."
      );

      return false;
    }

    if (!paymentMethod) {
      setError(
        "Please select a payment method."
      );

      return false;
    }

    return true;
  }

  // =======================================================
  // FINISH ORDER
  // =======================================================

  function finishOrder(realOrder) {
    setSuccess(
      "Your order has been placed successfully!"
    );

    setTimeout(() => {
      if (
        typeof onOrderPlaced ===
        "function"
      ) {
        onOrderPlaced(realOrder);
      }
    }, 800);
  }

  // =======================================================
  // CREATE RAZORPAY PAYMENT
  // =======================================================

  async function startRazorpayPayment(
    realOrder,
    token
  ) {
    // -----------------------------------------------------
    // Load Razorpay Checkout
    // -----------------------------------------------------

    const razorpayLoaded =
      await loadRazorpayScript();

    if (!razorpayLoaded) {
      throw new Error(
        "Unable to load Razorpay Checkout. Please check your internet connection and try again."
      );
    }

    // -----------------------------------------------------
    // Ask backend to create Razorpay order
    // -----------------------------------------------------

    const response = await fetch(
      `${API_BASE_URL}/payments/create/${realOrder.id}`,
      {
        method: "POST",

        headers: {
          Accept: "application/json",

          Authorization:
            `Bearer ${token}`,
        },
      }
    );

    let data = null;

    try {
      data = await response.json();
    } catch (jsonError) {
      console.error(
        "Unable to parse Razorpay response:",
        jsonError
      );
    }

    if (response.status === 401) {
      throw new Error(
        "Your login session has expired. Please login again."
      );
    }

    if (!response.ok) {
      throw new Error(
        data?.message ||
          "Unable to create Razorpay payment order."
      );
    }

    if (
      !data ||
      !data.success ||
      !data.razorpay_order_id ||
      !data.key_id
    ) {
      throw new Error(
        data?.message ||
          "Invalid Razorpay order response."
      );
    }

    // -----------------------------------------------------
    // Razorpay Checkout options
    // -----------------------------------------------------

    const options = {
      key: data.key_id,

      amount: data.amount,

      currency:
        data.currency || "INR",

      name: "Shop To Door",

      description:
        `Payment for Order #${realOrder.id}`,

      order_id:
        data.razorpay_order_id,

      prefill: {
        name:
          address.fullName.trim(),

        contact:
          address.phone.trim(),

        email:
          user?.email || "",
      },

      notes: {
        internal_order_id:
          String(realOrder.id),
      },

      theme: {
        color: "#2563eb",
      },

      modal: {
        ondismiss: function () {
          setPlacingOrder(false);

          setError(
            "Payment window was closed. Your order is still pending payment."
          );
        },
      },

      handler: async function (
        paymentResponse
      ) {
        try {
          setError("");

          setSuccess(
            "Payment completed. Verifying payment..."
          );

          // ------------------------------------------------
          // Send payment details to backend
          // ------------------------------------------------

          const verifyResponse =
            await fetch(
              `${API_BASE_URL}/payments/verify`,
              {
                method: "POST",

                headers: {
                  "Content-Type":
                    "application/json",

                  Accept:
                    "application/json",

                  Authorization:
                    `Bearer ${token}`,
                },

                body: JSON.stringify({
                  order_id:
                    realOrder.id,

                  razorpay_order_id:
                    paymentResponse.razorpay_order_id,

                  razorpay_payment_id:
                    paymentResponse.razorpay_payment_id,

                  razorpay_signature:
                    paymentResponse.razorpay_signature,
                }),
              }
            );

          let verifyData = null;

          try {
            verifyData =
              await verifyResponse.json();
          } catch (jsonError) {
            console.error(
              "Unable to parse verification response:",
              jsonError
            );
          }

          // ----------------------------------------------
          // Authentication error
          // ----------------------------------------------

          if (
            verifyResponse.status ===
            401
          ) {
            setSuccess("");

            setError(
              "Your login session has expired. Please login again."
            );

            setPlacingOrder(false);

            return;
          }

          // ----------------------------------------------
          // Verification failed
          // ----------------------------------------------

          if (
            !verifyResponse.ok ||
            !verifyData?.success
          ) {
            setSuccess("");

            setError(
              verifyData?.message ||
                "Payment verification failed. Please contact support."
            );

            setPlacingOrder(false);

            return;
          }

          // ----------------------------------------------
          // Payment verified successfully
          // ----------------------------------------------

          console.log(
            "Razorpay payment verified:",
            verifyData
          );

          const paidOrder = {
            ...realOrder,

            payment_status:
              "paid",

            razorpay_payment_id:
              paymentResponse.razorpay_payment_id,
          };

          finishOrder(
            paidOrder
          );

        } catch (verificationError) {
          console.error(
            "Payment verification error:",
            verificationError
          );

          setSuccess("");

          setError(
            verificationError?.message ||
              "Unable to verify payment."
          );

          setPlacingOrder(false);
        }
      },
    };

    // -----------------------------------------------------
    // Create Razorpay checkout
    // -----------------------------------------------------

    const razorpay =
      new window.Razorpay(
        options
      );

    // -----------------------------------------------------
    // Handle payment failure
    // -----------------------------------------------------

    razorpay.on(
      "payment.failed",
      function (response) {
        console.error(
          "Razorpay payment failed:",
          response
        );

        setSuccess("");

        setError(
          response?.error?.description ||
            "Payment failed. Please try again."
        );

        setPlacingOrder(false);
      }
    );

    // -----------------------------------------------------
    // Open Razorpay
    // -----------------------------------------------------

    razorpay.open();
  }

  // =======================================================
  // PLACE ORDER
  // =======================================================

  async function handlePlaceOrder() {
    setError("");
    setSuccess("");

    if (!validateCheckout()) {
      return;
    }

    const token = getToken();

    if (!token) {
      setError(
        "Your login session has expired. Please login again."
      );

      return;
    }

    try {
      setPlacingOrder(true);

      // ---------------------------------------------------
      // Save latest address
      // ---------------------------------------------------

      saveAddress();

      // ---------------------------------------------------
      // Backend order request
      // ---------------------------------------------------

      const requestBody = {
        payment_method:
          paymentMethod,

        shipping_name:
          address.fullName.trim(),

        shipping_phone:
          address.phone.trim(),

        shipping_address:
          address.address.trim(),

        shipping_city:
          address.city.trim(),

        shipping_state:
          address.state.trim(),

        shipping_pincode:
          address.pincode.trim(),

        notes:
          address.landmark.trim(),
      };

      const response = await fetch(
        `${API_BASE_URL}/orders/`,
        {
          method: "POST",

          headers: {
            "Content-Type":
              "application/json",

            Accept:
              "application/json",

            Authorization:
              `Bearer ${token}`,
          },

          body: JSON.stringify(
            requestBody
          ),
        }
      );

      // ---------------------------------------------------
      // Read response
      // ---------------------------------------------------

      let data = null;

      try {
        data = await response.json();
      } catch (jsonError) {
        console.error(
          "Unable to parse backend response:",
          jsonError
        );
      }

      // ---------------------------------------------------
      // Unauthorized
      // ---------------------------------------------------

      if (response.status === 401) {
        setError(
          "Your login session has expired. Please login again."
        );

        return;
      }

      // ---------------------------------------------------
      // Backend error
      // ---------------------------------------------------

      if (!response.ok) {
        const backendMessage =
          data?.message ||
          data?.error ||
          "Unable to place your order.";

        throw new Error(
          backendMessage
        );
      }

      // ---------------------------------------------------
      // Validate order
      // ---------------------------------------------------

      if (
        !data ||
        data.status !== "success" ||
        !data.order
      ) {
        throw new Error(
          data?.message ||
            "The order could not be created."
        );
      }

      const realOrder =
        data.order;

      console.log(
        "Order successfully created:",
        realOrder
      );

      // ===================================================
      // COD
      // ===================================================

      if (
        paymentMethod === "cod"
      ) {
        finishOrder(
          realOrder
        );

        return;
      }

      // ===================================================
      // RAZORPAY / ONLINE PAYMENT
      // ===================================================

      if (
        paymentMethod ===
          "online" ||
        paymentMethod ===
          "razorpay"
      ) {
        setSuccess(
          "Preparing secure payment..."
        );

        await startRazorpayPayment(
          realOrder,
          token
        );

        return;
      }

      // ---------------------------------------------------
      // Unknown payment method
      // ---------------------------------------------------

      throw new Error(
        "Unsupported payment method."
      );

    } catch (placeOrderError) {
      console.error(
        "Place order error:",
        placeOrderError
      );

      setSuccess("");

      setError(
        placeOrderError?.message ||
          "Unable to place your order. Please try again."
      );

      setPlacingOrder(false);
    }
  }

  // =======================================================
  // EMPTY CHECKOUT
  // =======================================================

  if (items.length === 0) {
    return (
      <div
        style={{
          background: "#ffffff",
          borderRadius: "16px",
          padding: "40px",
          textAlign: "center",
          boxShadow:
            "0 4px 20px rgba(0, 0, 0, 0.06)",
        }}
      >
        <div
          style={{
            fontSize: "60px",
            marginBottom: "15px",
          }}
        >
          🛒
        </div>

        <h2>
          No Items to Checkout
        </h2>

        <p
          style={{
            color: "#6b7280",
          }}
        >
          Your cart does not contain
          any products.
        </p>

        <button
          type="button"
          onClick={onBackToCart}
          style={{
            border: "none",
            background: "#2563eb",
            color: "#ffffff",
            padding: "12px 20px",
            borderRadius: "8px",
            cursor: "pointer",
            fontWeight: "600",
          }}
        >
          ← Back to Cart
        </button>
      </div>
    );
  }

  // =======================================================
  // COMMON STYLES
  // =======================================================

  const inputStyle = {
    width: "100%",
    boxSizing: "border-box",
    padding: "12px",
    border: "1px solid #d1d5db",
    borderRadius: "8px",
    fontSize: "14px",
    outline: "none",
    background: "#ffffff",
  };

  const labelStyle = {
    display: "block",
    marginBottom: "6px",
    fontWeight: "600",
    color: "#374151",
  };

  const sectionStyle = {
    background: "#ffffff",
    borderRadius: "16px",
    padding: "25px",
    boxShadow:
      "0 4px 20px rgba(0, 0, 0, 0.06)",
  };

  // =======================================================
  // UI
  // =======================================================

  return (
    <div
      style={{
        width: "100%",
        boxSizing: "border-box",
      }}
    >
      {/* =================================================
          BACK BUTTON
      ================================================= */}

      <button
        type="button"
        onClick={onBackToCart}
        disabled={placingOrder}
        style={{
          border: "none",
          background: "#ffffff",
          padding: "10px 15px",
          borderRadius: "8px",
          cursor: placingOrder
            ? "not-allowed"
            : "pointer",
          marginBottom: "20px",
          boxShadow:
            "0 2px 8px rgba(0, 0, 0, 0.05)",
          color: "#374151",
          fontWeight: "600",
          opacity: placingOrder
            ? 0.6
            : 1,
        }}
      >
        ← Back to Cart
      </button>

      {/* =================================================
          HEADER
      ================================================= */}

      <h1
        style={{
          color: "#111827",
          marginBottom: "8px",
        }}
      >
        Checkout
      </h1>

      <p
        style={{
          color: "#6b7280",
          marginTop: 0,
          marginBottom: "25px",
        }}
      >
        Complete your delivery
        information and place your
        order.
      </p>

      {/* =================================================
          ERROR
      ================================================= */}

      {error && (
        <div
          role="alert"
          style={{
            background: "#fee2e2",
            color: "#991b1b",
            padding: "13px 15px",
            borderRadius: "8px",
            marginBottom: "20px",
            border:
              "1px solid #fecaca",
          }}
        >
          ⚠️ {error}
        </div>
      )}

      {/* =================================================
          SUCCESS
      ================================================= */}

      {success && (
        <div
          role="status"
          style={{
            background: "#dcfce7",
            color: "#166534",
            padding: "13px 15px",
            borderRadius: "8px",
            marginBottom: "20px",
            border:
              "1px solid #bbf7d0",
          }}
        >
          ✓ {success}
        </div>
      )}

      {/* =================================================
          MAIN CHECKOUT GRID
      ================================================= */}

      <div
        style={{
          display: "grid",
          gridTemplateColumns:
            "minmax(0, 1fr) minmax(280px, 0.55fr)",
          gap: "25px",
          alignItems: "start",
        }}
      >
        {/* =================================================
            LEFT COLUMN
        ================================================= */}

        <div
          style={{
            display: "grid",
            gap: "20px",
            minWidth: 0,
          }}
        >
          {/* ===============================================
              DELIVERY ADDRESS
          =============================================== */}

          <section style={sectionStyle}>
            <h2
              style={{
                marginTop: 0,
                marginBottom: "20px",
                color: "#111827",
              }}
            >
              📍 Delivery Address
            </h2>

            <div
              style={{
                display: "grid",
                gap: "16px",
              }}
            >
              {/* FULL NAME */}

              <div>
                <label
                  style={labelStyle}
                  htmlFor="checkout-fullName"
                >
                  Full Name *
                </label>

                <input
                  id="checkout-fullName"
                  name="fullName"
                  type="text"
                  value={
                    address.fullName
                  }
                  onChange={
                    handleAddressChange
                  }
                  style={inputStyle}
                  placeholder="Enter your full name"
                  autoComplete="name"
                  disabled={
                    placingOrder
                  }
                />
              </div>

              {/* PHONE */}

              <div>
                <label
                  style={labelStyle}
                  htmlFor="checkout-phone"
                >
                  Phone Number *
                </label>

                <input
                  id="checkout-phone"
                  name="phone"
                  type="tel"
                  value={
                    address.phone
                  }
                  onChange={
                    handleAddressChange
                  }
                  style={inputStyle}
                  placeholder="10-digit phone number"
                  inputMode="tel"
                  autoComplete="tel"
                  maxLength={15}
                  disabled={
                    placingOrder
                  }
                />
              </div>

              {/* ADDRESS */}

              <div>
                <label
                  style={labelStyle}
                  htmlFor="checkout-address"
                >
                  Address *
                </label>

                <textarea
                  id="checkout-address"
                  name="address"
                  value={
                    address.address
                  }
                  onChange={
                    handleAddressChange
                  }
                  rows={4}
                  style={{
                    ...inputStyle,
                    resize: "vertical",
                    minHeight: "100px",
                  }}
                  placeholder="House number, street, locality"
                  autoComplete="street-address"
                  disabled={
                    placingOrder
                  }
                />
              </div>

              {/* CITY / STATE / PIN */}

              <div
                style={{
                  display: "grid",
                  gridTemplateColumns:
                    "repeat(auto-fit, minmax(150px, 1fr))",
                  gap: "15px",
                }}
              >
                {/* CITY */}

                <div>
                  <label
                    style={labelStyle}
                    htmlFor="checkout-city"
                  >
                    City *
                  </label>

                  <input
                    id="checkout-city"
                    name="city"
                    type="text"
                    value={
                      address.city
                    }
                    onChange={
                      handleAddressChange
                    }
                    style={inputStyle}
                    placeholder="City"
                    autoComplete="address-level2"
                    disabled={
                      placingOrder
                    }
                  />
                </div>

                {/* STATE */}

                <div>
                  <label
                    style={labelStyle}
                    htmlFor="checkout-state"
                  >
                    State *
                  </label>

                  <input
                    id="checkout-state"
                    name="state"
                    type="text"
                    value={
                      address.state
                    }
                    onChange={
                      handleAddressChange
                    }
                    style={inputStyle}
                    placeholder="State"
                    autoComplete="address-level1"
                    disabled={
                      placingOrder
                    }
                  />
                </div>

                {/* PIN CODE */}

                <div>
                  <label
                    style={labelStyle}
                    htmlFor="checkout-pincode"
                  >
                    PIN Code *
                  </label>

                  <input
                    id="checkout-pincode"
                    name="pincode"
                    type="text"
                    value={
                      address.pincode
                    }
                    onChange={
                      handleAddressChange
                    }
                    style={inputStyle}
                    placeholder="6-digit PIN"
                    inputMode="numeric"
                    maxLength={6}
                    autoComplete="postal-code"
                    disabled={
                      placingOrder
                    }
                  />
                </div>
              </div>

              {/* LANDMARK */}

              <div>
                <label
                  style={labelStyle}
                  htmlFor="checkout-landmark"
                >
                  Landmark
                </label>

                <input
                  id="checkout-landmark"
                  name="landmark"
                  type="text"
                  value={
                    address.landmark
                  }
                  onChange={
                    handleAddressChange
                  }
                  style={inputStyle}
                  placeholder="Nearby landmark (optional)"
                  disabled={
                    placingOrder
                  }
                />
              </div>
            </div>
          </section>

          {/* ===============================================
              PAYMENT METHOD
          =============================================== */}

          <section style={sectionStyle}>
            <h2
              style={{
                marginTop: 0,
                marginBottom: "20px",
                color: "#111827",
              }}
            >
              💳 Payment Method
            </h2>

            {/* CASH ON DELIVERY */}

            <label
              style={{
                display: "flex",
                alignItems: "flex-start",
                gap: "12px",
                border:
                  paymentMethod === "cod"
                    ? "2px solid #2563eb"
                    : "1px solid #e5e7eb",
                borderRadius: "10px",
                padding: "16px",
                cursor: placingOrder
                  ? "not-allowed"
                  : "pointer",
                background:
                  paymentMethod === "cod"
                    ? "#eff6ff"
                    : "#ffffff",
              }}
            >
              <input
                type="radio"
                name="payment"
                value="cod"
                checked={
                  paymentMethod ===
                  "cod"
                }
                onChange={(event) => {
                  setPaymentMethod(
                    event.target.value
                  );

                  setError("");
                }}
                disabled={
                  placingOrder
                }
                style={{
                  marginTop: "4px",
                }}
              />

              <div>
                <strong>
                  Cash on Delivery
                </strong>

                <p
                  style={{
                    margin:
                      "5px 0 0",
                    color:
                      "#6b7280",
                    fontSize:
                      "14px",
                    lineHeight:
                      "1.5",
                  }}
                >
                  Pay when your
                  order is
                  delivered.
                </p>
              </div>
            </label>

            {/* ONLINE PAYMENT */}

            <label
              style={{
                display: "flex",
                alignItems: "flex-start",
                gap: "12px",
                border:
                  paymentMethod ===
                  "online"
                    ? "2px solid #2563eb"
                    : "1px solid #e5e7eb",
                borderRadius: "10px",
                padding: "16px",
                cursor: placingOrder
                  ? "not-allowed"
                  : "pointer",
                marginTop: "12px",
                background:
                  paymentMethod ===
                  "online"
                    ? "#eff6ff"
                    : "#ffffff",
              }}
            >
              <input
                type="radio"
                name="payment"
                value="online"
                checked={
                  paymentMethod ===
                  "online"
                }
                onChange={(event) => {
                  setPaymentMethod(
                    event.target.value
                  );

                  setError("");
                }}
                disabled={
                  placingOrder
                }
                style={{
                  marginTop: "4px",
                }}
              />

              <div>
                <strong>
                  Online Payment
                </strong>

                <p
                  style={{
                    margin:
                      "5px 0 0",
                    color:
                      "#6b7280",
                    fontSize:
                      "14px",
                    lineHeight:
                      "1.5",
                  }}
                >
                  Pay securely
                  using Razorpay.
                  This is currently
                  running in Test
                  Mode.
                </p>
              </div>
            </label>
          </section>
        </div>

        {/* =================================================
            RIGHT COLUMN — ORDER SUMMARY
        ================================================= */}

        <aside
          style={{
            background: "#ffffff",
            borderRadius: "16px",
            padding: "25px",
            boxShadow:
              "0 4px 20px rgba(0, 0, 0, 0.06)",
            position: "sticky",
            top: "100px",
            minWidth: 0,
          }}
        >
          <h2
            style={{
              marginTop: 0,
              marginBottom: "20px",
              color: "#111827",
            }}
          >
            Order Summary
          </h2>

          {/* ITEMS */}

          <div
            style={{
              marginBottom: "20px",
            }}
          >
            {items.map(
              (item, index) => {
                const itemQuantity =
                  Number(
                    item.quantity ||
                      0
                  );

                const itemTotal =
                  Number(
                    item.total ||
                      item.total_price ||
                      0
                  );

                return (
                  <div
                    key={
                      item.id ||
                      item.product_id ||
                      index
                    }
                    style={{
                      display:
                        "flex",
                      justifyContent:
                        "space-between",
                      gap: "12px",
                      padding:
                        "12px 0",
                      borderBottom:
                        "1px solid #f0f0f0",
                    }}
                  >
                    <div
                      style={{
                        minWidth: 0,
                        flex: 1,
                      }}
                    >
                      <strong
                        style={{
                          fontSize:
                            "14px",
                          color:
                            "#111827",
                          display:
                            "block",
                          overflow:
                            "hidden",
                          textOverflow:
                            "ellipsis",
                          whiteSpace:
                            "nowrap",
                        }}
                      >
                        {item.name ||
                          item.product_name ||
                          "Product"}
                      </strong>

                      <div
                        style={{
                          color:
                            "#6b7280",
                          fontSize:
                            "13px",
                          marginTop:
                            "4px",
                        }}
                      >
                        Qty:{" "}
                        {
                          itemQuantity
                        }
                      </div>
                    </div>

                    <strong
                      style={{
                        whiteSpace:
                          "nowrap",
                        color:
                          "#111827",
                      }}
                    >
                      {formatPrice(
                        itemTotal
                      )}
                    </strong>
                  </div>
                );
              }
            )}
          </div>

          {/* QUANTITY */}

          <div
            style={{
              display: "flex",
              justifyContent:
                "space-between",
              marginBottom: "10px",
              color: "#374151",
            }}
          >
            <span>
              Total Items
            </span>

            <span
              style={{
                fontWeight: "600",
              }}
            >
              {quantity}
            </span>
          </div>

          {/* SHIPPING */}

          <div
            style={{
              display: "flex",
              justifyContent:
                "space-between",
              marginBottom: "10px",
              color: "#374151",
            }}
          >
            <span>
              Shipping
            </span>

            <span
              style={{
                color:
                  "#16a34a",
                fontWeight:
                  "600",
              }}
            >
              Free
            </span>
          </div>

          {/* DIVIDER */}

          <div
            style={{
              height: "1px",
              background:
                "#e5e7eb",
              margin:
                "15px 0",
            }}
          />

          {/* TOTAL */}

          <div
            style={{
              display: "flex",
              justifyContent:
                "space-between",
              gap: "15px",
              fontSize: "20px",
              fontWeight: "700",
              marginBottom:
                "20px",
              color: "#111827",
            }}
          >
            <span>
              Total
            </span>

            <span
              style={{
                whiteSpace:
                  "nowrap",
              }}
            >
              {formatPrice(
                total
              )}
            </span>
          </div>

          {/* PLACE ORDER */}

          <button
            type="button"
            onClick={
              handlePlaceOrder
            }
            disabled={
              placingOrder
            }
            style={{
              width: "100%",
              border: "none",
              background:
                placingOrder
                  ? "#9ca3af"
                  : "#2563eb",
              color: "#ffffff",
              padding: "15px",
              borderRadius: "9px",
              cursor:
                placingOrder
                  ? "not-allowed"
                  : "pointer",
              fontWeight: "700",
              fontSize: "16px",
              transition:
                "background 0.2s ease",
            }}
          >
            {placingOrder
              ? paymentMethod ===
                "online"
                ? "Opening Payment..."
                : "Placing Order..."
              : `Place Order • ${formatPrice(
                  total
                )}`}
          </button>

          {/* NOTE */}

          <p
            style={{
              textAlign: "center",
              color: "#6b7280",
              fontSize: "12px",
              lineHeight: "1.5",
              marginBottom: 0,
              marginTop: "12px",
            }}
          >
            By placing your
            order, you confirm
            that your delivery
            information is
            correct.
          </p>
        </aside>
      </div>
    </div>
  );
}

export default Checkout;