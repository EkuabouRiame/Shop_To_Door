import { useEffect, useState } from "react";

import Login from "./Login";
import Register from "./Register";
import Products from "./Products";
import Cart from "./Cart";
import AdminPage from "./AdminPage";
import DeliveryDashboard from "./DeliveryDashboard";
import Home from "./Home";
import Checkout from "./Checkout";
import DeliveryConfirmation from "./DeliveryConfirmation";
import ProductDetails from "./ProductDetail";

import {
  getToken,
  getUser,
  saveAuth,
  logout as clearAuth,
} from "./auth";

import logo from "./assets/shop-to-door-logo.png";

import "./App.css";

// =========================================================
// API
// =========================================================

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL ||
  "http://127.0.0.1:5000/api";

// =========================================================
// APP
// =========================================================

function App() {
  // =======================================================
  // USER
  // =======================================================

  const [user, setUser] = useState(null);

  const [loading, setLoading] = useState(true);

  // =======================================================
  // AUTH PAGE
  // =======================================================

  const [authPage, setAuthPage] = useState("login");

  // =======================================================
  // CURRENT PAGE
  // =======================================================

  const [currentPage, setCurrentPage] = useState("home");

  // =======================================================
  // CATEGORY
  // =======================================================

  const [selectedCategory, setSelectedCategory] =
    useState(null);

  // =======================================================
  // SEARCH
  // =======================================================

  const [searchQuery, setSearchQuery] = useState("");

  // =======================================================
  // SELECTED PRODUCT
  // =======================================================

  const [selectedProduct, setSelectedProduct] =
    useState(null);

  // =======================================================
  // CHECKOUT DATA
  // =======================================================

  const [checkoutData, setCheckoutData] = useState(null);

  // =======================================================
  // ROLE HELPERS
  // =======================================================

  function getRole(userData = user) {
    return String(
      userData?.role || "customer"
    )
      .trim()
      .toLowerCase();
  }

  function isAdmin(userData = user) {
    return getRole(userData) === "admin";
  }

  function isDeliveryPerson(userData = user) {
    const role = getRole(userData);

    return (
      role === "delivery_person" ||
      role === "delivery-person" ||
      role === "deliveryperson" ||
      role === "delivery"
    );
  }

  function isCustomer(userData = user) {
    return getRole(userData) === "customer";
  }

  // =======================================================
  // SET ROLE PAGE
  // =======================================================

  function setRolePage(userData) {
    if (isAdmin(userData)) {
      setCurrentPage("admin");
      return;
    }

    if (isDeliveryPerson(userData)) {
      setCurrentPage("delivery-dashboard");
      return;
    }

    setCurrentPage("home");
  }

  // =======================================================
  // CHECK AUTHENTICATION
  // =======================================================

  useEffect(() => {
    let mounted = true;

    async function checkAuthentication() {
      const token = getToken();
      const storedUser = getUser();

      if (!token) {
        if (mounted) {
          setLoading(false);
        }

        return;
      }

      try {
        const response = await fetch(
          `${API_BASE_URL}/auth/me`,
          {
            method: "GET",
            headers: {
              Accept: "application/json",
              Authorization: `Bearer ${token}`,
            },
          }
        );

        let data = null;

        try {
          data = await response.json();
        } catch {
          throw new Error(
            `Invalid server response. HTTP ${response.status}`
          );
        }

        console.log(
          "Authentication check:",
          data
        );

        if (
          !response.ok ||
          data?.status !== "success" ||
          !data?.user
        ) {
          clearAuth();

          if (mounted) {
            setUser(null);
          }

          return;
        }

        saveAuth(token, data.user);

        if (mounted) {
          setUser(data.user);

          // =================================================
          // ROLE-BASED LANDING PAGE
          // =================================================

          if (isAdmin(data.user)) {
            setCurrentPage("admin");
          } else if (isDeliveryPerson(data.user)) {
            setCurrentPage("delivery-dashboard");
          } else {
            setCurrentPage("home");
          }
        }
      } catch (error) {
        console.error(
          "Authentication check failed:",
          error
        );

        /*
         * If the backend is temporarily unavailable,
         * keep the locally stored user.
         */

        if (storedUser && mounted) {
          setUser(storedUser);

          if (isAdmin(storedUser)) {
            setCurrentPage("admin");
          } else if (isDeliveryPerson(storedUser)) {
            setCurrentPage("delivery-dashboard");
          } else {
            setCurrentPage("home");
          }
        }
      } finally {
        if (mounted) {
          setLoading(false);
        }
      }
    }

    checkAuthentication();

    return () => {
      mounted = false;
    };
  }, []);

  // =======================================================
  // LOGIN SUCCESS
  // =======================================================

  function handleLogin(userData) {
  console.log(
    "Login successful:",
    userData
  );

  setUser(userData);

  setAuthPage("login");

  setSelectedCategory(null);
  setSearchQuery("");
  setSelectedProduct(null);
  setCheckoutData(null);

  // =====================================================
  // QR DELIVERY LOGIN
  // =====================================================

  const pendingQrToken =
    sessionStorage.getItem(
      "shop_to_door_pending_qr_token"
    );

  if (pendingQrToken) {
    console.log(
      "Returning to delivery confirmation after QR customer login."
    );

    setCurrentPage(
      "delivery-confirmation"
    );

    window.scrollTo({
      top: 0,
      behavior: "smooth",
    });

    return;
  }

  // =====================================================
  // NORMAL ROLE-BASED REDIRECT
  // =====================================================

  setRolePage(userData);

  window.scrollTo({
    top: 0,
    behavior: "smooth",
  });
}
  // =======================================================
  // REGISTER SUCCESS
  // =======================================================

  function handleRegister(userData) {
    console.log(
      "Registration successful:",
      userData
    );

    if (userData) {
      setUser(userData);

      setAuthPage("login");

      setSelectedCategory(null);
      setSearchQuery("");
      setSelectedProduct(null);
      setCheckoutData(null);

      setRolePage(userData);
    } else {
      setAuthPage("login");
    }
  }

  // =======================================================
  // LOGOUT
  // =======================================================

  async function handleLogout() {
    const token = getToken();

    try {
      if (token) {
        await fetch(
          `${API_BASE_URL}/auth/logout`,
          {
            method: "POST",
            headers: {
              Accept: "application/json",
              Authorization: `Bearer ${token}`,
            },
          }
        );
      }
    } catch (error) {
      console.error(
        "Logout request failed:",
        error
      );
    } finally {
      clearAuth();

      setUser(null);

      setAuthPage("login");

      setSelectedCategory(null);
      setSearchQuery("");
      setSelectedProduct(null);
      setCheckoutData(null);

      setCurrentPage("home");

      window.scrollTo({
        top: 0,
        behavior: "smooth",
      });
    }
  }

  // =======================================================
  // ADMIN DASHBOARD
  // =======================================================

  function openAdminDashboard() {
    if (!isAdmin()) {
      return;
    }

    setSelectedCategory(null);
    setSearchQuery("");
    setSelectedProduct(null);
    setCheckoutData(null);

    setCurrentPage("admin");

    window.scrollTo({
      top: 0,
      behavior: "smooth",
    });
  }

  // =======================================================
  // DELIVERY DASHBOARD
  // =======================================================

  function openDeliveryDashboard() {
    if (!isDeliveryPerson()) {
      return;
    }

    setSelectedCategory(null);
    setSearchQuery("");
    setSelectedProduct(null);
    setCheckoutData(null);

    setCurrentPage("delivery-dashboard");

    window.scrollTo({
      top: 0,
      behavior: "smooth",
    });
  }

  // =======================================================
  // GO HOME
  // =======================================================

  function goHome() {
    // Admin
    if (isAdmin()) {
      openAdminDashboard();
      return;
    }

    // Delivery person
    if (isDeliveryPerson()) {
      openDeliveryDashboard();
      return;
    }

    setSelectedCategory(null);
    setSearchQuery("");
    setSelectedProduct(null);
    setCheckoutData(null);

    setCurrentPage("home");

    window.scrollTo({
      top: 0,
      behavior: "smooth",
    });
  }

  // =======================================================
  // GO TO PRODUCTS
  // =======================================================

  function goToProducts(options = {}) {
    // Admin does not use customer shopping page.
    if (isAdmin()) {
      openAdminDashboard();
      return;
    }

    // Delivery person does not use customer shopping page.
    if (isDeliveryPerson()) {
      openDeliveryDashboard();
      return;
    }

    const {
      category = null,
      search = "",
    } = options;

    setSelectedCategory(category);
    setSearchQuery(search);
    setSelectedProduct(null);

    setCurrentPage("products");

    window.scrollTo({
      top: 0,
      behavior: "smooth",
    });
  }

  // =======================================================
  // CATEGORY
  // =======================================================

  function handleCategorySelect(category) {
    if (isAdmin()) {
      openAdminDashboard();
      return;
    }

    if (isDeliveryPerson()) {
      openDeliveryDashboard();
      return;
    }

    console.log(
      "Selected category:",
      category
    );

    goToProducts({
      category,
      search: "",
    });
  }

  // =======================================================
  // SEARCH
  // =======================================================

  function handleSearch(searchText) {
    if (isAdmin()) {
      openAdminDashboard();
      return;
    }

    if (isDeliveryPerson()) {
      openDeliveryDashboard();
      return;
    }

    const cleanedSearch = String(
      searchText || ""
    ).trim();

    console.log(
      "Searching for:",
      cleanedSearch
    );

    goToProducts({
      category: null,
      search: cleanedSearch,
    });
  }

  // =======================================================
  // PRODUCT CLICK
  // =======================================================
function handleProductClick(product) {
  if (isAdmin()) {
    openAdminDashboard();
    return;
  }

  if (isDeliveryPerson()) {
    openDeliveryDashboard();
    return;
  }

  if (!product) {
    return;
  }

  console.log(
    "Selected product:",
    product
  );

  setSelectedProduct(product);

  setCurrentPage(
    "product-details"
  );

  window.scrollTo({
    top: 0,
    behavior: "smooth",
  });
}
  // =======================================================
  // PROCEED TO CHECKOUT
  // =======================================================

  function handleProceedToCheckout(
    data = null
  ) {
    // Only customers can checkout.
    if (!isCustomer()) {
      if (isAdmin()) {
        openAdminDashboard();
      } else if (isDeliveryPerson()) {
        openDeliveryDashboard();
      }

      return;
    }

    console.log(
      "Proceeding to checkout:",
      data
    );

    setCheckoutData(data);

    setCurrentPage("checkout");

    window.scrollTo({
      top: 0,
      behavior: "smooth",
    });
  }

  // =======================================================
  // ORDER PLACED
  // =======================================================

  function handleOrderPlaced(order) {
    console.log(
      "Order placed:",
      order
    );

    if (!isCustomer()) {
      if (isAdmin()) {
        openAdminDashboard();
      } else if (isDeliveryPerson()) {
        openDeliveryDashboard();
      }

      return;
    }

    setCheckoutData(null);

    setCurrentPage("orders");

    window.scrollTo({
      top: 0,
      behavior: "smooth",
    });
  }

  // =======================================================
  // BACK TO CART
  // =======================================================

  function handleBackToCart() {
    if (!isCustomer()) {
      if (isAdmin()) {
        openAdminDashboard();
      } else if (isDeliveryPerson()) {
        openDeliveryDashboard();
      }

      return;
    }

    setCurrentPage("cart");

    window.scrollTo({
      top: 0,
      behavior: "smooth",
    });
  }
{/* =================================================
    DELIVERY CONFIRMATION / QR SCANNER
================================================= */}

{currentPage === "delivery-confirmation" && (
  <DeliveryConfirmation
  onRequireLogin={() => {
    setAuthPage("login");
  }}
/>
)}
  // =======================================================
  // ACCOUNT
  // =======================================================

  function openAccount() {
    // Admin
    if (isAdmin()) {
      openAdminDashboard();
      return;
    }

    // Delivery person
    if (isDeliveryPerson()) {
      openDeliveryDashboard();
      return;
    }

    setSelectedProduct(null);

    setCurrentPage("account");

    window.scrollTo({
      top: 0,
      behavior: "smooth",
    });
  }

  // =======================================================
  // ORDERS
  // =======================================================

  function openOrders() {
    if (isAdmin()) {
      openAdminDashboard();
      return;
    }

    if (isDeliveryPerson()) {
      openDeliveryDashboard();
      return;
    }

    setSelectedProduct(null);

    setCurrentPage("orders");

    window.scrollTo({
      top: 0,
      behavior: "smooth",
    });
  }

  // =======================================================
  // DELIVERY ADDRESS
  // =======================================================

  function openDeliveryAddress() {
    if (isAdmin()) {
      openAdminDashboard();
      return;
    }

    if (isDeliveryPerson()) {
      openDeliveryDashboard();
      return;
    }

    setSelectedProduct(null);

    setCurrentPage("delivery");

    window.scrollTo({
      top: 0,
      behavior: "smooth",
    });
  }

  // =======================================================
  // SETTINGS
  // =======================================================

  function openAccountSettings() {
    if (isAdmin()) {
      openAdminDashboard();
      return;
    }

    if (isDeliveryPerson()) {
      openDeliveryDashboard();
      return;
    }

    setSelectedProduct(null);

    setCurrentPage("settings");

    window.scrollTo({
      top: 0,
      behavior: "smooth",
    });
  }

  // =======================================================
  // CATEGORIES PAGE
  // =======================================================

  function openCategories() {
    if (isAdmin()) {
      openAdminDashboard();
      return;
    }

    if (isDeliveryPerson()) {
      openDeliveryDashboard();
      return;
    }

    setSelectedCategory(null);
    setSearchQuery("");
    setSelectedProduct(null);

    setCurrentPage("categories");

    window.scrollTo({
      top: 0,
      behavior: "smooth",
    });
  }

  // =======================================================
  // CART PAGE
  // =======================================================

  function openCart() {
    if (isAdmin()) {
      openAdminDashboard();
      return;
    }

    if (isDeliveryPerson()) {
      openDeliveryDashboard();
      return;
    }

    setSelectedProduct(null);

    setCurrentPage("cart");

    window.scrollTo({
      top: 0,
      behavior: "smooth",
    });
  }

  // =======================================================
  // LOADING SCREEN
  // =======================================================

  if (loading) {
    return (
      <div
        style={{
          minHeight: "100vh",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          background: "#f5f7fb",
          fontFamily:
            "Arial, sans-serif",
        }}
      >
        <div
          style={{
            textAlign: "center",
            padding: "20px",
          }}
        >
          <img
            src={logo}
            alt="Shop To Door Logo"
            style={{
              width: "180px",
              maxWidth: "80vw",
              height: "auto",
              display: "block",
              margin:
                "0 auto 15px",
              objectFit: "contain",
            }}
          />

          <h2
            style={{
              margin:
                "0 0 8px",
              color: "#111827",
            }}
          >
            Shop To Door
          </h2>

          <p
            style={{
              margin: 0,
              color: "#6b7280",
            }}
          >
            Checking your account...
          </p>
        </div>
      </div>
    );
  }

  // =======================================================
  // AUTHENTICATION
  // =======================================================

  if (!user) {
    if (authPage === "register") {
      return (
        <Register
          onRegister={handleRegister}
          onSwitchToLogin={() =>
            setAuthPage("login")
          }
        />
      );
    }

      return (
     <Login
       onLogin={handleLogin}
       onSwitchToRegister={() =>
        setAuthPage("register")
     }
       qrMode={currentPage === "delivery-confirmation"}
    />
    );
  }
  // =======================================================
  // ADMIN APPLICATION
  // =======================================================

  if (isAdmin()) {
    return (
      <div
        className="app-container"
        style={{
          minHeight: "100vh",
          background: "#f5f7fb",
          fontFamily:
            "Arial, sans-serif",
        }}
      >
        {/* ADMIN HEADER */}

        <header
          style={{
            background: "#ffffff",
            borderBottom:
              "1px solid #e5e7eb",
            padding:
              "10px 20px",
            display: "flex",
            alignItems: "center",
            justifyContent:
              "space-between",
            position: "sticky",
            top: 0,
            zIndex: 1000,
          }}
        >
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: "15px",
            }}
          >
            <img
              src={logo}
              alt="Shop To Door"
              style={{
                width: "145px",
                height: "48px",
                objectFit:
                  "contain",
                display: "block",
              }}
            />

            <div
              style={{
                height: "32px",
                width: "1px",
                background:
                  "#e5e7eb",
              }}
            />

            <div>
              <div
                style={{
                  fontSize: "12px",
                  color: "#6b7280",
                  fontWeight: "600",
                  textTransform:
                    "uppercase",
                  letterSpacing:
                    "0.5px",
                }}
              >
                Management
              </div>

              <div
                style={{
                  fontSize: "15px",
                  fontWeight: "700",
                  color: "#111827",
                }}
              >
                Admin Dashboard
              </div>
            </div>
          </div>

          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: "12px",
            }}
          >
            <div
              style={{
                textAlign: "right",
              }}
            >
              <div
                style={{
                  color: "#111827",
                  fontSize: "14px",
                  fontWeight: "700",
                }}
              >
                {user.name}
              </div>

              <div
                style={{
                  color: "#6b7280",
                  fontSize: "12px",
                }}
              >
                Administrator
              </div>
            </div>

            <button
              type="button"
              onClick={handleLogout}
              style={{
                border: "none",
                background: "#111827",
                color: "#ffffff",
                padding:
                  "9px 15px",
                borderRadius: "8px",
                cursor: "pointer",
                fontWeight: "600",
              }}
            >
              Logout
            </button>
          </div>
        </header>

        {/* ADMIN PAGE */}

        <main>
          <AdminPage />
        </main>
      </div>
    );
  }

  // =======================================================
  // DELIVERY PERSON APPLICATION
  // =======================================================

  if (isDeliveryPerson()) {
    return (
      <div
        className="app-container"
        style={{
          minHeight: "100vh",
          background: "#f5f7fb",
          fontFamily:
            "Arial, sans-serif",
        }}
      >
        {/* DELIVERY HEADER */}

        <header
          style={{
            background: "#ffffff",
            borderBottom:
              "1px solid #e5e7eb",
            padding:
              "10px 20px",
            display: "flex",
            alignItems: "center",
            justifyContent:
              "space-between",
            position: "sticky",
            top: 0,
            zIndex: 1000,
          }}
        >
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: "15px",
            }}
          >
            <img
              src={logo}
              alt="Shop To Door"
              style={{
                width: "145px",
                height: "48px",
                objectFit:
                  "contain",
                display: "block",
              }}
            />

            <div
              style={{
                height: "32px",
                width: "1px",
                background:
                  "#e5e7eb",
              }}
            />

            <div>
              <div
                style={{
                  fontSize: "12px",
                  color: "#6b7280",
                  fontWeight: "600",
                  textTransform:
                    "uppercase",
                  letterSpacing:
                    "0.5px",
                }}
              >
                Delivery
              </div>

              <div
                style={{
                  fontSize: "15px",
                  fontWeight: "700",
                  color: "#111827",
                }}
              >
                Delivery Dashboard
              </div>
            </div>
          </div>

          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: "12px",
            }}
          >
            <div
              style={{
                textAlign: "right",
              }}
            >
              <div
                style={{
                  color: "#111827",
                  fontSize: "14px",
                  fontWeight: "700",
                }}
              >
                {user.name}
              </div>

              <div
                style={{
                  color: "#6b7280",
                  fontSize: "12px",
                }}
              >
                Delivery Person
              </div>
            </div>

            <button
              type="button"
              onClick={handleLogout}
              style={{
                border: "none",
                background: "#111827",
                color: "#ffffff",
                padding:
                  "9px 15px",
                borderRadius: "8px",
                cursor: "pointer",
                fontWeight: "600",
              }}
            >
              Logout
            </button>
          </div>
        </header>

        {/* DELIVERY DASHBOARD */}

        <main>
          <DeliveryDashboard />
        </main>
      </div>
    );
  }

  // =======================================================
  // CUSTOMER APPLICATION
  // =======================================================

  return (
    <div
      className="app-container"
      style={{
        minHeight: "100vh",
        background: "#f5f7fb",
        fontFamily:
          "Arial, sans-serif",
        paddingBottom: "80px",
      }}
    >
      {/* =================================================
          CUSTOMER HEADER
      ================================================= */}

      <header
        style={{
          background: "#ffffff",
          borderBottom:
            "1px solid #e5e7eb",
          padding: "8px 20px",
          display: "flex",
          alignItems: "center",
          justifyContent:
            "space-between",
          position: "sticky",
          top: 0,
          zIndex: 1000,
        }}
      >
        <button
          type="button"
          onClick={goHome}
          style={{
            border: "none",
            background:
              "transparent",
            cursor: "pointer",
            padding: 0,
            display: "flex",
            alignItems: "center",
          }}
          aria-label="Go to home"
        >
          <img
            src={logo}
            alt="Shop To Door"
            style={{
              width: "145px",
              height: "48px",
              objectFit:
                "contain",
              display: "block",
            }}
          />
        </button>

        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: "12px",
          }}
        >
          <span
            style={{
              color: "#374151",
              fontSize: "14px",
              fontWeight: "500",
            }}
          >
            {user.name}
          </span>

          <button
            type="button"
            onClick={handleLogout}
            style={{
              border: "none",
              background: "#111827",
              color: "#ffffff",
              padding:
                "9px 15px",
              borderRadius: "8px",
              cursor: "pointer",
              fontWeight: "600",
            }}
          >
            Logout
          </button>
        </div>
      </header>

      {/* =================================================
          CUSTOMER DESKTOP NAVIGATION
      ================================================= */}

      <nav className="desktop-navigation">
        <button
          type="button"
          className={
            currentPage === "home"
              ? "active"
              : ""
          }
          onClick={goHome}
        >
          🏠 Home
        </button>

        <button
          type="button"
          className={
            currentPage ===
            "categories"
              ? "active"
              : ""
          }
          onClick={openCategories}
        >
          ▦ Categories
        </button>

        <button
          type="button"
          className={
            currentPage === "account" ||
            currentPage === "orders" ||
            currentPage === "delivery" ||
            currentPage === "settings"
              ? "active"
              : ""
          }
          onClick={openAccount}
        >
          👤 Account
        </button>

        <button
          type="button"
          onClick={() =>
            setCurrentPage("delivery-confirmation")
          }
        >
          📷 Scan Delivery QR
        </button>

        <button
          type="button"
          className={
            currentPage === "cart"
              ? "active"
              : ""
          }
          onClick={openCart}
        >
          🛒 Cart
        </button>
      </nav>

      {/* =================================================
          HOME
      ================================================= */}

      {currentPage === "home" && (
        <Home
          user={user}
          setCurrentPage={
            setCurrentPage
          }
          onCategorySelect={
            handleCategorySelect
          }
          onSearch={handleSearch}
          onProductClick={
            handleProductClick
          }
          onShopNow={() =>
            goToProducts()
          }
          onViewAll={() =>
            goToProducts()
          }
        />
      )}

      {/* =================================================
          CATEGORIES
      ================================================= */}

      {currentPage ===
        "categories" && (
        <main
          style={{
            maxWidth: "1200px",
            margin: "0 auto",
            padding:
              "25px 20px",
          }}
        >
          <Products
            selectedCategory={
              selectedCategory
            }
            onProductClick={
              handleProductClick
            }
          />
        </main>
      )}

      {/* =================================================
          PRODUCTS
      ================================================= */}

      {currentPage === "products" && (
        <main
          style={{
            maxWidth: "1200px",
            margin: "0 auto",
            padding:
              "25px 20px",
          }}
        >
          <Products
            selectedCategory={
              selectedCategory
            }
            onProductClick={
              handleProductClick
            }
            searchQuery={
              searchQuery
            }
          />
        </main>
      )}
{/* =================================================
    PRODUCT DETAILS
================================================= */}

{currentPage === "product-details" &&
  selectedProduct && (
    <ProductDetails
      product={selectedProduct}
      onBack={() => {
        setSelectedProduct(null);

        setCurrentPage(
          "products"
        );

        window.scrollTo({
          top: 0,
          behavior: "smooth",
        });
      }}
    />
  )}
      {/* =================================================
          CART
      ================================================= */}

      {currentPage === "cart" && (
        <main
          style={{
            maxWidth: "1200px",
            margin: "0 auto",
            padding:
              "25px 20px",
          }}
        >
          <Cart
            onProceedToCheckout={
              handleProceedToCheckout
            }
          />
        </main>
      )}

      {/* =================================================
          CHECKOUT
      ================================================= */}

      {currentPage ===
        "checkout" && (
        <main
          style={{
            maxWidth: "1200px",
            margin: "0 auto",
            padding:
              "25px 20px",
          }}
        >
          <Checkout
            user={user}
            checkoutData={
              checkoutData
            }
            onBackToCart={
              handleBackToCart
            }
            onOrderPlaced={
              handleOrderPlaced
            }
          />
        </main>
      )}
     {/* =================================================
          DELIVERY CONFIRMATION / QR SCANNER
      ================================================= */}

      {currentPage === "delivery-confirmation" && (
        <DeliveryConfirmation />
      )}

      {/* =================================================
          ACCOUNT
      ================================================= */}

      {currentPage === "account" && (
        <main
          style={{
            maxWidth: "900px",
            margin: "0 auto",
            padding:
              "25px 20px",
          }}
        >
          <div
            style={{
              background: "#ffffff",
              borderRadius: "16px",
              padding: "30px",
              boxShadow:
                "0 4px 20px rgba(0,0,0,0.06)",
            }}
          >
            <div
              style={{
                display: "flex",
                alignItems: "center",
                gap: "15px",
                marginBottom:
                  "25px",
              }}
            >
              <div
                style={{
                  width: "60px",
                  height: "60px",
                  borderRadius:
                    "50%",
                  background:
                    "#eaf3ff",
                  display: "flex",
                  alignItems:
                    "center",
                  justifyContent:
                    "center",
                  fontSize: "30px",
                }}
              >
                👤
              </div>

              <div>
                <h2
                  style={{
                    margin:
                      "0 0 5px",
                    color:
                      "#111827",
                  }}
                >
                  My Account
                </h2>

                <p
                  style={{
                    margin: 0,
                    color:
                      "#6b7280",
                  }}
                >
                  {user.name}
                </p>
              </div>
            </div>

            <div
              style={{
                padding: "20px",
                background:
                  "#f9fafb",
                borderRadius:
                  "12px",
                marginBottom:
                  "20px",
              }}
            >
              <h3
                style={{
                  marginTop: 0,
                  color:
                    "#111827",
                }}
              >
                Account Information
              </h3>

              <p>
                <strong>
                  Name:
                </strong>{" "}
                {user.name}
              </p>

              <p>
                <strong>
                  Email:
                </strong>{" "}
                {user.email}
              </p>

              {user.phone && (
                <p>
                  <strong>
                    Phone:
                  </strong>{" "}
                  {user.phone}
                </p>
              )}

              <p
                style={{
                  marginBottom: 0,
                }}
              >
                <strong>
                  Role:
                </strong>{" "}
                {user.role ||
                  "customer"}
              </p>
            </div>

            <div
              style={{
                display: "grid",
                gridTemplateColumns:
                  "repeat(auto-fit, minmax(200px, 1fr))",
                gap: "15px",
              }}
            >
              <button
                type="button"
                onClick={
                  openOrders
                }
                style={{
                  border:
                    "1px solid #e5e7eb",
                  background:
                    "#ffffff",
                  borderRadius:
                    "12px",
                  padding:
                    "20px",
                  cursor:
                    "pointer",
                  textAlign:
                    "left",
                }}
              >
                <div
                  style={{
                    fontSize:
                      "28px",
                    marginBottom:
                      "8px",
                  }}
                >
                  📦
                </div>

                <strong>
                  My Orders
                </strong>

                <p
                  style={{
                    color:
                      "#6b7280",
                    marginBottom: 0,
                    fontSize:
                      "14px",
                  }}
                >
                  View your orders
                </p>
              </button>

              <button
                type="button"
                onClick={
                  openDeliveryAddress
                }
                style={{
                  border:
                    "1px solid #e5e7eb",
                  background:
                    "#ffffff",
                  borderRadius:
                    "12px",
                  padding:
                    "20px",
                  cursor:
                    "pointer",
                  textAlign:
                    "left",
                }}
              >
                <div
                  style={{
                    fontSize:
                      "28px",
                    marginBottom:
                      "8px",
                  }}
                >
                  📍
                </div>

                <strong>
                  Delivery Address
                </strong>

                <p
                  style={{
                    color:
                      "#6b7280",
                    marginBottom: 0,
                    fontSize:
                      "14px",
                  }}
                >
                  Manage your delivery address
                </p>
              </button>

              <button
                type="button"
                onClick={
                  openAccountSettings
                }
                style={{
                  border:
                    "1px solid #e5e7eb",
                  background:
                    "#ffffff",
                  borderRadius:
                    "12px",
                  padding:
                    "20px",
                  cursor:
                    "pointer",
                  textAlign:
                    "left",
                }}
              >
                <div
                  style={{
                    fontSize:
                      "28px",
                    marginBottom:
                      "8px",
                  }}
                >
                  ⚙️
                </div>

                <strong>
                  Account Settings
                </strong>

                <p
                  style={{
                    color:
                      "#6b7280",
                    marginBottom: 0,
                    fontSize:
                      "14px",
                  }}
                >
                  Manage your account
                </p>
              </button>
            </div>
          </div>
        </main>
      )}

      {/* =================================================
          MY ORDERS
      ================================================= */}

      {currentPage ===
        "orders" && (
        <main
          style={{
            maxWidth: "1000px",
            margin: "0 auto",
            padding:
              "25px 20px",
          }}
        >
          <MyOrders
            onBack={openAccount}
          />
        </main>
      )}

      {/* =================================================
          DELIVERY ADDRESS
      ================================================= */}

      {currentPage ===
        "delivery" && (
        <main
          style={{
            maxWidth: "900px",
            margin: "0 auto",
            padding:
              "25px 20px",
          }}
        >
          <DeliveryAddress
            user={user}
            onBack={openAccount}
          />
        </main>
      )}

      {/* =================================================
          ACCOUNT SETTINGS
      ================================================= */}

      {currentPage ===
        "settings" && (
        <main
          style={{
            maxWidth: "900px",
            margin: "0 auto",
            padding:
              "25px 20px",
          }}
        >
          <AccountSettings
            user={user}
            setUser={setUser}
            onBack={openAccount}
          />
        </main>
      )}

      {/* =================================================
          MOBILE CUSTOMER NAVIGATION
      ================================================= */}

      <nav className="bottom-navigation">
        <button
          type="button"
          className={
            currentPage === "home"
              ? "active"
              : ""
          }
          onClick={goHome}
        >
          <span>🏠</span>
          <small>Home</small>
        </button>

        <button
          type="button"
          className={
            currentPage ===
            "categories"
              ? "active"
              : ""
          }
          onClick={
            openCategories
          }
        >
          <span>▦</span>
          <small>
            Categories
          </small>
        </button>

        <button
          type="button"
          className={
            currentPage ===
              "account" ||
            currentPage ===
              "orders" ||
            currentPage ===
              "delivery" ||
            currentPage ===
              "settings"
              ? "active"
              : ""
          }
          onClick={openAccount}
        >
          <span>👤</span>
          <small>Account</small>
        </button>

        <button
          type="button"
          className={
            currentPage === "cart"
              ? "active"
              : ""
          }
          onClick={openCart}
        >
          <span>🛒</span>
          <small>Cart</small>
        </button>
      </nav>
    </div>
  );
}

// =========================================================
// MY ORDERS
// =========================================================

function MyOrders({ onBack }) {
  const [orders, setOrders] =
    useState([]);

  const [loading, setLoading] =
    useState(true);

  const [error, setError] =
    useState("");

  const [selectedOrder, setSelectedOrder] =
    useState(null);

  const [detailsLoading, setDetailsLoading] =
    useState(false);

  const [cancelLoading, setCancelLoading] =
    useState(false);

  async function loadOrders() {
    try {
      setLoading(true);
      setError("");

      const token = getToken();

      if (!token) {
        throw new Error(
          "Please login again to view your orders."
        );
      }

      const response = await fetch(
        `${API_BASE_URL}/orders/`,
        {
          method: "GET",
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
        throw new Error(
          `Invalid server response. HTTP ${response.status}`
        );
      }

      if (!response.ok) {
        throw new Error(
          data?.message ||
            data?.msg ||
            `Unable to load orders. HTTP ${response.status}`
        );
      }

      if (
        data?.status &&
        data.status !== "success"
      ) {
        throw new Error(
          data.message ||
            "Unable to load orders."
        );
      }

      setOrders(
        Array.isArray(data?.orders)
          ? data.orders
          : []
      );
    } catch (error) {
      console.error(
        "Unable to load orders:",
        error
      );

      setError(
        error.message ||
          "Unable to load your orders."
      );
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadOrders();
  }, []);

  function formatPrice(price) {
    return `₹${Number(
      price || 0
    ).toLocaleString(
      "en-IN",
      {
        minimumFractionDigits: 0,
        maximumFractionDigits: 2,
      }
    )}`;
  }

  function formatDate(dateValue) {
    if (!dateValue) {
      return "Date unavailable";
    }

    const date =
      new Date(dateValue);

    if (
      Number.isNaN(
        date.getTime()
      )
    ) {
      return String(
        dateValue
      );
    }

    return date.toLocaleString(
      "en-IN",
      {
        day: "numeric",
        month: "short",
        year: "numeric",
        hour: "numeric",
        minute: "2-digit",
        hour12: true,
      }
    );
  }

  function getStatusColor(status) {
    const value = String(
      status || ""
    ).toLowerCase();

    if (
      value === "cancelled" ||
      value === "canceled"
    ) {
      return "#dc2626";
    }

    if (value === "delivered") {
      return "#16a34a";
    }

    if (
      value === "shipped" ||
      value === "out_for_delivery"
    ) {
      return "#2563eb";
    }

    if (
      value === "assigned" ||
      value === "picked_up"
    ) {
      return "#7c3aed";
    }

    if (value === "packed") {
      return "#ca8a04";
    }

    if (value === "pending") {
      return "#ea580c";
    }

    return "#6b7280";
  }

  function formatStatus(status) {
    if (!status) {
      return "Order Placed";
    }

    return String(status)
      .replace(
        /_/g,
        " "
      )
      .replace(
        /\b\w/g,
        (char) =>
          char.toUpperCase()
      );
  }

  async function viewOrder(orderId) {
    try {
      setDetailsLoading(true);
      setError("");

      const token = getToken();

      if (!token) {
        throw new Error(
          "Please login again."
        );
      }

      const response =
        await fetch(
          `${API_BASE_URL}/orders/${orderId}`,
          {
            method: "GET",
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
        throw new Error(
          `Invalid server response. HTTP ${response.status}`
        );
      }

      if (!response.ok) {
        throw new Error(
          data?.message ||
            `Unable to load order. HTTP ${response.status}`
        );
      }

      if (
        data?.status !==
          "success" ||
        !data?.order
      ) {
        throw new Error(
          data?.message ||
            "Unable to load order details."
        );
      }

      setSelectedOrder(
        data.order
      );
    } catch (error) {
      console.error(
        "Unable to load order:",
        error
      );

      setError(
        error.message ||
          "Unable to load order details."
      );
    } finally {
      setDetailsLoading(
        false
      );
    }
  }

  async function cancelOrder(orderId) {
    const confirmed =
      window.confirm(
        "Are you sure you want to cancel this order?"
      );

    if (!confirmed) {
      return;
    }

    try {
      setCancelLoading(true);
      setError("");

      const token = getToken();

      if (!token) {
        throw new Error(
          "Please login again."
        );
      }

      const response =
        await fetch(
          `${API_BASE_URL}/orders/${orderId}/cancel`,
          {
            method: "POST",
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
        throw new Error(
          `Invalid server response. HTTP ${response.status}`
        );
      }

      if (!response.ok) {
        throw new Error(
          data?.message ||
            `Unable to cancel order. HTTP ${response.status}`
        );
      }

      if (
        data?.status !==
        "success"
      ) {
        throw new Error(
          data?.message ||
            "Unable to cancel order."
        );
      }

      await loadOrders();

      if (
        selectedOrder?.id ===
        orderId
      ) {
        setSelectedOrder(
          data.order ||
            null
        );
      }

      alert(
        "Order cancelled successfully."
      );
    } catch (error) {
      console.error(
        "Unable to cancel order:",
        error
      );

      setError(
        error.message ||
          "Unable to cancel order."
      );
    } finally {
      setCancelLoading(
        false
      );
    }
  }

  function canCancelOrder(order) {
    const status =
      String(
        order?.status || ""
      ).toLowerCase();

    return (
      status === "pending" ||
      status === "confirmed"
    );
  }

  if (loading) {
    return (
      <div
        style={{
          background: "#ffffff",
          borderRadius: "16px",
          padding: "30px",
          boxShadow:
            "0 4px 20px rgba(0,0,0,0.06)",
          textAlign: "center",
        }}
      >
        <BackButton
          onClick={onBack}
        />

        <h1
          style={{
            marginTop: 0,
            color: "#111827",
          }}
        >
          My Orders
        </h1>

        <p
          style={{
            color: "#6b7280",
          }}
        >
          Loading your orders...
        </p>
      </div>
    );
  }

  if (selectedOrder) {
    const orderItems =
      Array.isArray(
        selectedOrder.items
      )
        ? selectedOrder.items
        : [];

    const shipping =
      selectedOrder.shipping ||
      {};

    const orderStatus =
      selectedOrder.status ||
      "pending";

    return (
      <div
        style={{
          background: "#ffffff",
          borderRadius: "16px",
          padding: "30px",
          boxShadow:
            "0 4px 20px rgba(0,0,0,0.06)",
        }}
      >
        <button
          type="button"
          onClick={() =>
            setSelectedOrder(
              null
            )
          }
          style={{
            border: "none",
            background: "#f3f4f6",
            padding:
              "10px 15px",
            borderRadius: "8px",
            cursor: "pointer",
            marginBottom:
              "20px",
          }}
        >
          ← Back to Orders
        </button>

        <div
          style={{
            display: "flex",
            justifyContent:
              "space-between",
            alignItems:
              "flex-start",
            gap: "15px",
            flexWrap: "wrap",
          }}
        >
          <div>
            <h1
              style={{
                margin:
                  "0 0 6px",
                color:
                  "#111827",
              }}
            >
              Order #
              {selectedOrder.id}
            </h1>

            <p
              style={{
                margin: 0,
                color:
                  "#6b7280",
              }}
            >
              Placed on{" "}
              {formatDate(
                selectedOrder.created_at
              )}
            </p>
          </div>

          <span
            style={{
              display:
                "inline-block",
              padding:
                "8px 14px",
              borderRadius:
                "999px",
              background:
                `${getStatusColor(
                  orderStatus
                )}18`,
              color:
                getStatusColor(
                  orderStatus
                ),
              fontWeight:
                "700",
              fontSize:
                "14px",
            }}
          >
            {formatStatus(
              orderStatus
            )}
          </span>
        </div>

        {/* PAYMENT */}

        <div
          style={{
            marginTop: "25px",
            padding: "18px",
            background: "#f9fafb",
            borderRadius: "12px",
          }}
        >
          <h3
            style={{
              marginTop: 0,
              color: "#111827",
            }}
          >
            Payment Information
          </h3>

          <p>
            <strong>
              Method:
            </strong>{" "}
            {selectedOrder.payment_method ||
              "Not specified"}
          </p>

          <p
            style={{
              marginBottom: 0,
            }}
          >
            <strong>
              Status:
            </strong>{" "}
            {formatStatus(
              selectedOrder.payment_status ||
                "pending"
            )}
          </p>
        </div>

        {/* ITEMS */}

        <div
          style={{
            marginTop: "25px",
          }}
        >
          <h3
            style={{
              color: "#111827",
            }}
          >
            Order Items
          </h3>

          <div
            style={{
              border:
                "1px solid #e5e7eb",
              borderRadius:
                "12px",
              overflow:
                "hidden",
            }}
          >
            {orderItems.map(
              (item, index) => (
                <div
                  key={
                    item.id ||
                    index
                  }
                  style={{
                    display:
                      "flex",
                    justifyContent:
                      "space-between",
                    gap: "15px",
                    padding:
                      "15px",
                    borderBottom:
                      index ===
                      orderItems.length -
                        1
                        ? "none"
                        : "1px solid #f0f0f0",
                  }}
                >
                  <div>
                    <strong>
                      {item.product_name ||
                        "Product"}
                    </strong>

                    <div
                      style={{
                        marginTop:
                          "4px",
                        color:
                          "#6b7280",
                        fontSize:
                          "14px",
                      }}
                    >
                      Quantity:{" "}
                      {item.quantity ||
                        1}
                    </div>
                  </div>

                  <strong>
                    {formatPrice(
                      item.total_price
                    )}
                  </strong>
                </div>
              )
            )}
          </div>
        </div>

        {/* PRICE SUMMARY */}

        <div
          style={{
            marginTop: "25px",
            padding: "20px",
            background: "#f9fafb",
            borderRadius: "12px",
          }}
        >
          <h3
            style={{
              marginTop: 0,
            }}
          >
            Price Summary
          </h3>

          <PriceRow
            label="Subtotal"
            value={formatPrice(
              selectedOrder.subtotal
            )}
          />

          <PriceRow
            label="Shipping"
            value={formatPrice(
              selectedOrder.shipping_fee
            )}
          />

          <PriceRow
            label="Discount"
            value={`-${formatPrice(
              selectedOrder.discount
            )}`}
          />

          <div
            style={{
              borderTop:
                "1px solid #d1d5db",
              marginTop: "12px",
              paddingTop: "12px",
            }}
          >
            <PriceRow
              label="Total"
              value={formatPrice(
                selectedOrder.total_amount
              )}
              strong
            />
          </div>
        </div>

        {/* SHIPPING */}

        <div
          style={{
            marginTop: "25px",
            padding: "20px",
            background: "#f9fafb",
            borderRadius: "12px",
          }}
        >
          <h3
            style={{
              marginTop: 0,
            }}
          >
            Delivery Address
          </h3>

          <p
            style={{
              margin:
                "0 0 5px",
              fontWeight: "600",
            }}
          >
            {shipping.name ||
              "Not provided"}
          </p>

          <p
            style={{
              margin:
                "0 0 5px",
              color: "#6b7280",
            }}
          >
            {shipping.phone ||
              ""}
          </p>

          <p
            style={{
              margin:
                "0 0 5px",
              color: "#6b7280",
            }}
          >
            {shipping.address ||
              ""}
          </p>

          <p
            style={{
              margin: 0,
              color: "#6b7280",
            }}
          >
            {shipping.city ||
              ""}
            {shipping.city &&
            shipping.state
              ? ", "
              : ""}
            {shipping.state ||
              ""}
            {shipping.pincode
              ? ` - ${shipping.pincode}`
              : ""}
          </p>
        </div>

        {/* CANCEL */}

        {canCancelOrder(
          selectedOrder
        ) && (
          <button
            type="button"
            disabled={
              cancelLoading
            }
            onClick={() =>
              cancelOrder(
                selectedOrder.id
              )
            }
            style={{
              marginTop: "25px",
              border: "none",
              background:
                cancelLoading
                  ? "#9ca3af"
                  : "#dc2626",
              color: "#ffffff",
              padding:
                "12px 20px",
              borderRadius:
                "8px",
              cursor:
                cancelLoading
                  ? "not-allowed"
                  : "pointer",
              fontWeight:
                "700",
            }}
          >
            {cancelLoading
              ? "Cancelling..."
              : "Cancel Order"}
          </button>
        )}

        {detailsLoading && (
          <p
            style={{
              marginTop:
                "15px",
              color:
                "#6b7280",
            }}
          >
            Updating order...
          </p>
        )}

        {error && (
          <div
            style={{
              marginTop: "20px",
              background:
                "#fef2f2",
              border:
                "1px solid #fecaca",
              color:
                "#b91c1c",
              padding: "12px",
              borderRadius:
                "8px",
            }}
          >
            {error}
          </div>
        )}
      </div>
    );
  }

  if (error) {
    return (
      <div
        style={{
          background: "#ffffff",
          borderRadius: "16px",
          padding: "30px",
          boxShadow:
            "0 4px 20px rgba(0,0,0,0.06)",
        }}
      >
        <BackButton
          onClick={onBack}
        />

        <h1
          style={{
            marginTop: 0,
            color: "#111827",
          }}
        >
          My Orders
        </h1>

        <div
          style={{
            background: "#fef2f2",
            border:
              "1px solid #fecaca",
            color: "#b91c1c",
            padding: "15px",
            borderRadius: "10px",
            marginTop: "20px",
          }}
        >
          {error}
        </div>

        <button
          type="button"
          onClick={loadOrders}
          style={{
            marginTop: "15px",
            border: "none",
            background: "#2563eb",
            color: "#ffffff",
            padding:
              "11px 18px",
            borderRadius: "8px",
            cursor: "pointer",
            fontWeight: "600",
          }}
        >
          Try Again
        </button>
      </div>
    );
  }

  return (
    <div
      style={{
        background: "#ffffff",
        borderRadius: "16px",
        padding: "30px",
        boxShadow:
          "0 4px 20px rgba(0,0,0,0.06)",
      }}
    >
      <BackButton
        onClick={onBack}
      />

      <h1
        style={{
          marginTop: 0,
          color: "#111827",
        }}
      >
        My Orders
      </h1>

      <p
        style={{
          color: "#6b7280",
        }}
      >
        View and manage your Shop
        To Door orders.
      </p>

      {orders.length === 0 ? (
        <div
          style={{
            textAlign: "center",
            padding:
              "60px 20px",
            color: "#6b7280",
          }}
        >
          <div
            style={{
              fontSize: "55px",
              marginBottom:
                "15px",
            }}
          >
            📦
          </div>

          <h2
            style={{
              color:
                "#111827",
            }}
          >
            No Orders Yet
          </h2>

          <p>
            Your orders will appear
            here after you place
            an order.
          </p>
        </div>
      ) : (
        <div
          style={{
            display: "flex",
            flexDirection:
              "column",
            gap: "15px",
          }}
        >
          {orders.map(
            (order) => {
              const orderItems =
                Array.isArray(
                  order.items
                )
                  ? order.items
                  : [];

              const orderTotal =
                order.total_amount ??
                order.total ??
                0;

              const orderStatus =
                order.status ||
                "pending";

              return (
                <div
                  key={order.id}
                  style={{
                    border:
                      "1px solid #e5e7eb",
                    borderRadius:
                      "12px",
                    padding:
                      "20px",
                  }}
                >
                  <div
                    style={{
                      display:
                        "flex",
                      justifyContent:
                        "space-between",
                      alignItems:
                        "flex-start",
                      gap: "15px",
                      flexWrap:
                        "wrap",
                    }}
                  >
                    <div>
                      <strong
                        style={{
                          color:
                            "#111827",
                        }}
                      >
                        Order #
                        {order.id}
                      </strong>

                      <p
                        style={{
                          margin:
                            "6px 0 0",
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

                    <strong
                      style={{
                        color:
                          "#111827",
                        fontSize:
                          "16px",
                      }}
                    >
                      {formatPrice(
                        orderTotal
                      )}
                    </strong>
                  </div>

                  <div
                    style={{
                      marginTop:
                        "15px",
                      paddingTop:
                        "15px",
                      borderTop:
                        "1px solid #f0f0f0",
                    }}
                  >
                    <span
                      style={{
                        display:
                          "inline-block",
                        padding:
                          "6px 10px",
                        borderRadius:
                          "999px",
                        background:
                          `${getStatusColor(
                            orderStatus
                          )}18`,
                        color:
                          getStatusColor(
                            orderStatus
                          ),
                        fontWeight:
                          "700",
                        fontSize:
                          "13px",
                      }}
                    >
                      {formatStatus(
                        orderStatus
                      )}
                    </span>
                  </div>

                  {order.payment_method && (
                    <div
                      style={{
                        marginTop:
                          "10px",
                        fontSize:
                          "14px",
                        color:
                          "#6b7280",
                      }}
                    >
                      <strong
                        style={{
                          color:
                            "#374151",
                        }}
                      >
                        Payment:
                      </strong>{" "}
                      {formatStatus(
                        order.payment_method
                      )}
                    </div>
                  )}

                  {order.payment_status && (
                    <div
                      style={{
                        marginTop:
                          "5px",
                        fontSize:
                          "14px",
                        color:
                          "#6b7280",
                      }}
                    >
                      <strong
                        style={{
                          color:
                            "#374151",
                        }}
                      >
                        Payment Status:
                      </strong>{" "}
                      {formatStatus(
                        order.payment_status
                      )}
                    </div>
                  )}

                  {orderItems.length >
                    0 && (
                    <div
                      style={{
                        marginTop:
                          "15px",
                      }}
                    >
                      {orderItems.map(
                        (
                          item,
                          index
                        ) => {
                          const quantity =
                            item.quantity ||
                            1;

                          const itemTotal =
                            item.total_price ??
                            item.total ??
                            Number(
                              item.unit_price ||
                                0
                            ) *
                              Number(
                                quantity
                              );

                          return (
                            <div
                              key={
                                item.id ||
                                index
                              }
                              style={{
                                display:
                                  "flex",
                                justifyContent:
                                  "space-between",
                                alignItems:
                                  "center",
                                gap: "15px",
                                padding:
                                  "6px 0",
                                fontSize:
                                  "14px",
                              }}
                            >
                              <span
                                style={{
                                  color:
                                    "#374151",
                                }}
                              >
                                {item.product_name ||
                                  "Product"}{" "}
                                ×{" "}
                                {quantity}
                              </span>

                              <span
                                style={{
                                  color:
                                    "#374151",
                                  whiteSpace:
                                    "nowrap",
                                }}
                              >
                                {formatPrice(
                                  itemTotal
                                )}
                              </span>
                            </div>
                          );
                        }
                      )}
                    </div>
                  )}

                  <div
                    style={{
                      display:
                        "flex",
                      gap: "10px",
                      flexWrap:
                        "wrap",
                      marginTop:
                        "18px",
                      paddingTop:
                        "15px",
                      borderTop:
                        "1px solid #f0f0f0",
                    }}
                  >
                    <button
                      type="button"
                      onClick={() =>
                        viewOrder(
                          order.id
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
                          "10px 15px",
                        borderRadius:
                          "8px",
                        cursor:
                          "pointer",
                        fontWeight:
                          "600",
                      }}
                    >
                      View Details
                    </button>

                    {canCancelOrder(
                      order
                    ) && (
                      <button
                        type="button"
                        disabled={
                          cancelLoading
                        }
                        onClick={() =>
                          cancelOrder(
                            order.id
                          )
                        }
                        style={{
                          border:
                            "1px solid #fecaca",
                          background:
                            "#fff1f2",
                          color:
                            "#dc2626",
                          padding:
                            "10px 15px",
                          borderRadius:
                            "8px",
                          cursor:
                            cancelLoading
                              ? "not-allowed"
                              : "pointer",
                          fontWeight:
                            "600",
                        }}
                      >
                        Cancel Order
                      </button>
                    )}
                  </div>
                </div>
              );
            }
          )}
        </div>
      )}
    </div>
  );
}

// =========================================================
// BACK BUTTON
// =========================================================

function BackButton({ onClick }) {
  return (
    <button
      type="button"
      onClick={onClick}
      style={{
        border: "none",
        background: "#f3f4f6",
        padding:
          "10px 15px",
        borderRadius: "8px",
        cursor: "pointer",
        marginBottom:
          "20px",
      }}
    >
      ← Back to Account
    </button>
  );
}

// =========================================================
// PRICE ROW
// =========================================================

function PriceRow({
  label,
  value,
  strong = false,
}) {
  return (
    <div
      style={{
        display: "flex",
        justifyContent:
          "space-between",
        gap: "15px",
        marginBottom:
          "8px",
        fontWeight: strong
          ? "700"
          : "400",
        color: strong
          ? "#111827"
          : "#374151",
      }}
    >
      <span>{label}</span>
      <span>{value}</span>
    </div>
  );
}

// =========================================================
// DELIVERY ADDRESS
// =========================================================

function DeliveryAddress({
  user,
  onBack,
}) {
  const [address, setAddress] =
    useState({
      fullName:
        user?.name || "",
      phone:
        user?.phone || "",
      address: "",
      city: "",
      state: "",
      pincode: "",
      landmark: "",
    });

  const [saved, setSaved] =
    useState(false);

  useEffect(() => {
    try {
      const savedAddress =
        localStorage.getItem(
          "shop_to_door_address"
        );

      if (!savedAddress) {
        return;
      }

      const parsed =
        JSON.parse(
          savedAddress
        );

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
          parsed.address ||
          "",
        city:
          parsed.city || "",
        state:
          parsed.state || "",
        pincode:
          parsed.pincode ||
          "",
        landmark:
          parsed.landmark ||
          "",
      });
    } catch (error) {
      console.error(
        "Unable to load address:",
        error
      );
    }
  }, [user]);

  function handleChange(event) {
    const {
      name,
      value,
    } = event.target;

    setAddress(
      (previous) => ({
        ...previous,
        [name]: value,
      })
    );

    setSaved(false);
  }

  function saveAddress() {
    if (
      !address.fullName.trim() ||
      !address.phone.trim() ||
      !address.address.trim() ||
      !address.city.trim() ||
      !address.state.trim() ||
      !address.pincode.trim()
    ) {
      alert(
        "Please fill in all required fields."
      );

      return;
    }

    if (
      !/^\d{6}$/.test(
        address.pincode.trim()
      )
    ) {
      alert(
        "Please enter a valid 6-digit PIN code."
      );

      return;
    }

    localStorage.setItem(
      "shop_to_door_address",
      JSON.stringify(address)
    );

    setSaved(true);
  }

  const inputStyle = {
    width: "100%",
    boxSizing:
      "border-box",
    padding: "12px",
    border:
      "1px solid #d1d5db",
    borderRadius: "8px",
    fontSize: "14px",
    outline: "none",
  };

  const labelStyle = {
    display: "block",
    marginBottom: "6px",
    fontWeight: "600",
    color: "#374151",
  };

  return (
    <div
      style={{
        background: "#ffffff",
        borderRadius: "16px",
        padding: "30px",
        boxShadow:
          "0 4px 20px rgba(0,0,0,0.06)",
      }}
    >
      <BackButton
        onClick={onBack}
      />

      <h1
        style={{
          marginTop: 0,
        }}
      >
        Delivery Address
      </h1>

      <p
        style={{
          color: "#6b7280",
        }}
      >
        Add or update your delivery
        address.
      </p>

      {saved && (
        <div
          style={{
            background:
              "#dcfce7",
            color:
              "#166534",
            padding: "12px",
            borderRadius: "8px",
            marginBottom:
              "20px",
          }}
        >
          ✓ Delivery address
          saved successfully.
        </div>
      )}

      <div
        style={{
          display: "grid",
          gap: "18px",
        }}
      >
        <div>
          <label
            style={labelStyle}
          >
            Full Name *
          </label>

          <input
            name="fullName"
            value={
              address.fullName
            }
            onChange={
              handleChange
            }
            style={
              inputStyle
            }
            placeholder="Enter full name"
          />
        </div>

        <div>
          <label
            style={labelStyle}
          >
            Phone Number *
          </label>

          <input
            name="phone"
            value={
              address.phone
            }
            onChange={
              handleChange
            }
            style={
              inputStyle
            }
            placeholder="Enter phone number"
            inputMode="tel"
          />
        </div>

        <div>
          <label
            style={labelStyle}
          >
            Address *
          </label>

          <textarea
            name="address"
            value={
              address.address
            }
            onChange={
              handleChange
            }
            rows="4"
            style={{
              ...inputStyle,
              resize:
                "vertical",
            }}
            placeholder="House number, street, locality"
          />
        </div>

        <div
          style={{
            display: "grid",
            gridTemplateColumns:
              "repeat(auto-fit, minmax(180px, 1fr))",
            gap: "15px",
          }}
        >
          <div>
            <label
              style={
                labelStyle
              }
            >
              City *
            </label>

            <input
              name="city"
              value={
                address.city
              }
              onChange={
                handleChange
              }
              style={
                inputStyle
              }
              placeholder="City"
            />
          </div>

          <div>
            <label
              style={
                labelStyle
              }
            >
              State *
            </label>

            <input
              name="state"
              value={
                address.state
              }
              onChange={
                handleChange
              }
              style={
                inputStyle
              }
              placeholder="State"
            />
          </div>

          <div>
            <label
              style={
                labelStyle
              }
            >
              PIN Code *
            </label>

            <input
              name="pincode"
              value={
                address.pincode
              }
              onChange={
                handleChange
              }
              style={
                inputStyle
              }
              placeholder="6-digit PIN"
              inputMode="numeric"
              maxLength={6}
            />
          </div>
        </div>

        <div>
          <label
            style={labelStyle}
          >
            Landmark
          </label>

          <input
            name="landmark"
            value={
              address.landmark
            }
            onChange={
              handleChange
            }
            style={
              inputStyle
            }
            placeholder="Nearby landmark"
          />
        </div>

        <button
          type="button"
          onClick={
            saveAddress
          }
          style={{
            border: "none",
            background:
              "#2563eb",
            color:
              "#ffffff",
            padding:
              "13px 20px",
            borderRadius:
              "8px",
            cursor:
              "pointer",
            fontWeight:
              "600",
            fontSize:
              "15px",
          }}
        >
          Save Delivery Address
        </button>
      </div>
    </div>
  );
}

// =========================================================
// ACCOUNT SETTINGS
// =========================================================

function AccountSettings({
  user,
  setUser,
  onBack,
}) {
  const [name, setName] =
    useState(
      user?.name || ""
    );

  const [phone, setPhone] =
    useState(
      user?.phone || ""
    );

  const [saved, setSaved] =
    useState(false);

  function saveSettings() {
    const cleanedName =
      name.trim();

    const cleanedPhone =
      phone.trim();

    if (!cleanedName) {
      alert(
        "Please enter your name."
      );

      return;
    }

    const updatedUser = {
      ...user,
      name: cleanedName,
      phone: cleanedPhone,
    };

    setUser(updatedUser);

    try {
      const token =
        getToken();

      saveAuth(
        token,
        updatedUser
      );
    } catch (error) {
      console.error(
        "Unable to save account information:",
        error
      );
    }

    setSaved(true);
  }

  const inputStyle = {
    width: "100%",
    boxSizing:
      "border-box",
    padding: "12px",
    border:
      "1px solid #d1d5db",
    borderRadius: "8px",
    fontSize: "14px",
  };

  return (
    <div
      style={{
        background: "#ffffff",
        borderRadius: "16px",
        padding: "30px",
        boxShadow:
          "0 4px 20px rgba(0,0,0,0.06)",
      }}
    >
      <BackButton
        onClick={onBack}
      />

      <h1
        style={{
          marginTop: 0,
        }}
      >
        Account Settings
      </h1>

      <p
        style={{
          color: "#6b7280",
        }}
      >
        Manage your Shop To Door
        account information.
      </p>

      {saved && (
        <div
          style={{
            background:
              "#dcfce7",
            color:
              "#166534",
            padding: "12px",
            borderRadius: "8px",
            marginBottom:
              "20px",
          }}
        >
          ✓ Account settings
          updated successfully.
        </div>
      )}

      <div
        style={{
          display: "grid",
          gap: "18px",
          maxWidth: "600px",
        }}
      >
        <div>
          <label
            style={{
              display: "block",
              marginBottom:
                "6px",
              fontWeight:
                "600",
            }}
          >
            Name
          </label>

          <input
            value={name}
            onChange={(event) => {
              setName(
                event.target
                  .value
              );

              setSaved(false);
            }}
            style={
              inputStyle
            }
            placeholder="Enter your name"
          />
        </div>

        <div>
          <label
            style={{
              display: "block",
              marginBottom:
                "6px",
              fontWeight:
                "600",
            }}
          >
            Email
          </label>

          <input
            value={
              user?.email || ""
            }
            disabled
            style={{
              ...inputStyle,
              background:
                "#f3f4f6",
            }}
          />

          <small
            style={{
              color:
                "#6b7280",
            }}
          >
            Email cannot be
            changed here.
          </small>
        </div>

        <div>
          <label
            style={{
              display: "block",
              marginBottom:
                "6px",
              fontWeight:
                "600",
            }}
          >
            Phone
          </label>

          <input
            value={phone}
            onChange={(event) => {
              setPhone(
                event.target
                  .value
              );

              setSaved(false);
            }}
            style={
              inputStyle
            }
            placeholder="Enter phone number"
            inputMode="tel"
          />
        </div>

        <div
          style={{
            padding: "15px",
            background:
              "#f9fafb",
            borderRadius:
              "10px",
          }}
        >
          <strong>
            Account Role
          </strong>

          <p
            style={{
              marginBottom: 0,
              color:
                "#6b7280",
            }}
          >
            {user?.role ||
              "customer"}
          </p>
        </div>

        <div
          style={{
            padding:
              "12px 15px",
            background:
              "#fff7ed",
            color:
              "#9a3412",
            borderRadius:
              "8px",
            fontSize:
              "13px",
          }}
        >
          Account name and phone
          changes are currently
          saved locally in this
          browser.
        </div>

        <button
          type="button"
          onClick={
            saveSettings
          }
          style={{
            border: "none",
            background:
              "#2563eb",
            color:
              "#ffffff",
            padding:
              "13px 20px",
            borderRadius:
              "8px",
            cursor:
              "pointer",
            fontWeight:
              "600",
          }}
        >
          Save Account Settings
        </button>
      </div>
    </div>
  );
}

// =========================================================
// EXPORT
// =========================================================

export default App;