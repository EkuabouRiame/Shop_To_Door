import { useEffect, useState } from "react";

import "./App.css";

import "./Home.css";

import { getToken } from "./auth";

// =========================================================
// API BASE URL
// =========================================================

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL ||
  "http://127.0.0.1:5000/api";

const BACKEND_URL = API_BASE_URL.replace(/\/api\/?$/, "");

// =========================================================
// HOME
// =========================================================

function Home({
  user,
  setCurrentPage,
  onCategorySelect,
  onSearch,
  onProductClick,
  onShopNow,
  onViewAll,
}) {
  // =======================================================
  // SEARCH
  // =======================================================

  const [searchText, setSearchText] = useState("");

  // =======================================================
  // CATEGORIES
  // =======================================================

  const [categories, setCategories] = useState([]);
  const [loadingCategories, setLoadingCategories] =
    useState(true);
  const [categoryError, setCategoryError] = useState("");

  // =======================================================
  // PRODUCTS
  // =======================================================

  const [products, setProducts] = useState([]);
  const [loadingProducts, setLoadingProducts] =
    useState(true);
  const [productError, setProductError] = useState("");

  // =======================================================
  // ADD TO CART
  // =======================================================

  const [addingId, setAddingId] = useState(null);
  const [cartMessage, setCartMessage] = useState("");

  // =======================================================
  // LOAD HOME DATA
  // =======================================================

  useEffect(() => {
    loadCategories();
    loadProducts();
  }, []);

  // =======================================================
  // LOAD CATEGORIES
  // =======================================================

  async function loadCategories() {
    try {
      setLoadingCategories(true);
      setCategoryError("");

      const response = await fetch(
        `${API_BASE_URL}/admin/categories`,
        {
          method: "GET",
          headers: {
            Accept: "application/json",
          },
        }
      );

      let data;

      try {
        data = await response.json();
      } catch {
        throw new Error(
          `Invalid category response. HTTP ${response.status}`
        );
      }

      console.log("Categories response:", data);

      if (!response.ok) {
        throw new Error(
          data?.message ||
            data?.msg ||
            `Unable to load categories. HTTP ${response.status}`
        );
      }

      let list = [];

      if (Array.isArray(data?.categories)) {
        list = data.categories;
      } else if (Array.isArray(data?.data)) {
        list = data.data;
      } else if (Array.isArray(data)) {
        list = data;
      }

      // Only show active categories when is_active is provided.
      list = list.filter(
        (category) =>
          category?.is_active === undefined ||
          category?.is_active === true
      );

      console.log("Categories loaded:", list);

      setCategories(list);
    } catch (error) {
      console.error("Categories error:", error);

      setCategories([]);

      setCategoryError(
        error.message ||
          "Unable to load categories."
      );
    } finally {
      setLoadingCategories(false);
    }
  }

  // =======================================================
  // LOAD PRODUCTS
  // =======================================================

  async function loadProducts() {
    try {
      setLoadingProducts(true);
      setProductError("");

      const response = await fetch(
        `${API_BASE_URL}/products/?page=1&per_page=8&sort=newest`,
        {
          method: "GET",
          headers: {
            Accept: "application/json",
          },
        }
      );

      let data;

      try {
        data = await response.json();
      } catch {
        throw new Error(
          `Invalid product response. HTTP ${response.status}`
        );
      }

      console.log(
        "Home products response:",
        data
      );

      if (!response.ok) {
        throw new Error(
          data?.message ||
            data?.msg ||
            `Unable to load products. HTTP ${response.status}`
        );
      }

      let list = [];

      if (Array.isArray(data?.products)) {
        list = data.products;
      } else if (Array.isArray(data?.data)) {
        list = data.data;
      } else if (Array.isArray(data?.items)) {
        list = data.items;
      } else if (Array.isArray(data)) {
        list = data;
      }

      console.log(
        "Home products loaded:",
        list
      );

      setProducts(list);
    } catch (error) {
      console.error(
        "Home products error:",
        error
      );

      setProducts([]);

      setProductError(
        error.message ||
          "Unable to load products."
      );
    } finally {
      setLoadingProducts(false);
    }
  }

  // =======================================================
  // IMAGE URL
  // =======================================================

  function getFullImageUrl(imageUrl) {
    if (!imageUrl) {
      return "";
    }

    const value = String(imageUrl).trim();

    if (!value) {
      return "";
    }

    // Complete URL
    if (
      value.startsWith("http://") ||
      value.startsWith("https://") ||
      value.startsWith("data:")
    ) {
      return value;
    }

    // Absolute backend path
    if (value.startsWith("/")) {
      return `${BACKEND_URL}${value}`;
    }

    // Filename
    return `${BACKEND_URL}/uploads/products/${value}`;
  }

  // =======================================================
  // PRODUCT IMAGE
  // =======================================================

  function getProductImage(product) {
    // Product images array
    if (
      Array.isArray(product?.images) &&
      product.images.length > 0
    ) {
      // Primary image
      const primaryImage =
        product.images.find(
          (image) =>
            image?.is_primary === true
        );

      if (primaryImage?.image_url) {
        return getFullImageUrl(
          primaryImage.image_url
        );
      }

      // First available image
      const firstImage =
        product.images.find(
          (image) =>
            image?.image_url ||
            image?.url ||
            image?.image
        );

      if (firstImage) {
        return getFullImageUrl(
          firstImage.image_url ||
            firstImage.url ||
            firstImage.image
        );
      }
    }

    // Main image
    if (product?.image) {
      return getFullImageUrl(
        product.image
      );
    }

    if (product?.image_url) {
      return getFullImageUrl(
        product.image_url
      );
    }

    if (product?.image_path) {
      return getFullImageUrl(
        product.image_path
      );
    }

    return "";
  }

  // =======================================================
  // CATEGORY IMAGE
  // =======================================================

  function getCategoryImage(category) {
    if (!category) {
      return "";
    }

    return getFullImageUrl(
      category.image
    );
  }

  // =======================================================
  // PRICE
  // =======================================================

  function getCurrentPrice(product) {
    if (
      product?.discount_price !== null &&
      product?.discount_price !== undefined
    ) {
      return Number(
        product.discount_price
      );
    }

    return Number(
      product?.price ||
        product?.selling_price ||
        product?.sale_price ||
        0
    );
  }

  // =======================================================
  // FORMAT PRICE
  // =======================================================

  function formatPrice(price) {
    const number = Number(price);

    if (Number.isNaN(number)) {
      return "₹0";
    }

    return `₹${number.toLocaleString(
      "en-IN",
      {
        maximumFractionDigits: 2,
      }
    )}`;
  }

  // =======================================================
  // DISCOUNT
  // =======================================================

  function getDiscount(product) {
    const original = Number(
      product?.price || 0
    );

    const current = Number(
      product?.discount_price || 0
    );

    if (
      !original ||
      !current ||
      current >= original
    ) {
      return 0;
    }

    return Math.round(
      ((original - current) /
        original) *
        100
    );
  }

  // =======================================================
  // CATEGORY CLICK
  // =======================================================

  function handleCategoryClick(category) {
    if (!category) {
      return;
    }

    console.log(
      "Home category clicked:",
      category
    );

    if (
      typeof onCategorySelect ===
      "function"
    ) {
      onCategorySelect({
        categoryId: category.id,
        categoryName: category.name,
        categorySlug: category.slug,
      });

      return;
    }

    setCurrentPage("categories");
  }

  // =======================================================
  // SEARCH SUBMIT
  // =======================================================

  function handleSearchSubmit(event) {
    event.preventDefault();

    const query =
      searchText.trim();

    console.log(
      "Home search:",
      query
    );

    if (
      typeof onSearch ===
      "function"
    ) {
      onSearch(query);
      return;
    }

    setCurrentPage("products");
  }

  // =======================================================
  // SHOP NOW
  // =======================================================

  function handleShopNow() {
    console.log(
      "Shop Now clicked"
    );

    if (
      typeof onShopNow ===
      "function"
    ) {
      onShopNow();
      return;
    }

    setCurrentPage("products");
  }

  // =======================================================
  // VIEW ALL
  // =======================================================

  function handleViewAll() {
    console.log(
      "View All clicked"
    );

    if (
      typeof onViewAll ===
      "function"
    ) {
      onViewAll();
      return;
    }

    setCurrentPage("products");
  }

  // =======================================================
  // PRODUCT CLICK
  // =======================================================

  function handleProductClick(product) {
    if (!product) {
      return;
    }

    console.log(
      "Home product clicked:",
      product
    );

    /*
     * If App.jsx provides the product click
     * handler, use it.
     *
     * This should normally open the product
     * details page.
     */

    if (
      typeof onProductClick ===
      "function"
    ) {
      onProductClick(product);
      return;
    }

    /*
     * IMPORTANT:
     * Never send a product click to
     * Categories.
     *
     * If no product handler exists,
     * go to the Products page instead.
     */

    setCurrentPage("products");
  }

  // =======================================================
  // ADD TO CART
  // =======================================================

  async function handleAddToCart(
    event,
    product
  ) {
    // Prevent the product card's onClick
    // from opening the product details page.
    event?.preventDefault();
    event?.stopPropagation();

    if (!product?.id) {
      setCartMessage(
        "This product does not have a valid product ID."
      );
      return;
    }

    /*
     * IMPORTANT:
     * Use the same authentication helper
     * used by the rest of the application.
     *
     * Previously this page manually checked:
     * localStorage.getItem("access_token")
     * localStorage.getItem("token")
     *
     * Categories already works, so use getToken()
     * here as well.
     */

    const token = getToken();

    console.log(
      "Home Add to Cart:",
      {
        productId: product.id,
        productName: product.name,
        hasToken: Boolean(token),
      }
    );

    if (!token) {
      setCartMessage(
        "Please login before adding products to your cart."
      );
      return;
    }

    try {
      setAddingId(product.id);
      setCartMessage("");

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
                Number(product.id),

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
        "Home add-to-cart response:",
        data
      );

      if (!response.ok) {
        throw new Error(
          data?.message ||
            data?.msg ||
            data?.error ||
            "Unable to add product to cart."
        );
      }

      setCartMessage(
        `${product.name || "Product"} added to cart successfully.`
      );

      /*
       * Notify the rest of the application that
       * the cart has changed.
       *
       * This does not change the existing cart API.
       * It only allows other components to refresh
       * their cart count if they listen for this event.
       */
      window.dispatchEvent(
        new CustomEvent(
          "cartUpdated"
        )
      );
    } catch (error) {
      console.error(
        "Home add-to-cart error:",
        error
      );

      setCartMessage(
        error.message ||
          "Unable to add product to cart."
      );
    } finally {
      setAddingId(null);
    }
  }

  // =======================================================
  // RENDER
  // =======================================================

  return (
    <div className="app-background">
      <main className="mobile-app">

        {/* =================================================
            HEADER
        ================================================= */}

        <header className="top-header">

          {/* BRAND */}

          <div className="brand-header">
            <div className="brand-logo">
              🧳
            </div>

            <div className="brand-name">
              <span>Shop</span>{" "}
              To Door
            </div>
          </div>

          {/* SHORTCUTS */}

          <div className="top-shortcuts">

            <button
              type="button"
              className="shortcut active"
              onClick={
                handleShopNow
              }
            >
              <div className="shortcut-icon">
                🛍️
              </div>

              <span>
                Shop
              </span>
            </button>

            <button
              type="button"
              className="shortcut"
              onClick={() =>
                setCurrentPage(
                  "cart"
                )
              }
            >
              <div className="shortcut-icon">
                💳
              </div>

              <span>
                Pay
              </span>
            </button>

            <button
              type="button"
              className="shortcut"
              onClick={() => {
                const grocery =
                  categories.find(
                    (category) =>
                      String(
                        category.name
                      )
                        .toLowerCase() ===
                      "grocery"
                  );

                if (grocery) {
                  handleCategoryClick(
                    grocery
                  );
                } else {
                  handleShopNow();
                }
              }}
            >
              <div className="shortcut-icon">
                🛒
              </div>

              <span>
                Grocery
              </span>
            </button>

          </div>

          {/* LOCATION */}

          <div className="location-row">
            <span className="home-icon">
              ⌂
            </span>

            <span>
              Home · Delivery available
            </span>

            <span className="coin">
              🪙 16
            </span>
          </div>

          {/* SEARCH */}

          <form
            className="search-row"
            onSubmit={
              handleSearchSubmit
            }
          >
            <div className="search-box">

              <span className="search-icon">
                ⌕
              </span>

              <input
                type="text"
                value={searchText}
                onChange={(event) =>
                  setSearchText(
                    event.target.value
                  )
                }
                placeholder="Search products, brands and more"
                aria-label="Search products"
              />

              {searchText && (
                <button
                  type="button"
                  className="camera-icon"
                  onClick={() =>
                    setSearchText("")
                  }
                  aria-label="Clear search"
                >
                  ×
                </button>
              )}

            </div>

            <button
              className="scan-button"
              type="submit"
              aria-label="Search"
            >
              🔍
            </button>
          </form>

        </header>

        {/* =================================================
            CART MESSAGE
        ================================================= */}

        {cartMessage && (
          <div
            className="cart-message"
            role="status"
          >
            {cartMessage}
          </div>
        )}

        {/* =================================================
            PROMOTIONAL BANNER
        ================================================= */}

        <section className="banner-section">

          <div className="promo-banner">

            <div className="promo-text">

              <div className="promo-brand">
                SHOP TO DOOR
              </div>

              <div className="promo-title">
                YOUR SHOPPING,
                <br />
                MADE BETTER
              </div>

              <div className="promo-subtitle">
                DISCOVER DEALS, SHOP WITH EASE,
              </div>

              <div className="promo-small">
                AND ENJOY DOORSTEP DELIVERY.
              </div>

              <button
                type="button"
                onClick={
                  handleShopNow
                }
                style={{
                  marginTop:
                    "14px",
                  padding:
                    "10px 20px",
                  border: "none",
                  borderRadius:
                    "8px",
                  background:
                    "#ffffff",
                  color:
                    "#111827",
                  fontWeight:
                    "700",
                  cursor:
                    "pointer",
                }}
              >
                SHOP NOW
              </button>

            </div>

            <div className="promo-phone">
              📱
            </div>

          </div>

        </section>

        {/* =================================================
            CATEGORIES
        ================================================= */}

        <section className="category-section">

          <div className="section-heading">

            <h2>
              Categories
            </h2>

            <button
              type="button"
              onClick={() =>
                setCurrentPage(
                  "categories"
                )
              }
              style={{
                border:
                  "none",
                background:
                  "transparent",
                color:
                  "#2563eb",
                fontWeight:
                  "600",
                cursor:
                  "pointer",
              }}
            >
              View All
            </button>

          </div>

          {loadingCategories && (
            <div className="api-message loading">
              Loading categories...
            </div>
          )}

          {!loadingCategories &&
            categoryError && (
              <div className="api-message error">

                <p>
                  {categoryError}
                </p>

                <button
                  type="button"
                  className="retry-button"
                  onClick={
                    loadCategories
                  }
                >
                  Retry
                </button>

              </div>
            )}

          {!loadingCategories &&
            !categoryError &&
            categories.length === 0 && (
              <div className="api-message">
                No categories available.
              </div>
            )}

          {!loadingCategories &&
            !categoryError &&
            categories.length > 0 && (
              <div className="category-grid">

                {categories.map(
                  (category) => {

                    const image =
                      getCategoryImage(
                        category
                      );

                    return (
                      <button
                        type="button"
                        className="category-card"
                        key={
                          category.id ??
                          category.slug ??
                          category.name
                        }
                        onClick={() =>
                          handleCategoryClick(
                            category
                          )
                        }
                      >

                        <div className="category-image-wrapper">

                          {image ? (
                            <img
                              src={image}
                              alt={
                                category.name
                              }
                              loading="lazy"
                              onError={(
                                event
                              ) => {
                                event.currentTarget.style.display =
                                  "none";
                              }}
                            />
                          ) : (
                            <div className="product-placeholder">
                              🛍️
                            </div>
                          )}

                        </div>

                        <span>
                          {category.name}
                        </span>

                      </button>
                    );
                  }
                )}

              </div>
            )}

        </section>

        {/* =================================================
            SHOP PRODUCTS
        ================================================= */}

        <section className="api-products-section">

          <div className="section-heading">

            <h2>
              Shop Products
            </h2>

            <button
              type="button"
              onClick={
                handleViewAll
              }
              style={{
                border:
                  "none",
                background:
                  "transparent",
                color:
                  "#2563eb",
                fontWeight:
                  "600",
                cursor:
                  "pointer",
              }}
            >
              View All
            </button>

          </div>

          {/* LOADING */}

          {loadingProducts && (
            <div className="api-message loading">
              Loading products...
            </div>
          )}

          {/* ERROR */}

          {!loadingProducts &&
            productError && (
              <div className="api-message error">

                <p>
                  {productError}
                </p>

                <button
                  type="button"
                  className="retry-button"
                  onClick={
                    loadProducts
                  }
                >
                  Retry
                </button>

              </div>
            )}

          {/* EMPTY */}

          {!loadingProducts &&
            !productError &&
            products.length === 0 && (
              <div className="api-message">
                No products available.
              </div>
            )}

          {/* PRODUCTS */}

          {!loadingProducts &&
            !productError &&
            products.length > 0 && (
              <div className="api-product-grid">

                {products.map(
                  (product) => {

                    const image =
                      getProductImage(
                        product
                      );

                    const currentPrice =
                      getCurrentPrice(
                        product
                      );

                    const discount =
                      getDiscount(
                        product
                      );

                    const stock =
                      Number(
                        product?.stock ||
                          0
                      );

                    return (
                      <article
                        className="api-product-card"
                        key={
                          product.id
                        }
                        role="button"
                        tabIndex={0}
                        style={{
                          cursor:
                            "pointer",
                        }}
                        onClick={() =>
                          handleProductClick(
                            product
                          )
                        }
                        onKeyDown={(
                          event
                        ) => {

                          if (
                            event.key ===
                              "Enter" ||
                            event.key ===
                              " "
                          ) {
                            event.preventDefault();

                            handleProductClick(
                              product
                            );
                          }

                        }}
                      >

                        {/* IMAGE */}

                        <div className="api-product-image">

                          {discount > 0 && (
                            <span className="discount-badge">
                              {discount}% OFF
                            </span>
                          )}

                          {image ? (
                            <img
                              src={image}
                              alt={
                                product.name ||
                                "Product"
                              }
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
                                    ".no-image"
                                  )
                                ) {
                                  const placeholder =
                                    document.createElement(
                                      "div"
                                    );

                                  placeholder.className =
                                    "no-image";

                                  placeholder.textContent =
                                    "📦";

                                  parent.appendChild(
                                    placeholder
                                  );
                                }

                              }}
                            />
                          ) : (
                            <div className="no-image">
                              📦
                            </div>
                          )}

                        </div>

                        {/* INFORMATION */}

                        <div className="api-product-info">

                          {/* BRAND */}

                          {product?.brand && (
                            <div className="product-brand">
                              {product.brand}
                            </div>
                          )}

                          {/* NAME */}

                          <h3>
                            {product.name}
                          </h3>

                          {/* RATING */}

                          <div className="product-rating">

                            <span className="star">
                              ★
                            </span>{" "}

                            {Number(
                              product.rating ||
                                0
                            ).toFixed(1)}

                            {" · "}

                            {product.review_count ||
                              0}

                            {" reviews"}

                          </div>

                          {/* PRICE */}

                          <div className="product-prices">

                            <strong>
                              {formatPrice(
                                currentPrice
                              )}
                            </strong>

                            {product.price &&
                              product.discount_price &&
                              Number(
                                product.discount_price
                              ) <
                                Number(
                                  product.price
                                ) && (
                                  <del>
                                    {formatPrice(
                                      product.price
                                    )}
                                  </del>
                                )}

                          </div>

                          {/* STOCK */}

                          {stock > 0 ? (
                            <div className="stock-text">
                              {product.stock}{" "}
                              in stock
                            </div>
                          ) : (
                            <div className="stock-text out-of-stock">
                              Out of stock
                            </div>
                          )}

                          {/* ADD TO CART */}

                          <button
                            className="add-cart-button"
                            type="button"
                            disabled={
                              stock <= 0 ||
                              addingId ===
                                product.id
                            }
                            onClick={(
                              event
                            ) =>
                              handleAddToCart(
                                event,
                                product
                              )
                            }
                          >
                            {addingId ===
                            product.id
                              ? "Adding..."
                              : stock > 0
                              ? "Add to Cart"
                              : "Out of Stock"}
                          </button>

                        </div>

                      </article>
                    );
                  }
                )}

              </div>
            )}

        </section>

        {/* =================================================
            SHOP NOW
        ================================================= */}

        <section
          style={{
            padding:
              "25px 15px",
          }}
        >

          <button
            type="button"
            onClick={
              handleShopNow
            }
            style={{
              width: "100%",
              padding:
                "15px 20px",
              border: "none",
              borderRadius:
                "12px",
              background:
                "#2563eb",
              color:
                "#ffffff",
              fontSize:
                "16px",
              fontWeight:
                "700",
              cursor:
                "pointer",
              boxShadow:
                "0 5px 15px rgba(37,99,235,0.25)",
            }}
          >
            Shop Now
          </button>

        </section>

        {/* =================================================
            BOTTOM NAVIGATION
        ================================================= */}

        <nav className="bottom-navigation">

          {/* HOME */}

          <button
            type="button"
            className="active"
            onClick={() =>
              setCurrentPage(
                "home"
              )
            }
          >
            <span>
              🏠
            </span>

            <small>
              Home
            </small>
          </button>

          {/* CATEGORIES */}

          <button
            type="button"
            onClick={() =>
              setCurrentPage(
                "categories"
              )
            }
          >
            <span>
              ▦
            </span>

            <small>
              Categories
            </small>
          </button>

          {/* ACCOUNT */}

          <button
            type="button"
            onClick={() =>
              setCurrentPage(
                "account"
              )
            }
          >
            <span>
              👤
            </span>

            <small>
              Account
            </small>
          </button>

          {/* CART */}

          <button
            type="button"
            onClick={() =>
              setCurrentPage(
                "cart"
              )
            }
          >
            <span>
              🛒
            </span>

            <small>
              Cart
            </small>
          </button>

        </nav>

      </main>
    </div>
  );
}

export default Home;