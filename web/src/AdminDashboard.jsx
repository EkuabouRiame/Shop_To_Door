import { useEffect, useState } from "react";

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL ||
  "https://shop-to-door-backend-294288480400.asia-south2.run.app/api";

const BACKEND_URL = API_BASE_URL.replace(/\/api\/?$/, "");

function AdminDashboard({ user, onBack }) {
  const [activeSection, setActiveSection] = useState("dashboard");

  // =========================================================
  // PRODUCT STATE
  // =========================================================
  const [showAddProduct, setShowAddProduct] = useState(false);

  const [product, setProduct] = useState({
    name: "",
    sku: "",
    description: "",
    price: "",
    stock: "",
    category: "",
  });

  const [image, setImage] = useState(null);
  const [imagePreview, setImagePreview] = useState("");

  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState("");
  const [messageType, setMessageType] = useState("");

  // =========================================================
  // CATEGORY STATE
  // =========================================================
  const [categories, setCategories] = useState([]);

  const [categoryForm, setCategoryForm] = useState({
    name: "",
    description: "",
    is_active: true,
  });

  const [categoryImage, setCategoryImage] = useState(null);
  const [categoryImagePreview, setCategoryImagePreview] = useState("");

  const [categoryLoading, setCategoryLoading] = useState(false);
  const [categoryMessage, setCategoryMessage] = useState("");
  const [categoryMessageType, setCategoryMessageType] = useState("");

  const [editingCategory, setEditingCategory] = useState(null);

  const token = localStorage.getItem("token");

  // =========================================================
  // FETCH CATEGORIES
  // =========================================================
  const fetchCategories = async () => {
    try {
      setCategoryLoading(true);

      const response = await fetch(`${API_BASE_URL}/categories/`);
      const data = await response.json();

      if (!response.ok) {
        throw new Error(
          data.message || "Failed to load categories."
        );
      }

      setCategories(data.categories || []);
    } catch (error) {
      console.error("CATEGORY FETCH ERROR:", error);

      setCategoryMessage(
        error.message || "Failed to load categories."
      );
      setCategoryMessageType("error");
    } finally {
      setCategoryLoading(false);
    }
  };

  useEffect(() => {
    fetchCategories();
  }, []);

  // =========================================================
  // PRODUCT INPUT HANDLER
  // =========================================================
  const handleProductChange = (e) => {
    const { name, value } = e.target;

    setProduct((prev) => ({
      ...prev,
      [name]: value,
    }));
  };

  // =========================================================
  // PRODUCT IMAGE
  // =========================================================
  const handleProductImageChange = (e) => {
    const file = e.target.files?.[0];

    if (!file) {
      setImage(null);
      setImagePreview("");
      return;
    }

    setImage(file);
    setImagePreview(URL.createObjectURL(file));
  };

  // =========================================================
  // RESET PRODUCT FORM
  // =========================================================
  const resetProductForm = () => {
    setProduct({
      name: "",
      sku: "",
      description: "",
      price: "",
      stock: "",
      category: "",
    });

    setImage(null);
    setImagePreview("");
    setMessage("");
    setMessageType("");
  };

  // =========================================================
  // ADD PRODUCT
  // =========================================================
  const handleAddProduct = async (e) => {
    e.preventDefault();

    setLoading(true);
    setMessage("");
    setMessageType("");

    try {
      if (!image) {
        throw new Error("Please select a product image.");
      }

      if (!product.category) {
        throw new Error("Please select a category.");
      }

      const formData = new FormData();

      formData.append("name", product.name);
      formData.append("sku", product.sku);
      formData.append("description", product.description);
      formData.append("price", product.price);
      formData.append("stock", product.stock);
      formData.append("category_id", product.category);
      formData.append("image", image);

      const response = await fetch(
        `${API_BASE_URL}/admin/products`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${token}`,
          },
          body: formData,
        }
      );

      const data = await response.json();

      if (!response.ok) {
        throw new Error(
          data.message || "Failed to create product."
        );
      }

      setMessage(
        data.message || "Product created successfully."
      );
      setMessageType("success");

      resetProductForm();

      setTimeout(() => {
        setShowAddProduct(false);
      }, 1200);
    } catch (error) {
      console.error("ADD PRODUCT ERROR:", error);

      setMessage(
        error.message || "Failed to create product."
      );
      setMessageType("error");
    } finally {
      setLoading(false);
    }
  };

  // =========================================================
  // CATEGORY INPUT HANDLER
  // =========================================================
  const handleCategoryChange = (e) => {
    const { name, value, type, checked } = e.target;

    setCategoryForm((prev) => ({
      ...prev,
      [name]: type === "checkbox" ? checked : value,
    }));
  };

  // =========================================================
  // CATEGORY IMAGE
  // =========================================================
  const handleCategoryImageChange = (e) => {
    const file = e.target.files?.[0];

    if (!file) {
      setCategoryImage(null);
      setCategoryImagePreview("");
      return;
    }

    setCategoryImage(file);
    setCategoryImagePreview(URL.createObjectURL(file));
  };

  // =========================================================
  // RESET CATEGORY FORM
  // =========================================================
  const resetCategoryForm = () => {
    setCategoryForm({
      name: "",
      description: "",
      is_active: true,
    });

    setCategoryImage(null);
    setCategoryImagePreview("");
    setEditingCategory(null);
    setCategoryMessage("");
    setCategoryMessageType("");
  };

  // =========================================================
  // CREATE CATEGORY
  // =========================================================
  const handleCreateCategory = async (e) => {
    e.preventDefault();

    setCategoryLoading(true);
    setCategoryMessage("");
    setCategoryMessageType("");

    try {
      if (!categoryForm.name.trim()) {
        throw new Error("Category name is required.");
      }

      const formData = new FormData();

      formData.append("name", categoryForm.name.trim());
      formData.append(
        "description",
        categoryForm.description.trim()
      );
      formData.append(
        "is_active",
        categoryForm.is_active ? "true" : "false"
      );

      if (categoryImage) {
        formData.append("image", categoryImage);
      }

      const response = await fetch(
        `${API_BASE_URL}/admin/categories`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${token}`,
          },
          body: formData,
        }
      );

      const data = await response.json();

      if (!response.ok) {
        throw new Error(
          data.message || "Failed to create category."
        );
      }

      setCategoryMessage(
        data.message || "Category created successfully."
      );
      setCategoryMessageType("success");

      resetCategoryForm();
      await fetchCategories();
    } catch (error) {
      console.error("CREATE CATEGORY ERROR:", error);

      setCategoryMessage(
        error.message || "Failed to create category."
      );
      setCategoryMessageType("error");
    } finally {
      setCategoryLoading(false);
    }
  };

  // =========================================================
  // START EDIT CATEGORY
  // =========================================================
  const handleEditCategory = (category) => {
    setEditingCategory(category);

    setCategoryForm({
      name: category.name || "",
      description: category.description || "",
      is_active: category.is_active !== false,
    });

    setCategoryImage(null);

    if (category.image) {
      setCategoryImagePreview(category.image);
    } else {
      setCategoryImagePreview("");
    }

    setCategoryMessage("");
    setCategoryMessageType("");

    window.scrollTo({
      top: 0,
      behavior: "smooth",
    });
  };

  // =========================================================
  // UPDATE CATEGORY
  // =========================================================
  const handleUpdateCategory = async (e) => {
    e.preventDefault();

    if (!editingCategory) {
      return;
    }

    setCategoryLoading(true);
    setCategoryMessage("");
    setCategoryMessageType("");

    try {
      if (!categoryForm.name.trim()) {
        throw new Error("Category name is required.");
      }

      const formData = new FormData();

      formData.append("name", categoryForm.name.trim());
      formData.append(
        "description",
        categoryForm.description.trim()
      );
      formData.append(
        "is_active",
        categoryForm.is_active ? "true" : "false"
      );

      if (categoryImage) {
        formData.append("image", categoryImage);
      }

      const response = await fetch(
        `${API_BASE_URL}/admin/categories/${editingCategory.id}`,
        {
          method: "PUT",
          headers: {
            Authorization: `Bearer ${token}`,
          },
          body: formData,
        }
      );

      const data = await response.json();

      if (!response.ok) {
        throw new Error(
          data.message || "Failed to update category."
        );
      }

      setCategoryMessage(
        data.message || "Category updated successfully."
      );
      setCategoryMessageType("success");

      resetCategoryForm();
      await fetchCategories();
    } catch (error) {
      console.error("UPDATE CATEGORY ERROR:", error);

      setCategoryMessage(
        error.message || "Failed to update category."
      );
      setCategoryMessageType("error");
    } finally {
      setCategoryLoading(false);
    }
  };

  // =========================================================
  // DELETE CATEGORY
  // =========================================================
  const handleDeleteCategory = async (category) => {
    const confirmed = window.confirm(
      `Are you sure you want to delete "${category.name}"?`
    );

    if (!confirmed) {
      return;
    }

    setCategoryLoading(true);
    setCategoryMessage("");
    setCategoryMessageType("");

    try {
      const response = await fetch(
        `${API_BASE_URL}/admin/categories/${category.id}`,
        {
          method: "DELETE",
          headers: {
            Authorization: `Bearer ${token}`,
          },
        }
      );

      const data = await response.json();

      if (!response.ok) {
        throw new Error(
          data.message || "Failed to delete category."
        );
      }

      setCategoryMessage(
        data.message || "Category deleted successfully."
      );
      setCategoryMessageType("success");

      await fetchCategories();
    } catch (error) {
      console.error("DELETE CATEGORY ERROR:", error);

      setCategoryMessage(
        error.message || "Failed to delete category."
      );
      setCategoryMessageType("error");
    } finally {
      setCategoryLoading(false);
    }
  };

  // =========================================================
  // IMAGE URL HELPER
  // =========================================================
  const getImageUrl = (imagePath) => {
    if (!imagePath) {
      return "";
    }

    if (
      imagePath.startsWith("http://") ||
      imagePath.startsWith("https://")
    ) {
      return imagePath;
    }

    if (imagePath.startsWith("/")) {
      return `${BACKEND_URL}${imagePath}`;
    }

    return `${BACKEND_URL}/${imagePath}`;
  };

  // =========================================================
  // RENDER
  // =========================================================
  return (
    <div className="admin-dashboard">
      {/* =====================================================
          HEADER
      ===================================================== */}
      <div className="admin-header">
        <div>
          <h1>Admin Dashboard</h1>

          <p>
            Welcome,{" "}
            <strong>
              {user?.name || "Administrator"}
            </strong>
          </p>
        </div>

        {onBack && (
          <button
            type="button"
            className="admin-back-button"
            onClick={onBack}
          >
            ← Back
          </button>
        )}
      </div>

      {/* =====================================================
          NAVIGATION
      ===================================================== */}
      <div className="admin-navigation">
        <button
          type="button"
          className={
            activeSection === "dashboard"
              ? "active"
              : ""
          }
          onClick={() => {
            setActiveSection("dashboard");
            setShowAddProduct(false);
          }}
        >
          Dashboard
        </button>

        <button
          type="button"
          className={
            activeSection === "products"
              ? "active"
              : ""
          }
          onClick={() => {
            setActiveSection("products");
            setShowAddProduct(false);
          }}
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
          onClick={() => {
            setActiveSection("categories");
            setShowAddProduct(false);
          }}
        >
          Categories
        </button>
      </div>

      {/* =====================================================
          DASHBOARD
      ===================================================== */}
      {activeSection === "dashboard" && (
        <div className="admin-content">
          <div className="admin-cards">
            <button
              type="button"
              className="admin-card"
              onClick={() => {
                setActiveSection("products");
                setShowAddProduct(true);
              }}
            >
              <h3>Add Product</h3>
              <p>Create a new product.</p>
            </button>

            <button
              type="button"
              className="admin-card"
              onClick={() =>
                setActiveSection("products")
              }
            >
              <h3>Products</h3>
              <p>Manage your products.</p>
            </button>

            <button
              type="button"
              className="admin-card"
              onClick={() =>
                setActiveSection("categories")
              }
            >
              <h3>Categories</h3>
              <p>
                Create and manage product categories.
              </p>
            </button>

            <div className="admin-card">
              <h3>Orders</h3>
              <p>Order management coming soon.</p>
            </div>

            <div className="admin-card">
              <h3>Customers</h3>
              <p>Customer management coming soon.</p>
            </div>
          </div>
        </div>
      )}

      {/* =====================================================
          PRODUCTS
      ===================================================== */}
      {activeSection === "products" && (
        <div className="admin-content">
          <div className="admin-section-header">
            <div>
              <h2>Products</h2>
              <p>Manage your store products.</p>
            </div>

            <button
              type="button"
              className="admin-primary-button"
              onClick={() => {
                resetProductForm();
                setShowAddProduct(true);
              }}
            >
              + Add Product
            </button>
          </div>

          {showAddProduct && (
            <div className="admin-form-card">
              <h2>Add Product</h2>

              {message && (
                <div
                  className={`admin-message ${messageType}`}
                >
                  {message}
                </div>
              )}

              <form onSubmit={handleAddProduct}>
                <div className="form-group">
                  <label htmlFor="product-name">
                    Product Name
                  </label>

                  <input
                    id="product-name"
                    type="text"
                    name="name"
                    value={product.name}
                    onChange={handleProductChange}
                    required
                  />
                </div>

                <div className="form-group">
                  <label htmlFor="product-sku">
                    SKU
                  </label>

                  <input
                    id="product-sku"
                    type="text"
                    name="sku"
                    value={product.sku}
                    onChange={handleProductChange}
                    required
                  />
                </div>

                <div className="form-group">
                  <label htmlFor="product-description">
                    Description
                  </label>

                  <textarea
                    id="product-description"
                    name="description"
                    value={product.description}
                    onChange={handleProductChange}
                    rows="4"
                  />
                </div>

                <div className="form-row">
                  <div className="form-group">
                    <label htmlFor="product-price">
                      Price
                    </label>

                    <input
                      id="product-price"
                      type="number"
                      name="price"
                      value={product.price}
                      onChange={handleProductChange}
                      min="0"
                      step="0.01"
                      required
                    />
                  </div>

                  <div className="form-group">
                    <label htmlFor="product-stock">
                      Stock
                    </label>

                    <input
                      id="product-stock"
                      type="number"
                      name="stock"
                      value={product.stock}
                      onChange={handleProductChange}
                      min="0"
                      required
                    />
                  </div>
                </div>

                {/* CATEGORY DROPDOWN */}
                <div className="form-group">
                  <label htmlFor="product-category">
                    Category
                  </label>

                  <select
                    id="product-category"
                    name="category"
                    value={product.category}
                    onChange={handleProductChange}
                    required
                  >
                    <option value="">
                      Select a category
                    </option>

                    {categories.map((category) => (
                      <option
                        key={category.id}
                        value={category.id}
                      >
                        {category.name}
                      </option>
                    ))}
                  </select>
                </div>

                {/* PRODUCT IMAGE */}
                <div className="form-group">
                  <label htmlFor="product-image">
                    Select Product Image
                  </label>

                  <input
                    id="product-image"
                    type="file"
                    accept="image/*"
                    onChange={handleProductImageChange}
                    required
                  />
                </div>

                {imagePreview && (
                  <div className="image-preview">
                    <img
                      src={imagePreview}
                      alt="Product preview"
                    />
                  </div>
                )}

                <div className="form-actions">
                  <button
                    type="submit"
                    className="admin-primary-button"
                    disabled={loading}
                  >
                    {loading
                      ? "Creating..."
                      : "Create Product"}
                  </button>

                  <button
                    type="button"
                    className="admin-secondary-button"
                    onClick={() => {
                      resetProductForm();
                      setShowAddProduct(false);
                    }}
                  >
                    Cancel
                  </button>
                </div>
              </form>
            </div>
          )}
        </div>
      )}

      {/* =====================================================
          CATEGORIES
      ===================================================== */}
      {activeSection === "categories" && (
        <div className="admin-content">
          <div className="admin-section-header">
            <div>
              <h2>Categories</h2>
              <p>
                Create and manage your product categories.
              </p>
            </div>
          </div>

          {/* CATEGORY FORM */}
          <div className="admin-form-card">
            <h2>
              {editingCategory
                ? "Edit Category"
                : "Create Category"}
            </h2>

            {categoryMessage && (
              <div
                className={`admin-message ${categoryMessageType}`}
              >
                {categoryMessage}
              </div>
            )}

            <form
              onSubmit={
                editingCategory
                  ? handleUpdateCategory
                  : handleCreateCategory
              }
            >
              <div className="form-group">
                <label htmlFor="category-name">
                  Category Name
                </label>

                <input
                  id="category-name"
                  type="text"
                  name="name"
                  value={categoryForm.name}
                  onChange={handleCategoryChange}
                  placeholder="e.g. Electronics"
                  required
                />
              </div>

              <div className="form-group">
                <label htmlFor="category-description">
                  Description
                </label>

                <textarea
                  id="category-description"
                  name="description"
                  value={categoryForm.description}
                  onChange={handleCategoryChange}
                  placeholder="Category description"
                  rows="4"
                />
              </div>

              <div className="form-group">
                <label htmlFor="category-image">
                  Select a category image
                </label>

                <input
                  id="category-image"
                  type="file"
                  accept="image/*"
                  onChange={handleCategoryImageChange}
                />
              </div>

              {/* CATEGORY IMAGE PREVIEW */}
              {categoryImagePreview && (
                <div className="category-image-preview">
                  <img
                    src={
                      categoryImage
                        ? categoryImagePreview
                        : getImageUrl(
                            categoryImagePreview
                          )
                    }
                    alt="Category preview"
                  />
                </div>
              )}

              <div className="form-group checkbox-group">
                <label>
                  <input
                    type="checkbox"
                    name="is_active"
                    checked={categoryForm.is_active}
                    onChange={handleCategoryChange}
                  />

                  <span>Active category</span>
                </label>
              </div>

              <div className="form-actions">
                <button
                  type="submit"
                  className="admin-primary-button"
                  disabled={categoryLoading}
                >
                  {categoryLoading
                    ? editingCategory
                      ? "Updating..."
                      : "Creating..."
                    : editingCategory
                    ? "Update Category"
                    : "Create Category"}
                </button>

                {editingCategory && (
                  <button
                    type="button"
                    className="admin-secondary-button"
                    onClick={resetCategoryForm}
                  >
                    Cancel Edit
                  </button>
                )}
              </div>
            </form>
          </div>

          {/* CATEGORY LIST */}
          <div className="admin-table-card">
            <div className="admin-table-header">
              <h2>Category List</h2>

              <button
                type="button"
                className="admin-secondary-button"
                onClick={fetchCategories}
                disabled={categoryLoading}
              >
                Refresh
              </button>
            </div>

            {categoryLoading && categories.length === 0 ? (
              <p>Loading categories...</p>
            ) : categories.length === 0 ? (
              <p>No categories found.</p>
            ) : (
              <div className="admin-table-wrapper">
                <table className="admin-table">
                  <thead>
                    <tr>
                      <th>ID</th>
                      <th>Image</th>
                      <th>Name</th>
                      <th>Description</th>
                      <th>Status</th>
                      <th>Actions</th>
                    </tr>
                  </thead>

                  <tbody>
                    {categories.map((category) => (
                      <tr key={category.id}>
                        <td>{category.id}</td>

                        <td>
                          {category.image ? (
                            <img
                              src={getImageUrl(
                                category.image
                              )}
                              alt={category.name}
                              className="category-table-image"
                            />
                          ) : (
                            <span>No image</span>
                          )}
                        </td>

                        <td>
                          <strong>
                            {category.name}
                          </strong>
                        </td>

                        <td>
                          {category.description ||
                            "—"}
                        </td>

                        <td>
                          <span
                            className={
                              category.is_active
                                ? "status-active"
                                : "status-inactive"
                            }
                          >
                            {category.is_active
                              ? "Active"
                              : "Inactive"}
                          </span>
                        </td>

                        <td>
                          <div className="table-actions">
                            <button
                              type="button"
                              className="edit-button"
                              onClick={() =>
                                handleEditCategory(
                                  category
                                )
                              }
                            >
                              Edit
                            </button>

                            <button
                              type="button"
                              className="delete-button"
                              onClick={() =>
                                handleDeleteCategory(
                                  category
                                )
                              }
                            >
                              Delete
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

export default AdminDashboard;
