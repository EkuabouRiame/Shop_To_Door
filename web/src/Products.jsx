import { useEffect, useMemo, useState } from "react";

import "./Products.css";

import { getToken } from "./auth";

// =========================================================
// API BASE URL
// =========================================================

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL ||
  "http://127.0.0.1:5000/api";

// =========================================================
// PRODUCTS COMPONENT
// =========================================================

function Products({
  selectedCategory,
  onProductClick,
  searchQuery,
}) {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [addingId, setAddingId] = useState(null);
  const [message, setMessage] = useState("");

  // =========================================================
  // LOAD PRODUCTS WHEN PAGE OPENS
  // =========================================================

  useEffect(() => {
    loadProducts();
  }, []);

  // =========================================================
  // LOAD PRODUCTS
  // =========================================================

  async function loadProducts() {
    try {
      setLoading(true);
      setError("");
      setMessage("");

      const response = await fetch(
        `${API_BASE_URL}/products/`,
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
          `Server returned an invalid response. HTTP ${response.status}`
        );
      }

      console.log("Products response:", data);

      // =====================================================
      // HTTP ERROR
      // =====================================================

      if (!response.ok) {
        throw new Error(
          data?.message ||
            data?.msg ||
            `Unable to load products. HTTP ${response.status}`
        );
      }

      // =====================================================
      // GET PRODUCT ARRAY
      // =====================================================

      let productList = [];

      if (Array.isArray(data)) {
        productList = data;
      } else if (Array.isArray(data?.products)) {
        productList = data.products;
      } else if (Array.isArray(data?.data)) {
        productList = data.data;
      } else if (Array.isArray(data?.items)) {
        productList = data.items;
      } else if (
        data?.products &&
        Array.isArray(data.products.items)
      ) {
        productList = data.products.items;
      }

      console.log("Products loaded:", productList);

      setProducts(productList);
    } catch (error) {
      console.error("Products error:", error);

      setProducts([]);

      setError(
        error.message || "Unable to load products."
      );
    } finally {
      setLoading(false);
    }
  }

  // =========================================================
  // GET BACKEND BASE URL
  // =========================================================

  function getBackendBaseUrl() {
    return API_BASE_URL.replace(/\/api\/?$/, "");
  }

  // =========================================================
  // CREATE IMAGE URL
  // =========================================================

  function makeImageUrl(image) {
    if (!image) {
      return "";
    }

    const value = String(image).trim();

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

    const backendBase = getBackendBaseUrl();

    // Backend absolute path
    if (value.startsWith("/")) {
      return `${backendBase}${value}`;
    }

    // Backend relative path
    return `${backendBase}/${value}`;
  }

  // =========================================================
  // GET PRODUCT IMAGE
  // =========================================================

  function getProductImage(product) {
    // -------------------------------------------------------
    // PRODUCT IMAGES ARRAY
    // -------------------------------------------------------

    if (
      Array.isArray(product?.images) &&
      product.images.length > 0
    ) {
      // Primary image
      const primaryImage = product.images.find(
        (image) => image?.is_primary === true
      );

      if (primaryImage) {
        const imageValue =
          primaryImage.image_url ||
          primaryImage.url ||
          primaryImage.image;

        if (imageValue) {
          return makeImageUrl(imageValue);
        }
      }

      // Uploaded image
      const uploadedImage = product.images.find(
        (image) =>
          image?.image_url &&
          String(image.image_url).startsWith("/uploads/")
      );

      if (uploadedImage?.image_url) {
        return makeImageUrl(uploadedImage.image_url);
      }

      // First available image
      const firstImage = product.images.find(
        (image) =>
          image?.image_url ||
          image?.url ||
          image?.image
      );

      if (firstImage) {
        return makeImageUrl(
          firstImage.image_url ||
            firstImage.url ||
            firstImage.image
        );
      }
    }

    // -------------------------------------------------------
    // SINGLE IMAGE FIELDS
    // -------------------------------------------------------

    if (product?.image) {
      return makeImageUrl(product.image);
    }

    if (product?.image_url) {
      return makeImageUrl(product.image_url);
    }

    if (product?.image_path) {
      return makeImageUrl(product.image_path);
    }

    if (product?.thumbnail) {
      return makeImageUrl(product.thumbnail);
    }

    if (product?.photo_url) {
      return makeImageUrl(product.photo_url);
    }

    return "";
  }

  // =========================================================
  // PRODUCT PRICE
  // =========================================================

  function getProductPrice(product) {
    if (
      product?.discount_price !== null &&
      product?.discount_price !== undefined
    ) {
      return Number(product.discount_price);
    }

    return Number(
      product?.price ??
        product?.selling_price ??
        product?.sale_price ??
        product?.amount ??
        0
    );
  }

  // =========================================================
  // ORIGINAL PRODUCT PRICE
  // =========================================================

  function getOriginalPrice(product) {
    return Number(
      product?.price ??
        product?.selling_price ??
        product?.amount ??
        0
    );
  }

  // =========================================================
  // CHECK WHETHER PRODUCT HAS DISCOUNT
  // =========================================================

  function hasDiscount(product) {
    const originalPrice =
      getOriginalPrice(product);

    const currentPrice =
      getProductPrice(product);

    return (
      product?.discount_price !== null &&
      product?.discount_price !== undefined &&
      originalPrice > currentPrice
    );
  }

  // =========================================================
  // DISCOUNT PERCENTAGE
  // =========================================================

  function getDiscountPercentage(product) {
    const originalPrice =
      getOriginalPrice(product);

    const currentPrice =
      getProductPrice(product);

    if (
      !originalPrice ||
      originalPrice <= currentPrice
    ) {
      return 0;
    }

    return Math.round(
      ((originalPrice - currentPrice) /
        originalPrice) *
        100
    );
  }

  // =========================================================
  // PRODUCT CATEGORY
  // =========================================================

  function getProductCategory(product) {
    const category = product?.category;

    if (!category) {
      return "";
    }

    // Category is a string
    if (typeof category === "string") {
      return category;
    }

    // Category is an object
    if (typeof category === "object") {
      return (
        category.name ||
        category.slug ||
        ""
      );
    }

    return "";
  }

  // =========================================================
  // CHECK CATEGORY MATCH
  // =========================================================

  function productMatchesCategory(product) {
    if (!selectedCategory) {
      return true;
    }

    const productCategory =
      getProductCategory(product)
        .trim()
        .toLowerCase();

    const selectedName =
      String(
        selectedCategory.categoryName || ""
      )
        .trim()
        .toLowerCase();

    const selectedSlug =
      String(
        selectedCategory.categorySlug || ""
      )
        .trim()
        .toLowerCase();

    const selectedId =
      selectedCategory.categoryId;

    // -------------------------------------------------------
    // CATEGORY ID
    // -------------------------------------------------------

    if (
      selectedId !== undefined &&
      selectedId !== null
    ) {
      const productCategoryId =
        typeof product?.category === "object"
          ? product.category?.id
          : product?.category_id;

      if (
        productCategoryId !== undefined &&
        productCategoryId !== null &&
        String(productCategoryId) ===
          String(selectedId)
      ) {
        return true;
      }
    }

    // -------------------------------------------------------
    // CATEGORY NAME
    // -------------------------------------------------------

    if (
      selectedName &&
      productCategory === selectedName
    ) {
      return true;
    }

    // -------------------------------------------------------
    // CATEGORY SLUG
    // -------------------------------------------------------

    if (
      selectedSlug &&
      productCategory === selectedSlug
    ) {
      return true;
    }

    // -------------------------------------------------------
    // CATEGORY OBJECT SLUG
    // -------------------------------------------------------

    if (
      typeof product?.category === "object"
    ) {
      const productSlug =
        String(
          product.category?.slug || ""
        )
          .trim()
          .toLowerCase();

      if (
        selectedSlug &&
        productSlug === selectedSlug
      ) {
        return true;
      }
    }

    return false;
  }

  // =========================================================
  // CHECK SEARCH MATCH
  // =========================================================

  function productMatchesSearch(product) {
    const query = String(searchQuery || "")
      .trim()
      .toLowerCase();

    // No search query = show everything
    if (!query) {
      return true;
    }

    const productName = String(
      product?.name || ""
    ).toLowerCase();

    const brand = String(
      product?.brand || ""
    ).toLowerCase();

    const description = String(
      product?.description || ""
    ).toLowerCase();

    const category = getProductCategory(
      product
    ).toLowerCase();

    const sku = String(
      product?.sku ||
        product?.product_code ||
        product?.code ||
        ""
    ).toLowerCase();

    return (
      productName.includes(query) ||
      brand.includes(query) ||
      description.includes(query) ||
      category.includes(query) ||
      sku.includes(query)
    );
  }

  // =========================================================
  // FILTERED PRODUCTS
  // =========================================================

  const filteredProducts = useMemo(() => {
    return products.filter((product) => {
      const matchesCategory =
        productMatchesCategory(product);

      const matchesSearch =
        productMatchesSearch(product);

      return (
        matchesCategory &&
        matchesSearch
      );
    });
  }, [
    products,
    selectedCategory,
    searchQuery,
  ]);

  // =========================================================
  // PRODUCT RATING
  // =========================================================

  function getRating(product) {
    const rating = Number(
      product?.rating ?? 0
    );

    if (
      Number.isNaN(rating) ||
      rating < 0
    ) {
      return 0;
    }

    return Math.min(rating, 5);
  }

  // =========================================================
  // RATING STARS
  // =========================================================

  function renderRating(product) {
    const rating = getRating(product);

    if (rating <= 0) {
      return null;
    }

    const roundedRating =
      Math.round(rating);

    return (
      <div
        className="product-rating"
        aria-label={`Rating ${rating} out of 5`}
      >
        <span className="rating-stars">
          {"★".repeat(roundedRating)}
          {"☆".repeat(
            5 - roundedRating
          )}
        </span>

        <span className="rating-value">
          {rating.toFixed(1)}
        </span>

        {product?.review_count !==
          undefined && (
          <span className="review-count">
            ({product.review_count})
          </span>
        )}
      </div>
    );
  }

  // =========================================================
  // PRODUCT CLICK
  // =========================================================

  function handleProductClick(product) {
    if (!product) {
      return;
    }

    console.log(
      "Selected product:",
      product
    );

    if (
      typeof onProductClick ===
      "function"
    ) {
      onProductClick(product);
    }
  }

  // =========================================================
  // KEYBOARD PRODUCT CLICK
  // =========================================================

  function handleProductKeyDown(
    event,
    product
  ) {
    if (
      event.key === "Enter" ||
      event.key === " "
    ) {
      event.preventDefault();

      handleProductClick(product);
    }
  }

  // =========================================================
  // ADD PRODUCT TO CART
  // =========================================================

  async function addToCart(product) {
    const token = getToken();

    setMessage("");

    // -------------------------------------------------------
    // LOGIN CHECK
    // -------------------------------------------------------

    if (!token) {
      setMessage(
        "Please login before adding products to your cart."
      );

      return;
    }

    // -------------------------------------------------------
    // PRODUCT ID CHECK
    // -------------------------------------------------------

    if (!product?.id) {
      setMessage(
        "This product does not have a valid product ID."
      );

      return;
    }

    // -------------------------------------------------------
    // STOCK CHECK
    // -------------------------------------------------------

    if (
      product?.stock !== undefined &&
      product?.stock !== null &&
      Number(product.stock) <= 0
    ) {
      setMessage(
        "This product is currently out of stock."
      );

      return;
    }

    try {
      setAddingId(product.id);

      const response = await fetch(
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
            product_id: product.id,
            quantity: 1,
          }),
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
        "Add to cart response:",
        data
      );

      // -----------------------------------------------------
      // HTTP ERROR
      // -----------------------------------------------------

      if (!response.ok) {
        throw new Error(
          data?.message ||
            data?.msg ||
            `Unable to add product to cart. HTTP ${response.status}`
        );
      }

      // -----------------------------------------------------
      // SUCCESS
      // -----------------------------------------------------

      setMessage(
        `${product.name || "Product"} added to cart successfully.`
      );
    } catch (error) {
      console.error(
        "Add to cart error:",
        error
      );

      setMessage(
        error.message ||
          "Unable to add product to cart."
      );
    } finally {
      setAddingId(null);
    }
  }

  // =========================================================
  // FORMAT PRICE
  // =========================================================

  function formatPrice(price) {
    const numericPrice =
      Number(price);

    if (
      Number.isNaN(numericPrice)
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

  // =========================================================
  // SEARCH TEXT
  // =========================================================

  const cleanSearchQuery =
    String(searchQuery || "").trim();

  // =========================================================
  // RENDER
  // =========================================================

  return (
    <div className="products-page">

      {/* =====================================================
          HEADER
      ===================================================== */}

      <div className="products-header">

        <div className="products-title">

          <h1>
            {cleanSearchQuery
              ? `Search results for "${cleanSearchQuery}"`
              : selectedCategory?.categoryName
              ? selectedCategory.categoryName
              : "Products"}
          </h1>

          <p>
            {cleanSearchQuery
              ? `Products matching "${cleanSearchQuery}"`
              : selectedCategory?.categoryName
              ? `Products in ${selectedCategory.categoryName}`
              : "Explore products available on Shop To Door"}
          </p>

        </div>

        <button
          type="button"
          className="refresh-button"
          onClick={loadProducts}
          disabled={loading}
        >
          {loading
            ? "Loading..."
            : "↻ Refresh"}
        </button>

      </div>

      {/* =====================================================
          SEARCH RESULT BANNER
      ===================================================== */}

      {cleanSearchQuery && (
        <div className="category-filter-banner">

          <span>
            Search results:
          </span>

          <strong>
            {cleanSearchQuery}
          </strong>

          <span>
            ({filteredProducts.length})
          </span>

        </div>
      )}

      {/* =====================================================
          SELECTED CATEGORY
      ===================================================== */}

      {selectedCategory &&
        !cleanSearchQuery && (
          <div className="category-filter-banner">

            <span>
              Showing products in:
            </span>

            <strong>
              {selectedCategory.categoryName}
            </strong>

            <span>
              ({filteredProducts.length})
            </span>

          </div>
        )}

      {/* =====================================================
          CART MESSAGE
      ===================================================== */}

      {message && (
        <div
          className="cart-message"
          role="status"
        >
          {message}
        </div>
      )}

      {/* =====================================================
          LOADING
      ===================================================== */}

      {loading && (
        <div className="products-message">

          <div className="loading-spinner">
            ⟳
          </div>

          <p>
            Loading products...
          </p>

        </div>
      )}

      {/* =====================================================
          ERROR
      ===================================================== */}

      {!loading && error && (
        <div className="products-error">

          <div className="error-icon">
            ⚠️
          </div>

          <h2>
            Unable to Load Products
          </h2>

          <p>
            {error}
          </p>

          <button
            type="button"
            className="try-again-button"
            onClick={loadProducts}
          >
            Try Again
          </button>

        </div>
      )}

      {/* =====================================================
          EMPTY PRODUCTS
      ===================================================== */}

      {!loading &&
        !error &&
        filteredProducts.length === 0 && (
          <div className="products-empty">

            <div className="empty-icon">
              🛍️
            </div>

            <h2>
              {cleanSearchQuery
                ? `No products found for "${cleanSearchQuery}"`
                : selectedCategory?.categoryName
                ? `No products in ${selectedCategory.categoryName}`
                : "No Products Yet"}
            </h2>

            <p>
              {cleanSearchQuery
                ? "Try searching with a different product name, brand, category, or keyword."
                : selectedCategory?.categoryName
                ? "There are currently no products available in this category."
                : "Products added by the administrator will appear here."}
            </p>

            <button
              type="button"
              className="try-again-button"
              onClick={loadProducts}
            >
              Refresh Products
            </button>

          </div>
        )}

      {/* =====================================================
          PRODUCTS GRID
      ===================================================== */}

      {!loading &&
        !error &&
        filteredProducts.length > 0 && (

          <div className="products-grid">

            {filteredProducts.map(
              (product, index) => {

                const image =
                  getProductImage(product);

                const price =
                  getProductPrice(product);

                const originalPrice =
                  getOriginalPrice(product);

                const category =
                  getProductCategory(
                    product
                  );

                const productName =
                  product?.name ||
                  "Unnamed Product";

                const productId =
                  product?.id ??
                  `product-${index}`;

                const discounted =
                  hasDiscount(product);

                const discountPercentage =
                  getDiscountPercentage(
                    product
                  );

                const outOfStock =
                  product?.stock !==
                    undefined &&
                  product?.stock !==
                    null &&
                  Number(product.stock) <=
                    0;

                const isAdding =
                  addingId ===
                  product?.id;

                return (
                  <article
                    className="product-card product-card-clickable"
                    key={productId}
                    role="button"
                    tabIndex={0}
                    onClick={() =>
                      handleProductClick(
                        product
                      )
                    }
                    onKeyDown={(event) =>
                      handleProductKeyDown(
                        event,
                        product
                      )
                    }
                  >

                    {/* =====================================
                        PRODUCT IMAGE
                    ===================================== */}

                    <div className="product-image">

                      {discounted && (
                        <span className="discount-badge">
                          {discountPercentage}% OFF
                        </span>
                      )}

                      {image ? (
                        <img
                          src={image}
                          alt={productName}
                          loading="lazy"
                          onError={(event) => {
                            console.error(
                              "Product image failed:",
                              image
                            );

                            event.currentTarget.style.display =
                              "none";

                            const parent =
                              event.currentTarget
                                .parentElement;

                            if (
                              parent &&
                              !parent.querySelector(
                                ".product-placeholder"
                              )
                            ) {
                              const placeholder =
                                document.createElement(
                                  "div"
                                );

                              placeholder.className =
                                "product-placeholder";

                              placeholder.textContent =
                                "🛍️";

                              parent.appendChild(
                                placeholder
                              );
                            }
                          }}
                        />
                      ) : (
                        <div className="product-placeholder">
                          🛍️
                        </div>
                      )}

                    </div>

                    {/* =====================================
                        PRODUCT INFORMATION
                    ===================================== */}

                    <div className="product-info">

                      {/* PRODUCT NAME */}

                      <h2>
                        {productName}
                      </h2>

                      {/* CATEGORY */}

                      {category && (
                        <span className="product-category">
                          {category}
                        </span>
                      )}

                      {/* BRAND */}

                      {product?.brand && (
                        <p className="product-brand">
                          {product.brand}
                        </p>
                      )}

                      {/* DESCRIPTION */}

                      {product?.description && (
                        <p className="product-description">
                          {product.description}
                        </p>
                      )}

                      {/* RATING */}

                      {renderRating(product)}

                      {/* STOCK */}

                      {product?.stock !==
                        undefined &&
                        product?.stock !==
                          null && (
                          <p className="product-stock">
                            {Number(
                              product.stock
                            ) > 0
                              ? `${product.stock} in stock`
                              : "Out of stock"}
                          </p>
                        )}

                      {/* PRICE */}

                      <div className="product-pricing">

                        <strong className="product-price">
                          {formatPrice(
                            price
                          )}
                        </strong>

                        {discounted && (
                          <span className="original-price">
                            {formatPrice(
                              originalPrice
                            )}
                          </span>
                        )}

                      </div>

                      {/* =================================
                          ADD TO CART
                      ================================= */}

                      <div className="product-bottom">

                        <button
                          type="button"
                          className="add-cart-button"
                          onClick={(event) => {
                            event.stopPropagation();

                            addToCart(
                              product
                            );
                          }}
                          onKeyDown={(event) => {
                            event.stopPropagation();
                          }}
                          disabled={
                            isAdding ||
                            outOfStock
                          }
                        >
                          {isAdding
                            ? "Adding..."
                            : outOfStock
                            ? "Out of Stock"
                            : "Add to Cart"}
                        </button>

                      </div>

                    </div>

                  </article>
                );
              }
            )}

          </div>
        )}

    </div>
  );
}

export default Products;