import React, { useState } from "react";
import { getToken } from "./auth";

// =========================================================
// API
// =========================================================

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL ||
  "http://127.0.0.1:5000/api";

// =========================================================
// FORMAT MONEY
// =========================================================

function formatMoney(amount) {
  const value = Number(amount || 0);

  return value.toLocaleString("en-IN", {
    style: "currency",
    currency: "INR",
    maximumFractionDigits: 2,
  });
}

// =========================================================
// PRODUCT DETAIL
// =========================================================

function ProductDetail({
  product,
  onBack,
  onGoToCart,
}) {
  // =======================================================
  // ADD TO CART STATE
  // =======================================================

  const [addingToCart, setAddingToCart] =
    useState(false);

  const [cartMessage, setCartMessage] =
    useState("");

  const [cartMessageType, setCartMessageType] =
    useState("");

  // =======================================================
  // ADD TO CART
  // =======================================================

  async function handleAddToCart() {
    if (!product?.id) {
      setCartMessage(
        "This product does not have a valid product ID."
      );

      setCartMessageType("error");

      return;
    }

    // Use the same authentication method as Cart.jsx
    const token = getToken();

    if (!token) {
      setCartMessage(
        "Please login before adding products to your cart."
      );

      setCartMessageType("error");

      return;
    }

    try {
      setAddingToCart(true);
      setCartMessage("");
      setCartMessageType("");

      const response =
        await fetch(
          `${API_BASE_URL}/cart/items`,
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
              product_id:
                product.id,

              quantity: 1,
            }),
          }
        );

      let data;

      try {
        data =
          await response.json();
      } catch {
        throw new Error(
          `Invalid server response. HTTP ${response.status}`
        );
      }

      console.log(
        "Product detail add-to-cart response:",
        data
      );

      if (!response.ok) {
        throw new Error(
          data?.message ||
            data?.msg ||
            "Unable to add product to cart."
        );
      }

      setCartMessage(
        `${product.name || "Product"} added to cart successfully.`
      );

      setCartMessageType("success");
    } catch (error) {
      console.error(
        "Product detail add-to-cart error:",
        error
      );

      setCartMessage(
        error.message ||
          "Unable to add product to cart."
      );

      setCartMessageType("error");
    } finally {
      setAddingToCart(false);
    }
  }

  // =======================================================
  // PRODUCT NOT FOUND
  // =======================================================

  if (!product) {
    return (
      <main
        style={{
          maxWidth: "1000px",
          margin: "0 auto",
          padding: "30px 20px",
        }}
      >
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
            🛍️
          </div>

          <h2
            style={{
              margin: "0 0 10px",
              color: "#111827",
            }}
          >
            Product Not Found
          </h2>

          <p
            style={{
              color: "#6b7280",
              marginBottom: "20px",
            }}
          >
            The product you're looking for
            could not be found.
          </p>

          <button
            type="button"
            onClick={onBack}
            style={{
              border: "none",
              background: "#111827",
              color: "#ffffff",
              padding: "12px 22px",
              borderRadius: "8px",
              cursor: "pointer",
              fontWeight: "700",
            }}
          >
            ← Back to Products
          </button>
        </div>
      </main>
    );
  }

  // =======================================================
  // PRODUCT INFORMATION
  // =======================================================

  const productName =
    product.name ||
    product.product_name ||
    "Product";

  const productImage =
    product.image ||
    product.image_url ||
    "";

  const productCategory =
    typeof product.category === "object"
      ? product.category?.name
      : product.category;

  const productDescription =
    product.description ||
    "No product description is available.";

  const productPrice = Number(
    product.price || 0
  );

  // =======================================================
  // RENDER
  // =======================================================

  return (
    <main
      style={{
        maxWidth: "1100px",
        margin: "0 auto",
        padding: "25px 20px 40px",
      }}
    >
      {/* =================================================
          BACK BUTTON
      ================================================= */}

      <button
        type="button"
        onClick={onBack}
        style={{
          border:
            "1px solid #d1d5db",
          background: "#ffffff",
          color: "#111827",
          padding: "10px 16px",
          borderRadius: "8px",
          cursor: "pointer",
          fontWeight: "600",
          marginBottom: "20px",
        }}
      >
        ← Back to Products
      </button>

      {/* =================================================
          PRODUCT CARD
      ================================================= */}

      <div
        style={{
          background: "#ffffff",
          borderRadius: "18px",
          padding: "25px",
          boxShadow:
            "0 4px 25px rgba(0,0,0,0.07)",
          display: "grid",
          gridTemplateColumns:
            "minmax(280px, 1fr) minmax(280px, 1fr)",
          gap: "35px",
        }}
      >
        {/* =================================================
            PRODUCT IMAGE
        ================================================= */}

        <div
          style={{
            background: "#f9fafb",
            borderRadius: "16px",
            minHeight: "450px",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            overflow: "hidden",
            border:
              "1px solid #f3f4f6",
          }}
        >
          {productImage ? (
            <img
              src={productImage}
              alt={productName}
              style={{
                width: "100%",
                height: "450px",
                objectFit: "contain",
                display: "block",
              }}
              onError={(event) => {
                event.currentTarget.style.display =
                  "none";

                if (
                  event.currentTarget
                    .parentElement
                ) {
                  event.currentTarget.parentElement.innerHTML =
                    `
                    <div style="
                      font-size: 80px;
                      text-align: center;
                    ">
                      🛍️
                    </div>
                  `;
                }
              }}
            />
          ) : (
            <div
              style={{
                fontSize: "90px",
              }}
            >
              🛍️
            </div>
          )}
        </div>

        {/* =================================================
            PRODUCT INFORMATION
        ================================================= */}

        <div
          style={{
            display: "flex",
            flexDirection: "column",
            justifyContent: "center",
          }}
        >
          {/* CATEGORY */}

          {productCategory && (
            <div
              style={{
                display:
                  "inline-block",
                color: "#4f46e5",
                background: "#eef2ff",
                padding: "6px 10px",
                borderRadius: "6px",
                fontSize: "13px",
                fontWeight: "700",
                marginBottom: "12px",
                width: "fit-content",
              }}
            >
              {productCategory}
            </div>
          )}

          {/* PRODUCT NAME */}

          <h1
            style={{
              margin: "0 0 15px",
              color: "#111827",
              fontSize: "36px",
              lineHeight: "1.2",
            }}
          >
            {productName}
          </h1>

          {/* PRICE */}

          <div
            style={{
              fontSize: "30px",
              fontWeight: "800",
              color: "#111827",
              marginBottom: "20px",
            }}
          >
            {formatMoney(productPrice)}
          </div>

          {/* DESCRIPTION */}

          <div
            style={{
              borderTop:
                "1px solid #e5e7eb",
              borderBottom:
                "1px solid #e5e7eb",
              padding: "20px 0",
              marginBottom: "20px",
            }}
          >
            <h3
              style={{
                margin:
                  "0 0 10px",
                color: "#111827",
                fontSize: "18px",
              }}
            >
              Product Description
            </h3>

            <p
              style={{
                margin: 0,
                color: "#4b5563",
                lineHeight: "1.8",
                fontSize: "15px",
              }}
            >
              {productDescription}
            </p>
          </div>

          {/* EXTRA INFORMATION */}

          <div
            style={{
              display: "grid",
              gridTemplateColumns:
                "repeat(auto-fit, minmax(140px, 1fr))",
              gap: "10px",
              marginBottom: "20px",
            }}
          >
            <div
              style={{
                background: "#f9fafb",
                padding: "12px",
                borderRadius: "8px",
              }}
            >
              <div
                style={{
                  fontSize: "12px",
                  color: "#6b7280",
                }}
              >
                Category
              </div>

              <strong
                style={{
                  color: "#111827",
                }}
              >
                {productCategory ||
                  "General"}
              </strong>
            </div>

            <div
              style={{
                background: "#f9fafb",
                padding: "12px",
                borderRadius: "8px",
              }}
            >
              <div
                style={{
                  fontSize: "12px",
                  color: "#6b7280",
                }}
              >
                Product ID
              </div>

              <strong
                style={{
                  color: "#111827",
                }}
              >
                #{product.id || "N/A"}
              </strong>
            </div>
          </div>

          {/* =================================================
              CART MESSAGE
          ================================================= */}

          {cartMessage && (
            <div
              role="status"
              style={{
                padding: "11px 13px",
                borderRadius: "8px",
                marginBottom: "12px",
                fontSize: "14px",
                fontWeight: "600",

                background:
                  cartMessageType ===
                  "success"
                    ? "#ecfdf5"
                    : "#fef2f2",

                color:
                  cartMessageType ===
                  "success"
                    ? "#047857"
                    : "#b91c1c",

                border:
                  cartMessageType ===
                  "success"
                    ? "1px solid #a7f3d0"
                    : "1px solid #fecaca",
              }}
            >
              {cartMessage}
            </div>
          )}

          {/* =================================================
              ADD TO CART
          ================================================= */}

          <button
            type="button"
            onClick={
              handleAddToCart
            }
            disabled={
              addingToCart
            }
            style={{
              width: "100%",
              border: "none",
              background:
                addingToCart
                  ? "#6b7280"
                  : "#111827",
              color: "#ffffff",
              padding: "15px",
              borderRadius: "10px",
              cursor:
                addingToCart
                  ? "not-allowed"
                  : "pointer",
              fontWeight: "700",
              fontSize: "16px",
              marginBottom: "10px",
              opacity:
                addingToCart
                  ? 0.85
                  : 1,
            }}
          >
            {addingToCart
              ? "Adding..."
              : "🛒 Add to Cart"}
          </button>

          {/* =================================================
              CONTINUE SHOPPING
          ================================================= */}

          <button
            type="button"
            onClick={onBack}
            style={{
              width: "100%",
              border:
                "1px solid #d1d5db",
              background: "#ffffff",
              color: "#111827",
              padding: "14px",
              borderRadius: "10px",
              cursor: "pointer",
              fontWeight: "600",
              fontSize: "15px",
            }}
          >
            Continue Shopping
          </button>
        </div>
      </div>
    </main>
  );
}

export default ProductDetail;