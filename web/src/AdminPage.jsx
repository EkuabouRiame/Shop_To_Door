import { useEffect, useMemo, useRef, useState } from "react";
import { getToken } from "./auth";
import "./AdminPage.css";
import DeliveryAccountForm from "./DeliveryAccountForm";

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL ||
  "https://shop-to-door-backend-294288480400.asia-south2.run.app/api";

const API_ORIGIN = API_BASE_URL.replace(/\/api\/?$/, "");

const ORDER_STATUSES = [
  "pending",
  "assigned",
  "packed",
  "shipped",
  "picked_up",
  "out_for_delivery",
  "delivered",
  "delivery_failed",
  "cancelled",
];

const PAYMENT_STATUSES = [
  "pending",
  "paid",
  "failed",
  "refund_pending",
  "refunded",
];

const ALLOWED_IMAGE_TYPES = [
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/jpg",
];

const ALLOWED_IMAGE_EXTENSIONS = [
  ".jpg",
  ".jpeg",
  ".png",
  ".webp",
];

function AdminPage() {
  // =====================================================
  // PRODUCTS / CATEGORIES
  // =====================================================

  const [products, setProducts] = useState([]);
  const [categories, setCategories] = useState([]);

  const [productLoading, setProductLoading] = useState(false);
  const [categoryLoading, setCategoryLoading] = useState(false);

  const [productError, setProductError] = useState("");
  const [categoryError, setCategoryError] = useState("");

  const [newCategoryName, setNewCategoryName] = useState("");
  const [newCategoryDescription, setNewCategoryDescription] =
    useState("");

  const [newCategoryImage, setNewCategoryImage] = useState(null);
  const [newCategoryImagePreview, setNewCategoryImagePreview] =
    useState("");
  const [updatingCategoryImageId, setUpdatingCategoryImageId] =
    useState(null);

  const categoryImageInputRef = useRef(null);

  const [productForm, setProductForm] = useState({
    name: "",
    sku: "",
    description: "",
    price: "",
    discount_price: "",
    stock: "",
    category_id: "",
    is_active: true,
  });

  const [productImages, setProductImages] = useState([]);

  // =====================================================
  // ORDERS
  // =====================================================

  const [orders, setOrders] = useState([]);
  const [ordersLoading, setOrdersLoading] = useState(false);
  const [ordersError, setOrdersError] = useState("");

  const [updatingOrderStatusId, setUpdatingOrderStatusId] =
    useState(null);

  // =====================================================
  // DELIVERY PERSONS
  // =====================================================

  const [deliveryPersons, setDeliveryPersons] = useState([]);
  const [deliveryLoading, setDeliveryLoading] = useState(false);
  const [deliveryError, setDeliveryError] = useState("");

  const [deliveryAccountMessage, setDeliveryAccountMessage] =
    useState("");

  const [assigningOrderId, setAssigningOrderId] = useState(null);

  // =====================================================
  // GENERAL
  // =====================================================

  const [message, setMessage] = useState("");
  const [activeSection, setActiveSection] = useState("dashboard");

  // =====================================================
  // AUTH HEADERS
  // =====================================================

  const getHeaders = () => {
    const token = getToken();

    return {
      "Content-Type": "application/json",
      ...(token
        ? {
            Authorization: `Bearer ${token}`,
          }
        : {}),
    };
  };

  const getMultipartHeaders = () => {
    const token = getToken();

    return {
      ...(token
        ? {
            Authorization: `Bearer ${token}`,
          }
        : {}),
    };
  };

  // =====================================================
  // API HELPER
  // =====================================================

  const apiRequest = async (url, options = {}) => {
    const response = await fetch(url, {
      ...options,
      headers: {
        ...getHeaders(),
        ...(options.headers || {}),
      },
    });

    let data = {};

    try {
      data = await response.json();
    } catch {
      data = {};
    }

    if (!response.ok) {
      throw new Error(
        data.message ||
          data.error ||
          `Request failed with status ${response.status}`
      );
    }

    return data;
  };

  // =====================================================
  // IMAGE URL HELPER
  // =====================================================

  const getImageUrl = (image) => {
    if (!image) {
      return "";
    }

    if (/^https?:\/\//i.test(image)) {
      return image;
    }

    if (image.startsWith("/")) {
      return `${API_ORIGIN}${image}`;
    }

    return `${API_ORIGIN}/uploads/categories/${image}`;
  };

  // =====================================================
  // IMAGE VALIDATION
  // =====================================================

  const validateImageFile = (file) => {
    if (!file) {
      return "Please select an image.";
    }

    const extension = file.name
      ? file.name
          .substring(file.name.lastIndexOf("."))
          .toLowerCase()
      : "";

    const validType = ALLOWED_IMAGE_TYPES.includes(file.type);
    const validExtension =
      ALLOWED_IMAGE_EXTENSIONS.includes(extension);

    if (!validType && !validExtension) {
      return "Please select a JPG, JPEG, PNG or WEBP image.";
    }

    return "";
  };

  // =====================================================
  // LOAD CATEGORIES
  // =====================================================

  const loadCategories = async () => {
    setCategoryLoading(true);
    setCategoryError("");

    try {
      const data = await apiRequest(
        `${API_BASE_URL}/admin/categories`
      );

      setCategories(data.categories || []);
    } catch (error) {
      console.error(error);
      setCategoryError(error.message);
    } finally {
      setCategoryLoading(false);
    }
  };

  // =====================================================
  // LOAD PRODUCTS
  // =====================================================

  const loadProducts = async () => {
    setProductLoading(true);
    setProductError("");

    try {
      const data = await apiRequest(
        `${API_BASE_URL}/admin/products`
      );

      setProducts(data.products || []);
    } catch (error) {
      console.error(error);
      setProductError(error.message);
    } finally {
      setProductLoading(false);
    }
  };

  // =====================================================
  // LOAD ORDERS
  // =====================================================

  const loadOrders = async () => {
    setOrdersLoading(true);
    setOrdersError("");

    try {
      const data = await apiRequest(`${API_BASE_URL}/orders/`);

      setOrders(data.orders || []);
    } catch (error) {
      console.error(error);
      setOrdersError(error.message);
    } finally {
      setOrdersLoading(false);
    }
  };

  // =====================================================
  // LOAD DELIVERY PERSONS
  // =====================================================

  const loadDeliveryPersons = async () => {
    setDeliveryLoading(true);
    setDeliveryError("");

    try {
      const data = await apiRequest(
        `${API_BASE_URL}/orders/admin/delivery-persons`
      );

      setDeliveryPersons(data.delivery_persons || []);
    } catch (error) {
      console.error(error);
      setDeliveryError(error.message);
    } finally {
      setDeliveryLoading(false);
    }
  };

  // =====================================================
  // INITIAL LOAD
  // =====================================================

  useEffect(() => {
    loadCategories();
    loadProducts();
    loadOrders();
    loadDeliveryPersons();
  }, []);

  // =====================================================
  // CLEAN CATEGORY IMAGE PREVIEW
  // =====================================================

  useEffect(() => {
    return () => {
      if (newCategoryImagePreview) {
        URL.revokeObjectURL(newCategoryImagePreview);
      }
    };
  }, [newCategoryImagePreview]);

  // =====================================================
  // DASHBOARD COUNTS
  // =====================================================

  const dashboardStats = useMemo(() => {
    const totalOrders = orders.length;

    const pendingOrders = orders.filter(
      (order) => order.status === "pending"
    ).length;

    const assignedOrders = orders.filter(
      (order) => order.status === "assigned"
    ).length;

    const outForDelivery = orders.filter(
      (order) => order.status === "out_for_delivery"
    ).length;

    const deliveredOrders = orders.filter(
      (order) => order.status === "delivered"
    ).length;

    const cancelledOrders = orders.filter(
      (order) => order.status === "cancelled"
    ).length;

    const totalSales = orders.reduce(
      (sum, order) =>
        sum + Number(order.total_amount || 0),
      0
    );

    return {
      totalOrders,
      pendingOrders,
      assignedOrders,
      outForDelivery,
      deliveredOrders,
      cancelledOrders,
      totalSales,
    };
  }, [orders]);

  // =====================================================
  // CATEGORY IMAGE CHANGE
  // =====================================================

  const handleCategoryImageChange = (event) => {
    const file = event.target.files?.[0] || null;

    setCategoryError("");
    setMessage("");

    if (!file) {
      setNewCategoryImage(null);
      setNewCategoryImagePreview("");
      return;
    }

    const validationError = validateImageFile(file);

    if (validationError) {
      setNewCategoryImage(null);
      setNewCategoryImagePreview("");

      if (categoryImageInputRef.current) {
        categoryImageInputRef.current.value = "";
      }

      setCategoryError(validationError);
      return;
    }

    if (newCategoryImagePreview) {
      URL.revokeObjectURL(newCategoryImagePreview);
    }

    const previewUrl = URL.createObjectURL(file);

    setNewCategoryImage(file);
    setNewCategoryImagePreview(previewUrl);
  };

  // =====================================================
  // RESET CATEGORY IMAGE INPUT
  // =====================================================

  const resetCategoryImageInput = () => {
    if (newCategoryImagePreview) {
      URL.revokeObjectURL(newCategoryImagePreview);
    }

    setNewCategoryImage(null);
    setNewCategoryImagePreview("");

    if (categoryImageInputRef.current) {
      categoryImageInputRef.current.value = "";
    }
  };

  // =====================================================
  // UPLOAD CATEGORY IMAGE
  // =====================================================

  const uploadCategoryImage = async (
    categoryId,
    imageFile
  ) => {
    if (!imageFile) {
      return null;
    }

    const validationError = validateImageFile(imageFile);

    if (validationError) {
      throw new Error(validationError);
    }

    const formData = new FormData();

    formData.append("image", imageFile);

    const response = await fetch(
      `${API_BASE_URL}/admin/categories/${categoryId}/image`,
      {
        method: "POST",
        headers: getMultipartHeaders(),
        body: formData,
      }
    );

    let data = {};

    try {
      data = await response.json();
    } catch {
      data = {};
    }

    if (!response.ok) {
      throw new Error(
        data.message ||
          data.error ||
          `Category image upload failed with status ${response.status}`
      );
    }

    return data;
  };

  // =====================================================
  // ADD CATEGORY
  // =====================================================

  const handleAddCategory = async (event) => {
    event.preventDefault();

    setCategoryError("");
    setMessage("");

    if (!newCategoryName.trim()) {
      setCategoryError("Category name is required.");
      return;
    }

    if (newCategoryImage) {
      const imageValidationError =
        validateImageFile(newCategoryImage);

      if (imageValidationError) {
        setCategoryError(imageValidationError);
        return;
      }
    }

    setCategoryLoading(true);

    try {
      const categoryData = await apiRequest(
        `${API_BASE_URL}/admin/categories`,
        {
          method: "POST",
          body: JSON.stringify({
            name: newCategoryName.trim(),
            description: newCategoryDescription.trim(),
          }),
        }
      );

      const createdCategory = categoryData.category;

      if (!createdCategory?.id) {
        throw new Error(
          "Category was created, but no category ID was returned."
        );
      }

      if (newCategoryImage) {
        await uploadCategoryImage(
          createdCategory.id,
          newCategoryImage
        );
      }

      setNewCategoryName("");
      setNewCategoryDescription("");
      resetCategoryImageInput();

      setMessage(
        newCategoryImage
          ? "Category and image added successfully."
          : "Category added successfully."
      );

      await loadCategories();
    } catch (error) {
      console.error(error);
      setCategoryError(error.message);
    } finally {
      setCategoryLoading(false);
    }
  };

  // =====================================================
  // REPLACE CATEGORY IMAGE
  // =====================================================

  const handleReplaceCategoryImage = async (
    categoryId
  ) => {
    setCategoryError("");
    setMessage("");

    const input = document.createElement("input");

    input.type = "file";
    input.accept =
      "image/png,image/jpeg,image/jpg,image/webp";

    input.onchange = async (event) => {
      const file = event.target.files?.[0] || null;

      if (!file) {
        return;
      }

      const validationError = validateImageFile(file);

      if (validationError) {
        setCategoryError(validationError);
        return;
      }

      setUpdatingCategoryImageId(categoryId);

      try {
        await uploadCategoryImage(categoryId, file);

        setMessage(
          "Category image replaced successfully."
        );

        await loadCategories();
      } catch (error) {
        console.error(error);
        setCategoryError(error.message);
      } finally {
        setUpdatingCategoryImageId(null);
      }
    };

    input.click();
  };

  // =====================================================
  // DELETE CATEGORY
  // =====================================================

  const handleDeleteCategory = async (categoryId) => {
    const confirmed = window.confirm(
      "Are you sure you want to delete this category? This will also delete products belonging to this category."
    );

    if (!confirmed) {
      return;
    }

    setCategoryError("");
    setMessage("");

    try {
      await apiRequest(
        `${API_BASE_URL}/admin/categories/${categoryId}`,
        {
          method: "DELETE",
        }
      );

      setMessage("Category deleted successfully.");

      await loadCategories();
      await loadProducts();
    } catch (error) {
      console.error(error);
      setCategoryError(error.message);
    }
  };

  // =====================================================
  // PRODUCT FORM CHANGE
  // =====================================================

  const handleProductChange = (event) => {
    const {
      name,
      value,
      type,
      checked,
    } = event.target;

    setProductForm((previous) => ({
      ...previous,
      [name]:
        type === "checkbox"
          ? checked
          : value,
    }));
  };

  // =====================================================
  // PRODUCT IMAGE CHANGE
  // =====================================================

  const handleImageChange = (event) => {
    const files = Array.from(
      event.target.files || []
    );

    setProductImages(files);
  };

  // =====================================================
  // ADD PRODUCT
  // =====================================================

  const handleAddProduct = async (event) => {
    event.preventDefault();

    setProductError("");
    setMessage("");

    if (!productForm.name.trim()) {
      setProductError("Product name is required.");
      return;
    }

    if (!productForm.sku.trim()) {
      setProductError("Product SKU is required.");
      return;
    }

    if (
      productForm.price === "" ||
      Number(productForm.price) < 0
    ) {
      setProductError(
        "A valid product price is required."
      );
      return;
    }

    if (!productForm.category_id) {
      setProductError(
        "Please select a product category."
      );
      return;
    }

    if (
      !productImages ||
      productImages.length === 0
    ) {
      setProductError("Product image is required.");
      return;
    }

    const imageFile = productImages[0];

    const imageValidationError =
      validateImageFile(imageFile);

    if (imageValidationError) {
      setProductError(imageValidationError);
      return;
    }

    setProductLoading(true);

    try {
      const formData = new FormData();

      formData.append(
        "name",
        productForm.name.trim()
      );

      formData.append(
        "sku",
        productForm.sku.trim()
      );

      formData.append(
        "description",
        productForm.description.trim()
      );

      formData.append(
        "price",
        String(Number(productForm.price))
      );

      if (productForm.discount_price !== "") {
        formData.append(
          "discount_price",
          String(
            Number(productForm.discount_price)
          )
        );
      }

      formData.append(
        "stock",
        String(
          Number(productForm.stock || 0)
        )
      );

      formData.append(
        "category_id",
        String(
          Number(productForm.category_id)
        )
      );

      formData.append(
        "is_active",
        String(productForm.is_active)
      );

      formData.append("image", imageFile);

      const response = await fetch(
        `${API_BASE_URL}/admin/products`,
        {
          method: "POST",
          headers: getMultipartHeaders(),
          body: formData,
        }
      );

      let data = {};

      try {
        data = await response.json();
      } catch {
        data = {};
      }

      if (!response.ok) {
        throw new Error(
          data.message ||
            data.error ||
            `Product creation failed with status ${response.status}`
        );
      }

      setProductForm({
        name: "",
        sku: "",
        description: "",
        price: "",
        discount_price: "",
        stock: "",
        category_id: "",
        is_active: true,
      });

      setProductImages([]);

      const fileInputs =
        document.querySelectorAll(
          'input[type="file"]'
        );

      fileInputs.forEach((input) => {
        if (
          input !==
          categoryImageInputRef.current
        ) {
          input.value = "";
        }
      });

      setMessage("Product added successfully.");

      await loadProducts();
    } catch (error) {
      console.error(error);
      setProductError(error.message);
    } finally {
      setProductLoading(false);
    }
  };

  // =====================================================
  // DELETE PRODUCT
  // =====================================================

  const handleDeleteProduct = async (productId) => {
    const confirmed = window.confirm(
      "Are you sure you want to delete this product?"
    );

    if (!confirmed) {
      return;
    }

    setProductError("");
    setMessage("");

    try {
      const data = await apiRequest(
        `${API_BASE_URL}/admin/products/${productId}`,
        {
          method: "DELETE",
        }
      );

      setMessage(
        data.message ||
          "Product deleted successfully."
      );

      await loadProducts();
    } catch (error) {
      console.error(error);
      setProductError(error.message);
    }
  };

  // =====================================================
  // UPDATE ORDER STATUS
  // =====================================================

  const handleOrderStatusChange = async (
    orderId,
    newStatus
  ) => {
    if (!newStatus) {
      return;
    }

    const currentOrder = orders.find(
      (order) => order.id === orderId
    );

    if (!currentOrder) {
      return;
    }

    if (currentOrder.status === newStatus) {
      return;
    }

    setUpdatingOrderStatusId(orderId);
    setOrdersError("");
    setMessage("");

    try {
      const data = await apiRequest(
        `${API_BASE_URL}/orders/admin/${orderId}/status`,
        {
          method: "POST",
          body: JSON.stringify({
            status: newStatus,
          }),
        }
      );

      if (data.order) {
        setOrders((previous) =>
          previous.map((order) =>
            order.id === orderId
              ? data.order
              : order
          )
        );
      } else {
        await loadOrders();
      }

      setMessage(
        `Order #${orderId} status updated to ${formatStatus(
          newStatus
        )}.`
      );
    } catch (error) {
      console.error(error);
      setOrdersError(error.message);
    } finally {
      setUpdatingOrderStatusId(null);
    }
  };

  // =====================================================
  // ASSIGN DELIVERY PERSON
  // =====================================================

  const handleAssignDeliveryPerson = async (
    orderId,
    deliveryPersonId
  ) => {
    if (!deliveryPersonId) {
      return;
    }

    setAssigningOrderId(orderId);
    setOrdersError("");
    setMessage("");

    try {
      const data = await apiRequest(
        `${API_BASE_URL}/orders/admin/${orderId}/assign`,
        {
          method: "POST",
          body: JSON.stringify({
            delivery_person_id:
              Number(deliveryPersonId),
          }),
        }
      );

      if (data.order) {
        setOrders((previous) =>
          previous.map((order) =>
            order.id === orderId
              ? data.order
              : order
          )
        );
      }

      setMessage(
        "Delivery person assigned successfully."
      );
    } catch (error) {
      console.error(error);
      setOrdersError(error.message);
    } finally {
      setAssigningOrderId(null);
    }
  };

  // =====================================================
  // UNASSIGN DELIVERY PERSON
  // =====================================================

  const handleUnassignDeliveryPerson = async (
    orderId
  ) => {
    const confirmed = window.confirm(
      "Remove the delivery person from this order?"
    );

    if (!confirmed) {
      return;
    }

    setAssigningOrderId(orderId);
    setOrdersError("");
    setMessage("");

    try {
      const data = await apiRequest(
        `${API_BASE_URL}/orders/admin/${orderId}/unassign`,
        {
          method: "POST",
        }
      );

      if (data.order) {
        setOrders((previous) =>
          previous.map((order) =>
            order.id === orderId
              ? data.order
              : order
          )
        );
      }

      setMessage(
        "Delivery person removed successfully."
      );
    } catch (error) {
      console.error(error);
      setOrdersError(error.message);
    } finally {
      setAssigningOrderId(null);
    }
  };

  // =====================================================
  // STATUS LABEL
  // =====================================================

  const formatStatus = (status) => {
    if (!status) {
      return "Unknown";
    }

    return status
      .split("_")
      .map(
        (word) =>
          word.charAt(0).toUpperCase() +
          word.slice(1)
      )
      .join(" ");
  };

  // =====================================================
  // PAYMENT STATUS LABEL
  // =====================================================

  const formatPaymentStatus = (status) => {
    if (!status) {
      return "Unknown";
    }

    return status
      .split("_")
      .map(
        (word) =>
          word.charAt(0).toUpperCase() +
          word.slice(1)
      )
      .join(" ");
  };

  // =====================================================
  // DATE FORMAT
  // =====================================================

  const formatDate = (date) => {
    if (!date) {
      return "—";
    }

    try {
      return new Date(date).toLocaleString("en-IN");
    } catch {
      return date;
    }
  };

  // =====================================================
  // CURRENCY
  // =====================================================

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat("en-IN", {
      style: "currency",
      currency: "INR",
    }).format(Number(amount || 0));
  };

  // =====================================================
  // RENDER
  // =====================================================

  return (
    <div className="admin-page">

      {/* =================================================
          HEADER
      ================================================= */}

      <div className="admin-header">
        <div>
          <h1>Admin Dashboard</h1>

          <p>
            Manage products, categories,
            orders and delivery.
          </p>
        </div>

        <button
          type="button"
          className="admin-refresh-btn"
          onClick={() => {
            loadProducts();
            loadCategories();
            loadOrders();
            loadDeliveryPersons();
          }}
        >
          ↻ Refresh
        </button>
      </div>

      {/* =================================================
          MESSAGE
      ================================================= */}

      {message && (
        <div className="admin-success-message">
          {message}
        </div>
      )}

      {/* =================================================
          NAVIGATION
      ================================================= */}

      <div className="admin-tabs">

        <button
          type="button"
          className={
            activeSection === "dashboard"
              ? "active"
              : ""
          }
          onClick={() =>
            setActiveSection("dashboard")
          }
        >
          Dashboard
        </button>

        <button
          type="button"
          className={
            activeSection === "orders"
              ? "active"
              : ""
          }
          onClick={() =>
            setActiveSection("orders")
          }
        >
          Orders
        </button>

        <button
          type="button"
          className={
            activeSection === "products"
              ? "active"
              : ""
          }
          onClick={() =>
            setActiveSection("products")
          }
        >
          Products
        </button>

        <button
          type="button"
          className={
            activeSection === "categories"
              ? "active"
              : ""
          }
          onClick={() =>
            setActiveSection("categories")
          }
        >
          Categories
        </button>

        <button
          type="button"
          className={
            activeSection === "delivery"
              ? "active"
              : ""
          }
          onClick={() =>
            setActiveSection("delivery")
          }
        >
          Delivery
        </button>

      </div>

      {/* =================================================
          DASHBOARD
      ================================================= */}

      {activeSection === "dashboard" && (
        <section className="admin-section">

          <h2>Dashboard Overview</h2>

          <div className="admin-stats-grid">

            <div className="admin-stat-card">
              <span>Total Orders</span>
              <strong>
                {dashboardStats.totalOrders}
              </strong>
            </div>

            <div className="admin-stat-card">
              <span>Pending</span>
              <strong>
                {dashboardStats.pendingOrders}
              </strong>
            </div>

            <div className="admin-stat-card">
              <span>Assigned</span>
              <strong>
                {dashboardStats.assignedOrders}
              </strong>
            </div>

            <div className="admin-stat-card">
              <span>Out for Delivery</span>
              <strong>
                {dashboardStats.outForDelivery}
              </strong>
            </div>

            <div className="admin-stat-card">
              <span>Delivered</span>
              <strong>
                {dashboardStats.deliveredOrders}
              </strong>
            </div>

            <div className="admin-stat-card">
              <span>Cancelled</span>
              <strong>
                {dashboardStats.cancelledOrders}
              </strong>
            </div>

            <div className="admin-stat-card">
              <span>Products</span>
              <strong>{products.length}</strong>
            </div>

            <div className="admin-stat-card">
              <span>Delivery Persons</span>
              <strong>
                {deliveryPersons.length}
              </strong>
            </div>

          </div>

          <div className="admin-sales-card">

            <h3>Total Order Value</h3>

            <strong>
              {formatCurrency(
                dashboardStats.totalSales
              )}
            </strong>

          </div>

        </section>
      )}

      {/* =================================================
          ORDERS
      ================================================= */}

      {activeSection === "orders" && (
        <section className="admin-section">

          <div className="section-heading">

            <div>
              <h2>Orders</h2>

              <p>
                Manage customer orders,
                statuses and delivery
                assignments.
              </p>
            </div>

            <button
              type="button"
              onClick={loadOrders}
              disabled={ordersLoading}
            >
              {ordersLoading
                ? "Loading..."
                : "Refresh Orders"}
            </button>

          </div>

          {ordersError && (
            <div className="admin-error-message">
              {ordersError}
            </div>
          )}

          {ordersLoading ? (
            <div className="admin-loading">
              Loading orders...
            </div>
          ) : orders.length === 0 ? (
            <div className="admin-empty">
              No orders found.
            </div>
          ) : (
            <div className="orders-list">

              {orders.map((order) => (
                <div
                  className="admin-order-card"
                  key={order.id}
                >

                  <div className="order-card-header">

                    <div>

                      <h3>
                        Order #{order.id}
                      </h3>

                      <small>
                        {formatDate(
                          order.created_at
                        )}
                      </small>

                    </div>

                    <div className="order-header-right">

                      <span
                        className={`order-status status-${order.status}`}
                      >
                        {formatStatus(
                          order.status
                        )}
                      </span>

                      <strong>
                        {formatCurrency(
                          order.total_amount
                        )}
                      </strong>

                    </div>

                  </div>

                  <div className="order-info-grid">

                    <div className="order-info-box">

                      <h4>Customer</h4>

                      <p>
                        <strong>
                          {order.shipping?.name ||
                            "—"}
                        </strong>
                      </p>

                      <p>
                        Customer ID:{" "}
                        {order.user_id}
                      </p>

                      <p>
                        📞{" "}
                        {order.shipping?.phone ||
                          "—"}
                      </p>

                    </div>

                    <div className="order-info-box">

                      <h4>Delivery Address</h4>

                      <p>
                        {order.shipping?.address ||
                          "—"}
                      </p>

                      <p>
                        {order.shipping?.city ||
                          "—"}

                        {order.shipping?.state
                          ? `, ${order.shipping.state}`
                          : ""}
                      </p>

                      <p>
                        PIN:{" "}
                        {order.shipping?.pincode ||
                          "—"}
                      </p>

                    </div>

                    <div className="order-info-box">

                      <h4>Payment</h4>

                      <p>
                        Method:{" "}
                        <strong>
                          {String(
                            order.payment_method ||
                              "—"
                          ).toUpperCase()}
                        </strong>
                      </p>

                      <p>
                        Status:{" "}

                        <span
                          className={`payment-status payment-${order.payment_status}`}
                        >
                          {formatPaymentStatus(
                            order.payment_status
                          )}
                        </span>
                      </p>

                      <p>
                        Subtotal:{" "}
                        {formatCurrency(
                          order.subtotal
                        )}
                      </p>

                    </div>

                  </div>

                  <div className="delivery-assignment-box">

                    <div>

                      <h4>
                        🚚 Delivery Person
                      </h4>

                      {order.delivery_person ? (
                        <div className="assigned-person">

                          <strong>
                            {
                              order
                                .delivery_person
                                .name
                            }
                          </strong>

                          <span>
                            {order
                              .delivery_person
                              .phone ||
                              order
                                .delivery_person
                                .email ||
                              "No contact"}
                          </span>

                        </div>
                      ) : (
                        <p className="not-assigned">
                          No delivery person
                          assigned.
                        </p>
                      )}

                    </div>

                    <div className="delivery-assignment-controls">

                      <select
                        value={
                          order.delivery_person_id ||
                          ""
                        }
                        disabled={
                          assigningOrderId ===
                            order.id ||
                          order.status ===
                            "delivered" ||
                          order.status ===
                            "cancelled"
                        }
                        onChange={(event) =>
                          handleAssignDeliveryPerson(
                            order.id,
                            event.target.value
                          )
                        }
                      >

                        <option value="">
                          Select delivery person
                        </option>

                        {deliveryPersons.map(
                          (person) => (
                            <option
                              key={person.id}
                              value={person.id}
                              disabled={
                                !person.is_active
                              }
                            >
                              {person.name}

                              {!person.is_active
                                ? " (Inactive)"
                                : ""}
                            </option>
                          )
                        )}

                      </select>

                      {order.delivery_person_id && (
                        <button
                          type="button"
                          className="danger-button"
                          disabled={
                            assigningOrderId ===
                            order.id
                          }
                          onClick={() =>
                            handleUnassignDeliveryPerson(
                              order.id
                            )
                          }
                        >
                          {assigningOrderId ===
                          order.id
                            ? "Updating..."
                            : "Unassign"}
                        </button>
                      )}

                    </div>

                  </div>

                  <div className="order-items-section">

                    <h4>Order Items</h4>

                    <div className="order-items-list">

                      {order.items?.map(
                        (item) => (
                          <div
                            className="order-item-row"
                            key={item.id}
                          >

                            <div>

                              <strong>
                                {
                                  item.product_name
                                }
                              </strong>

                              <small>
                                SKU:{" "}
                                {item.product_sku ||
                                  "—"}
                              </small>

                            </div>

                            <span>
                              ×{" "}
                              {item.quantity}
                            </span>

                            <span>
                              {formatCurrency(
                                item.total_price
                              )}
                            </span>

                          </div>
                        )
                      )}

                    </div>

                  </div>

                  <div className="order-status-section">

                    <div>

                      <h4>Order Status</h4>

                      <span
                        className={`order-status status-${order.status}`}
                      >
                        {formatStatus(
                          order.status
                        )}
                      </span>

                    </div>

                    <div className="order-status-control">

                      <label
                        htmlFor={`status-${order.id}`}
                      >
                        Change Status
                      </label>

                      <select
                        id={`status-${order.id}`}
                        value={
                          order.status ||
                          "pending"
                        }
                        disabled={
                          updatingOrderStatusId ===
                          order.id
                        }
                        onChange={(event) =>
                          handleOrderStatusChange(
                            order.id,
                            event.target.value
                          )
                        }
                      >

                        {ORDER_STATUSES.map(
                          (status) => (
                            <option
                              key={status}
                              value={status}
                            >
                              {formatStatus(
                                status
                              )}
                            </option>
                          )
                        )}

                      </select>

                      {updatingOrderStatusId ===
                        order.id && (
                        <span className="status-updating">
                          Updating...
                        </span>
                      )}

                    </div>

                  </div>

                  <div className="status-timeline">

                    {ORDER_STATUSES.map(
                      (status) => (
                        <span
                          key={status}
                          className={
                            order.status ===
                            status
                              ? "current"
                              : ""
                          }
                        >
                          {formatStatus(
                            status
                          )}
                        </span>
                      )
                    )}

                  </div>

                  {order.notes && (
                    <div className="order-notes">

                      <strong>
                        Customer Note:
                      </strong>

                      <p>
                        {order.notes}
                      </p>

                    </div>
                  )}

                </div>
              ))}

            </div>
          )}

        </section>
      )}

      {/* =================================================
          PRODUCTS
      ================================================= */}

      {activeSection === "products" && (
        <section className="admin-section">

          <h2>Products</h2>

          {productError && (
            <div className="admin-error-message">
              {productError}
            </div>
          )}

          <form
            className="admin-form"
            onSubmit={handleAddProduct}
          >

            <h3>Add New Product</h3>

            <div className="form-grid">

              <input
                type="text"
                name="name"
                placeholder="Product name"
                value={productForm.name}
                onChange={
                  handleProductChange
                }
                required
              />

              <input
                type="text"
                name="sku"
                placeholder="SKU"
                value={productForm.sku}
                onChange={
                  handleProductChange
                }
                required
              />

              <input
                type="number"
                name="price"
                placeholder="Price"
                min="0"
                step="0.01"
                value={productForm.price}
                onChange={
                  handleProductChange
                }
                required
              />

              <input
                type="number"
                name="discount_price"
                placeholder="Discount price"
                min="0"
                step="0.01"
                value={
                  productForm.discount_price
                }
                onChange={
                  handleProductChange
                }
              />

              <input
                type="number"
                name="stock"
                placeholder="Stock"
                min="0"
                value={productForm.stock}
                onChange={
                  handleProductChange
                }
              />

              <select
                name="category_id"
                value={
                  productForm.category_id
                }
                onChange={
                  handleProductChange
                }
                required
              >

                <option value="">
                  Select category
                </option>

                {categories.map(
                  (category) => (
                    <option
                      key={category.id}
                      value={category.id}
                    >
                      {category.name}
                    </option>
                  )
                )}

              </select>

            </div>

            <textarea
              name="description"
              placeholder="Product description"
              value={
                productForm.description
              }
              onChange={
                handleProductChange
              }
              rows="4"
            />

            <label className="checkbox-label">

              <input
                type="checkbox"
                name="is_active"
                checked={
                  productForm.is_active
                }
                onChange={
                  handleProductChange
                }
              />

              Product active

            </label>

            <label>
              Product image
            </label>

            <input
              type="file"
              accept="image/png,image/jpeg,image/jpg,image/webp"
              onChange={handleImageChange}
              required
            />

            {productImages.length > 0 && (
              <p>
                {productImages[0].name} selected.
              </p>
            )}

            <button
              type="submit"
              disabled={productLoading}
            >
              {productLoading
                ? "Adding..."
                : "Add Product"}
            </button>

          </form>

          <div className="admin-table-wrapper">

            <h3>Existing Products</h3>

            {products.length === 0 ? (
              <p>
                No products found.
              </p>
            ) : (
              <table className="admin-table">

                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Product</th>
                    <th>SKU</th>
                    <th>Price</th>
                    <th>Stock</th>
                    <th>Action</th>
                  </tr>
                </thead>

                <tbody>

                  {products.map(
                    (product) => (
                      <tr
                        key={product.id}
                      >

                        <td>
                          {product.id}
                        </td>

                        <td>
                          {product.name}
                        </td>

                        <td>
                          {product.sku ||
                            "—"}
                        </td>

                        <td>
                          {formatCurrency(
                            product.discount_price ??
                              product.price
                          )}
                        </td>

                        <td>
                          {product.stock}
                        </td>

                        <td>

                          <button
                            type="button"
                            className="danger-button"
                            onClick={() =>
                              handleDeleteProduct(
                                product.id
                              )
                            }
                          >
                            Delete
                          </button>

                        </td>

                      </tr>
                    )
                  )}

                </tbody>

              </table>
            )}

          </div>

        </section>
      )}

      {/* =================================================
          CATEGORIES
      ================================================= */}

      {activeSection === "categories" && (
        <section className="admin-section">

          <h2>Categories</h2>

          {categoryError && (
            <div className="admin-error-message">
              {categoryError}
            </div>
          )}

          <form
            className="admin-form"
            onSubmit={handleAddCategory}
          >

            <h3>Add Category</h3>

            <input
              type="text"
              placeholder="Category name"
              value={newCategoryName}
              onChange={(event) =>
                setNewCategoryName(
                  event.target.value
                )
              }
              required
            />

            <textarea
              placeholder="Description"
              value={
                newCategoryDescription
              }
              onChange={(event) =>
                setNewCategoryDescription(
                  event.target.value
                )
              }
              rows="3"
            />

            {/* CATEGORY IMAGE */}

            <div
              style={{
                marginTop: "10px",
              }}
            >

              <label
                htmlFor="category-image-input"
                style={{
                  display: "block",
                  marginBottom: "8px",
                  fontWeight: "600",
                }}
              >
                Category image
              </label>

              <input
                id="category-image-input"
                ref={categoryImageInputRef}
                type="file"
                accept="image/png,image/jpeg,image/jpg,image/webp"
                onChange={
                  handleCategoryImageChange
                }
              />

              <p
                style={{
                  marginTop: "6px",
                  fontSize: "13px",
                  color: "#777",
                }}
              >
                JPG, JPEG, PNG or WEBP
              </p>

              {newCategoryImagePreview && (
                <div
                  style={{
                    marginTop: "12px",
                    display: "flex",
                    alignItems: "center",
                    gap: "12px",
                    flexWrap: "wrap",
                  }}
                >

                  <img
                    src={
                      newCategoryImagePreview
                    }
                    alt="Category preview"
                    style={{
                      width: "100px",
                      height: "100px",
                      objectFit: "cover",
                      borderRadius: "10px",
                      border:
                        "1px solid #ddd",
                    }}
                  />

                  <div>

                    <strong>
                      {newCategoryImage.name}
                    </strong>

                    <br />

                    <button
                      type="button"
                      onClick={
                        resetCategoryImageInput
                      }
                      style={{
                        marginTop: "8px",
                      }}
                    >
                      Remove Image
                    </button>

                  </div>

                </div>
              )}

            </div>

            <button
              type="submit"
              disabled={categoryLoading}
            >
              {categoryLoading
                ? "Adding..."
                : "Add Category"}
            </button>

          </form>

          <div className="admin-table-wrapper">

            <h3>Existing Categories</h3>

            {categories.length === 0 ? (
              <p>
                No categories found.
              </p>
            ) : (
              <table className="admin-table">

                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Image</th>
                    <th>Name</th>
                    <th>Slug</th>
                    <th>Action</th>
                  </tr>
                </thead>

                <tbody>

                  {categories.map(
                    (category) => (
                      <tr
                        key={category.id}
                      >

                        <td>
                          {category.id}
                        </td>

                        <td>

                          {category.image ? (
                            <img
                              src={getImageUrl(
                                category.image
                              )}
                              alt={
                                category.name
                              }
                              style={{
                                width: "70px",
                                height: "70px",
                                objectFit:
                                  "cover",
                                borderRadius:
                                  "10px",
                                border:
                                  "1px solid #ddd",
                                display:
                                  "block",
                              }}
                              onError={(event) => {
                                event.currentTarget.style.display =
                                  "none";
                              }}
                            />
                          ) : (
                            <span
                              style={{
                                color: "#999",
                              }}
                            >
                              No image
                            </span>
                          )}

                        </td>

                        <td>
                          {category.name}
                        </td>

                        <td>
                          {category.slug ||
                            "—"}
                        </td>

                        <td>

                          <div
                            style={{
                              display: "flex",
                              gap: "8px",
                              flexWrap:
                                "wrap",
                            }}
                          >

                            <button
                              type="button"
                              disabled={
                                updatingCategoryImageId ===
                                category.id
                              }
                              onClick={() =>
                                handleReplaceCategoryImage(
                                  category.id
                                )
                              }
                            >
                              {updatingCategoryImageId ===
                              category.id
                                ? "Uploading..."
                                : category.image
                                ? "Replace Image"
                                : "Upload Image"}
                            </button>

                            <button
                              type="button"
                              className="danger-button"
                              onClick={() =>
                                handleDeleteCategory(
                                  category.id
                                )
                              }
                            >
                              Delete
                            </button>

                          </div>

                        </td>

                      </tr>
                    )
                  )}

                </tbody>

              </table>
            )}

          </div>

        </section>
      )}

      {/* =================================================
          DELIVERY PERSONS
      ================================================= */}

      {activeSection === "delivery" && (
        <section className="admin-section">

          <DeliveryAccountForm
            onCreated={async () => {
              setDeliveryAccountMessage(
                "Delivery account created successfully."
              );

              await loadDeliveryPersons();
            }}
          />

          {deliveryAccountMessage && (
            <div className="admin-success-message">
              {deliveryAccountMessage}
            </div>
          )}

          <div className="section-heading">

            <div>

              <h2>
                Delivery Persons
              </h2>

              <p>
                Delivery accounts available
                for order assignment.
              </p>

            </div>

            <button
              type="button"
              onClick={
                loadDeliveryPersons
              }
              disabled={deliveryLoading}
            >
              {deliveryLoading
                ? "Loading..."
                : "Refresh"}
            </button>

          </div>

          {deliveryError && (
            <div className="admin-error-message">
              {deliveryError}
            </div>
          )}

          {deliveryPersons.length === 0 ? (
            <div className="admin-empty">

              <h3>
                No delivery persons found
              </h3>

              <p>
                Create a user whose role is{" "}
                <strong>
                  delivery_person
                </strong>{" "}
                before assigning orders.
              </p>

            </div>
          ) : (
            <div className="delivery-person-grid">

              {deliveryPersons.map(
                (person) => (
                  <div
                    className="delivery-person-card"
                    key={person.id}
                  >

                    <div className="delivery-person-avatar">

                      {person.name
                        ?.charAt(0)
                        ?.toUpperCase() ||
                        "D"}

                    </div>

                    <div>

                      <h3>
                        {person.name}
                      </h3>

                      <p>
                        ID: {person.id}
                      </p>

                      <p>
                        📧{" "}
                        {person.email ||
                          "No email"}
                      </p>

                      <p>
                        📞{" "}
                        {person.phone ||
                          "No phone"}
                      </p>

                      <span
                        className={
                          person.is_active
                            ? "active-badge"
                            : "inactive-badge"
                        }
                      >
                        {person.is_active
                          ? "Active"
                          : "Inactive"}
                      </span>

                    </div>

                  </div>
                )
              )}

            </div>
          )}

        </section>
      )}

    </div>
  );
}

export default AdminPage;
