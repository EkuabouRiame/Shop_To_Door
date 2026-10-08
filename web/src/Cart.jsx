import { useEffect, useState } from "react";

import "./Cart.css";

import { getToken } from "./auth";

// =========================================================
// API BASE URL
// =========================================================

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL ||
  "http://127.0.0.1:5000/api";

// =========================================================
// CART COMPONENT
// =========================================================

function Cart({ onProceedToCheckout }) {
  const [cartItems, setCartItems] = useState([]);

  const [loading, setLoading] = useState(true);

  const [error, setError] = useState("");

  const [message, setMessage] = useState("");

  const [updatingId, setUpdatingId] =
    useState(null);

  // =======================================================
  // LOAD CART
  // =======================================================

  useEffect(() => {
    loadCart();
  }, []);

  async function loadCart() {
    const token = getToken();

    if (!token) {
      setError(
        "Please login to view your cart."
      );

      setLoading(false);

      return;
    }

    try {
      setLoading(true);

      setError("");

      const response = await fetch(
        `${API_BASE_URL}/cart/`,
        {
          method: "GET",

          headers: {
            Accept: "application/json",

            Authorization: `Bearer ${token}`,
          },
        }
      );

      let data;

      try {
        data = await response.json();
      } catch {
        throw new Error(
          `Server returned an invalid response. HTTP ${response.status}`
        );
      }

      console.log(
        "Cart response:",
        data
      );

      if (!response.ok) {
        throw new Error(
          data?.message ||
            data?.msg ||
            `Unable to load cart. HTTP ${response.status}`
        );
      }

      let items = [];

      if (
        data?.cart &&
        Array.isArray(data.cart.items)
      ) {
        items = data.cart.items;
      } else if (
        Array.isArray(data?.items)
      ) {
        items = data.items;
      } else if (
        Array.isArray(data?.data)
      ) {
        items = data.data;
      } else if (Array.isArray(data)) {
        items = data;
      }

      console.log(
        "Cart items:",
        items
      );

      setCartItems(items);
    } catch (error) {
      console.error(
        "Cart error:",
        error
      );

      setError(
        error.message ||
          "Unable to load your cart."
      );
    } finally {
      setLoading(false);
    }
  }

  // =======================================================
  // GET PRODUCT
  // =======================================================

  function getProduct(item) {
    return item?.product || {};
  }

  // =======================================================
  // PRODUCT NAME
  // =======================================================

  function getProductName(item) {
    const product = getProduct(item);

    return (
      product?.name ||
      item?.product_name ||
      item?.name ||
      "Unnamed Product"
    );
  }

  // =======================================================
  // PRODUCT IMAGE
  // =======================================================

  function getProductImage(item) {
    const product = getProduct(item);

    const image =
      product?.image_url ||
      product?.image ||
      product?.thumbnail ||
      product?.photo_url ||
      item?.image_url ||
      item?.image ||
      "";

    if (!image) {
      return "";
    }

    if (
      image.startsWith("http://") ||
      image.startsWith("https://") ||
      image.startsWith("data:")
    ) {
      return image;
    }

    const backendBase =
      API_BASE_URL.replace(
        /\/api\/?$/,
        ""
      );

    if (image.startsWith("/")) {
      return `${backendBase}${image}`;
    }

    return `${backendBase}/${image}`;
  }

  // =======================================================
  // PRODUCT PRICE
  // =======================================================

  function getProductPrice(item) {
    if (
      item?.unit_price !==
        undefined &&
      item?.unit_price !== null
    ) {
      return Number(item.unit_price);
    }

    const product = getProduct(item);

    if (
      product?.discount_price !==
        undefined &&
      product?.discount_price !== null
    ) {
      return Number(
        product.discount_price
      );
    }

    if (
      product?.price !== undefined &&
      product?.price !== null
    ) {
      return Number(product.price);
    }

    return 0;
  }

  // =======================================================
  // ORIGINAL PRICE
  // =======================================================

  function getOriginalPrice(item) {
    const product = getProduct(item);

    if (
      product?.price !== undefined &&
      product?.price !== null
    ) {
      return Number(product.price);
    }

    return getProductPrice(item);
  }

  // =======================================================
  // DISCOUNT PRICE
  // =======================================================

  function getDiscountPrice(item) {
    const product = getProduct(item);

    if (
      product?.discount_price !==
        undefined &&
      product?.discount_price !== null
    ) {
      return Number(
        product.discount_price
      );
    }

    return null;
  }

  // =======================================================
  // QUANTITY
  // =======================================================

  function getQuantity(item) {
    const quantity = Number(
      item?.quantity ?? 1
    );

    return quantity > 0 ? quantity : 1;
  }

  // =======================================================
  // ITEM TOTAL
  // =======================================================

  function getItemTotal(item) {
    if (
      item?.total !== undefined &&
      item?.total !== null
    ) {
      return Number(item.total);
    }

    if (
      item?.item_total !== undefined &&
      item?.item_total !== null
    ) {
      return Number(item.item_total);
    }

    return (
      getProductPrice(item) *
      getQuantity(item)
    );
  }

  // =======================================================
  // CART TOTAL
  // =======================================================

  const cartTotal = cartItems.reduce(
    (total, item) => {
      return (
        total +
        getItemTotal(item)
      );
    },
    0
  );

  // =======================================================
  // TOTAL QUANTITY
  // =======================================================

  const totalQuantity =
    cartItems.reduce(
      (total, item) => {
        return (
          total +
          getQuantity(item)
        );
      },
      0
    );

  // =======================================================
  // CART ITEM ID
  // =======================================================

  function getCartItemId(item) {
    return (
      item?.id ??
      item?.cart_item_id ??
      item?.item_id ??
      null
    );
  }

  // =======================================================
  // UPDATE QUANTITY
  // =======================================================

  async function updateQuantity(
    item,
    newQuantity
  ) {
    if (newQuantity < 1) {
      return;
    }

    const token = getToken();

    if (!token) {
      setError(
        "Please login again."
      );

      return;
    }

    const itemId =
      getCartItemId(item);

    if (!itemId) {
      setError(
        "Unable to identify this cart item."
      );

      return;
    }

    try {
      setUpdatingId(itemId);

      setMessage("");

      setError("");

      const response =
        await fetch(
          `${API_BASE_URL}/cart/items/${itemId}`,
          {
            method: "PUT",

            headers: {
              "Content-Type":
                "application/json",

              Accept:
                "application/json",

              Authorization: `Bearer ${token}`,
            },

            body: JSON.stringify({
              quantity:
                newQuantity,
            }),
          }
        );

      let data;

      try {
        data =
          await response.json();
      } catch {
        throw new Error(
          `Server returned an invalid response. HTTP ${response.status}`
        );
      }

      console.log(
        "Update cart response:",
        data
      );

      if (!response.ok) {
        throw new Error(
          data?.message ||
            data?.msg ||
            `Unable to update cart. HTTP ${response.status}`
        );
      }

      if (
        data?.cart &&
        Array.isArray(
          data.cart.items
        )
      ) {
        setCartItems(
          data.cart.items
        );
      } else if (
        Array.isArray(data?.items)
      ) {
        setCartItems(
          data.items
        );
      } else {
        await loadCart();
      }

      setMessage(
        "Cart updated successfully."
      );
    } catch (error) {
      console.error(
        "Update cart error:",
        error
      );

      setError(
        error.message ||
          "Unable to update cart."
      );
    } finally {
      setUpdatingId(null);
    }
  }

  // =======================================================
  // REMOVE ITEM
  // =======================================================

  async function removeItem(item) {
    const token = getToken();

    if (!token) {
      setError(
        "Please login again."
      );

      return;
    }

    const itemId =
      getCartItemId(item);

    if (!itemId) {
      setError(
        "Unable to identify this cart item."
      );

      return;
    }

    try {
      setUpdatingId(itemId);

      setMessage("");

      setError("");

      const response =
        await fetch(
          `${API_BASE_URL}/cart/items/${itemId}`,
          {
            method: "DELETE",

            headers: {
              Accept:
                "application/json",

              Authorization: `Bearer ${token}`,
            },
          }
        );

      let data = null;

      try {
        data =
          await response.json();
      } catch {
        // Empty response allowed
      }

      console.log(
        "Remove cart response:",
        data
      );

      if (!response.ok) {
        throw new Error(
          data?.message ||
            data?.msg ||
            `Unable to remove item. HTTP ${response.status}`
        );
      }

      if (
        data?.cart &&
        Array.isArray(
          data.cart.items
        )
      ) {
        setCartItems(
          data.cart.items
        );
      } else if (
        Array.isArray(data?.items)
      ) {
        setCartItems(
          data.items
        );
      } else {
        await loadCart();
      }

      setMessage(
        "Product removed from cart."
      );
    } catch (error) {
      console.error(
        "Remove cart error:",
        error
      );

      setError(
        error.message ||
          "Unable to remove product."
      );
    } finally {
      setUpdatingId(null);
    }
  }

  // =======================================================
  // CLEAR CART
  // =======================================================

  async function clearCart() {
    const token = getToken();

    if (!token) {
      setError(
        "Please login again."
      );

      return;
    }

    if (cartItems.length === 0) {
      return;
    }

    const confirmed =
      window.confirm(
        "Are you sure you want to remove all products from your cart?"
      );

    if (!confirmed) {
      return;
    }

    try {
      setUpdatingId("clear");

      setMessage("");

      setError("");

      const response =
        await fetch(
          `${API_BASE_URL}/cart/clear`,
          {
            method: "DELETE",

            headers: {
              Accept:
                "application/json",

              Authorization: `Bearer ${token}`,
            },
          }
        );

      let data = null;

      try {
        data =
          await response.json();
      } catch {
        // Empty response allowed
      }

      console.log(
        "Clear cart response:",
        data
      );

      if (!response.ok) {
        throw new Error(
          data?.message ||
            data?.msg ||
            `Unable to clear cart. HTTP ${response.status}`
        );
      }

      if (
        data?.cart &&
        Array.isArray(
          data.cart.items
        )
      ) {
        setCartItems(
          data.cart.items
        );
      } else {
        setCartItems([]);
      }

      setMessage(
        "Cart cleared successfully."
      );
    } catch (error) {
      console.error(
        "Clear cart error:",
        error
      );

      setError(
        error.message ||
          "Unable to clear cart."
      );
    } finally {
      setUpdatingId(null);
    }
  }

  // =======================================================
  // FORMAT PRICE
  // =======================================================

  function formatPrice(price) {
    const numericPrice =
      Number(price);

    if (
      Number.isNaN(
        numericPrice
      )
    ) {
      return "₹0";
    }

    return `₹${numericPrice.toLocaleString(
      "en-IN",
      {
        minimumFractionDigits: 0,
        maximumFractionDigits: 2,
      }
    )}`;
  }

  // =======================================================
  // CHECKOUT
  // =======================================================

  function handleCheckout() {
    if (cartItems.length === 0) {
      setError(
        "Your cart is empty."
      );

      return;
    }

    if (
      typeof onProceedToCheckout !==
      "function"
    ) {
      console.error(
        "onProceedToCheckout was not provided."
      );

      setError(
        "Checkout is not available right now."
      );

      return;
    }

    const checkoutItems =
      cartItems.map((item) => ({
        id: getCartItemId(item),

        name:
          getProductName(item),

        quantity:
          getQuantity(item),

        price:
          getProductPrice(item),

        total:
          getItemTotal(item),

        image:
          getProductImage(item),
      }));

    onProceedToCheckout({
      items: checkoutItems,

      total: cartTotal,

      quantity: totalQuantity,
    });
  }

  // =======================================================
  // LOADING
  // =======================================================

  if (loading) {
    return (
      <div className="cart-page">
        <div className="cart-message-box">
          <div className="cart-spinner">
            ⟳
          </div>

          <p>
            Loading your cart...
          </p>
        </div>
      </div>
    );
  }

  // =======================================================
  // ERROR WITH NO ITEMS
  // =======================================================

  if (
    error &&
    cartItems.length === 0
  ) {
    return (
      <div className="cart-page">
        <div className="cart-error">
          <div className="cart-error-icon">
            ⚠️
          </div>

          <h2>
            Unable to Load Cart
          </h2>

          <p>{error}</p>

          <button
            type="button"
            className="cart-action-button"
            onClick={loadCart}
          >
            Try Again
          </button>
        </div>
      </div>
    );
  }

  // =======================================================
  // EMPTY CART
  // =======================================================

  if (cartItems.length === 0) {
    return (
      <div className="cart-page">
        <div className="cart-header">
          <div>
            <h1>
              Shopping Cart
            </h1>

            <p>
              Review the products
              you want to buy.
            </p>
          </div>

          <button
            type="button"
            className="cart-refresh-button"
            onClick={loadCart}
          >
            ↻ Refresh
          </button>
        </div>

        {message && (
          <div className="cart-success">
            {message}
          </div>
        )}

        <div className="cart-empty">
          <div className="cart-empty-icon">
            🛒
          </div>

          <h2>
            Your Cart is Empty
          </h2>

          <p>
            Add some products to
            your cart to see them
            here.
          </p>

          <button
            type="button"
            className="cart-action-button"
            onClick={loadCart}
          >
            Refresh Cart
          </button>
        </div>
      </div>
    );
  }

  // =======================================================
  // CART PAGE
  // =======================================================

  return (
    <div className="cart-page">
      <div className="cart-header">
        <div>
          <h1>
            Shopping Cart
          </h1>

          <p>
            Review your products
            before checkout.
          </p>
        </div>

        <div
          style={{
            display: "flex",
            gap: "10px",
            alignItems: "center",
          }}
        >
          <button
            type="button"
            className="cart-refresh-button"
            onClick={loadCart}
            disabled={
              updatingId !== null
            }
          >
            ↻ Refresh
          </button>

          <button
            type="button"
            className="cart-refresh-button"
            onClick={clearCart}
            disabled={
              updatingId !== null
            }
          >
            Clear Cart
          </button>
        </div>
      </div>

      {message && (
        <div className="cart-success">
          {message}
        </div>
      )}

      {error && (
        <div className="cart-error-small">
          {error}
        </div>
      )}

      <div className="cart-layout">
        <div className="cart-items">
          {cartItems.map(
            (item, index) => {
              const itemId =
                getCartItemId(item) ??
                `item-${index}`;

              const product =
                getProduct(item);

              const productName =
                getProductName(item);

              const image =
                getProductImage(item);

              const price =
                getProductPrice(item);

              const originalPrice =
                getOriginalPrice(item);

              const discountPrice =
                getDiscountPrice(item);

              const quantity =
                getQuantity(item);

              const itemTotal =
                getItemTotal(item);

              const updating =
                updatingId === itemId;

              return (
                <div
                  className="cart-item"
                  key={itemId}
                >
                  <div className="cart-item-image">
                    {image ? (
                      <img
                        src={image}
                        alt={productName}
                        loading="lazy"
                        onError={(
                          event
                        ) => {
                          event.currentTarget.style.display =
                            "none";

                          const parent =
                            event
                              .currentTarget
                              .parentElement;

                          if (
                            parent &&
                            !parent.querySelector(
                              ".cart-placeholder"
                            )
                          ) {
                            const placeholder =
                              document.createElement(
                                "div"
                              );

                            placeholder.className =
                              "cart-placeholder";

                            placeholder.textContent =
                              "🛍️";

                            parent.appendChild(
                              placeholder
                            );
                          }
                        }}
                      />
                    ) : (
                      <div className="cart-placeholder">
                        🛍️
                      </div>
                    )}
                  </div>

                  <div className="cart-item-info">
                    <h2>
                      {productName}
                    </h2>

                    {product?.brand && (
                      <p className="cart-item-brand">
                        {product.brand}
                      </p>
                    )}

                    <div className="cart-price-area">
                      {discountPrice !==
                        null &&
                      originalPrice >
                        discountPrice ? (
                        <>
                          <span className="cart-item-price">
                            {formatPrice(
                              discountPrice
                            )}
                          </span>

                          <span
                            className="cart-original-price"
                            style={{
                              textDecoration:
                                "line-through",
                              marginLeft:
                                "8px",
                              color:
                                "#6b7280",
                            }}
                          >
                            {formatPrice(
                              originalPrice
                            )}
                          </span>
                        </>
                      ) : (
                        <span className="cart-item-price">
                          {formatPrice(
                            price
                          )}
                        </span>
                      )}
                    </div>

                    {product?.stock !==
                      undefined &&
                      product?.stock !==
                        null && (
                        <p
                          style={{
                            fontSize:
                              "13px",
                            color:
                              Number(
                                product.stock
                              ) > 0
                                ? "#16a34a"
                                : "#dc2626",
                            margin:
                              "6px 0",
                          }}
                        >
                          {Number(
                            product.stock
                          ) > 0
                            ? `${product.stock} available`
                            : "Out of stock"}
                        </p>
                      )}

                    <div className="quantity-controls">
                      <button
                        type="button"
                        onClick={() =>
                          updateQuantity(
                            item,
                            quantity -
                              1
                          )
                        }
                        disabled={
                          updating ||
                          quantity <=
                            1
                        }
                        aria-label="Decrease quantity"
                      >
                        −
                      </button>

                      <span>
                        {updating
                          ? "..."
                          : quantity}
                      </span>

                      <button
                        type="button"
                        onClick={() =>
                          updateQuantity(
                            item,
                            quantity +
                              1
                          )
                        }
                        disabled={
                          updating
                        }
                        aria-label="Increase quantity"
                      >
                        +
                      </button>
                    </div>
                  </div>

                  <div className="cart-item-right">
                    <strong>
                      {formatPrice(
                        itemTotal
                      )}
                    </strong>

                    <button
                      type="button"
                      className="remove-cart-button"
                      onClick={() =>
                        removeItem(item)
                      }
                      disabled={
                        updating
                      }
                    >
                      {updating
                        ? "..."
                        : "Remove"}
                    </button>
                  </div>
                </div>
              );
            }
          )}
        </div>

        <aside className="cart-summary">
          <h2>
            Order Summary
          </h2>

          <div className="summary-row">
            <span>
              Items
            </span>

            <span>
              {totalQuantity}
            </span>
          </div>

          <div className="summary-row">
            <span>
              Products
            </span>

            <span>
              {cartItems.length}
            </span>
          </div>

          <div className="summary-row">
            <span>
              Subtotal
            </span>

            <strong>
              {formatPrice(
                cartTotal
              )}
            </strong>
          </div>

          <div className="summary-divider" />

          <div className="summary-total">
            <span>
              Total
            </span>

            <strong>
              {formatPrice(
                cartTotal
              )}
            </strong>
          </div>

          <button
            type="button"
            className="checkout-button"
            onClick={
              handleCheckout
            }
            disabled={
              updatingId !== null
            }
          >
            Proceed to Checkout
          </button>
        </aside>
      </div>
    </div>
  );
}

export default Cart;