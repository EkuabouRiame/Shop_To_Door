import { useEffect, useState } from "react";
import "./AddProduct.css";
import { getToken } from "../auth";

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL ||
  "https://shop-to-door-backend-294288480400.asia-south2.run.app/api";

function AddProduct() {
  const [categories, setCategories] = useState([]);

  const [form, setForm] = useState({
    name: "",
    sku: "",
    brand: "",
    category_id: "",
    description: "",
    price: "",
    discount_price: "",
    stock: "",
    is_active: true,
    is_featured: false,
  });

  const [image, setImage] = useState(null);
  const [preview, setPreview] = useState("");

  const [loading, setLoading] = useState(false);
  const [loadingCategories, setLoadingCategories] =
    useState(true);

  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  // =========================================================
  // LOAD CATEGORIES
  // =========================================================

  useEffect(() => {
    loadCategories();
  }, []);

  async function loadCategories() {
    try {
      setLoadingCategories(true);
      setError("");

      const response = await fetch(
        `${API_BASE_URL}/categories/`
      );

      const data = await response.json();

      if (!response.ok) {
        throw new Error(
          data?.message ||
            data?.msg ||
            "Unable to load categories."
        );
      }

      if (Array.isArray(data)) {
        setCategories(data);
      } else if (Array.isArray(data.categories)) {
        setCategories(data.categories);
      } else if (Array.isArray(data.data)) {
        setCategories(data.data);
      } else {
        setCategories([]);
      }
    } catch (err) {
      console.error(
        "Category loading error:",
        err
      );

      setError(
        err.message ||
          "Unable to load categories."
      );
    } finally {
      setLoadingCategories(false);
    }
  }

  // =========================================================
  // HANDLE INPUT
  // =========================================================

  function handleChange(event) {
    const {
      name,
      value,
      type,
      checked,
    } = event.target;

    setForm((previous) => ({
      ...previous,
      [name]:
        type === "checkbox"
          ? checked
          : value,
    }));
  }

  // =========================================================
  // HANDLE IMAGE
  // =========================================================

  function handleImageChange(event) {
    const selectedFile =
      event.target.files?.[0];

    setError("");
    setMessage("");

    if (!selectedFile) {
      setImage(null);
      setPreview("");
      return;
    }

    const allowedTypes = [
      "image/jpeg",
      "image/png",
      "image/webp",
    ];

    if (!allowedTypes.includes(selectedFile.type)) {
      setError(
        "Only JPG, JPEG, PNG and WEBP images are allowed."
      );

      event.target.value = "";
      setImage(null);
      setPreview("");

      return;
    }

    // Optional size restriction: 5 MB
    const maxSize =
      5 * 1024 * 1024;

    if (selectedFile.size > maxSize) {
      setError(
        "Image size must be less than 5 MB."
      );

      event.target.value = "";
      setImage(null);
      setPreview("");

      return;
    }

    setImage(selectedFile);

    const previewUrl =
      URL.createObjectURL(selectedFile);

    setPreview(previewUrl);
  }

  // =========================================================
  // REMOVE IMAGE
  // =========================================================

  function removeImage() {
    setImage(null);
    setPreview("");

    const fileInput =
      document.getElementById(
        "product-image"
      );

    if (fileInput) {
      fileInput.value = "";
    }
  }

  // =========================================================
  // RESET FORM
  // =========================================================

  function resetForm() {
    setForm({
      name: "",
      sku: "",
      brand: "",
      category_id: "",
      description: "",
      price: "",
      discount_price: "",
      stock: "",
      is_active: true,
      is_featured: false,
    });

    setImage(null);
    setPreview("");

    const fileInput =
      document.getElementById(
        "product-image"
      );

    if (fileInput) {
      fileInput.value = "";
    }
  }

  // =========================================================
  // SUBMIT PRODUCT
  // =========================================================

  async function handleSubmit(event) {
    event.preventDefault();

    setMessage("");
    setError("");

    const token = getToken();

    if (!token) {
      setError(
        "Please login before adding a product."
      );
      return;
    }

    // -------------------------------------------------------
    // VALIDATION
    // -------------------------------------------------------

    if (!form.name.trim()) {
      setError(
        "Product name is required."
      );
      return;
    }

    if (!form.category_id) {
      setError(
        "Please select a category."
      );
      return;
    }

    if (!form.price) {
      setError(
        "Product price is required."
      );
      return;
    }

    if (form.stock === "") {
      setError(
        "Product stock is required."
      );
      return;
    }

    try {
      setLoading(true);

      // =====================================================
      // STEP 1
      // CREATE PRODUCT
      // =====================================================

      const productData = {
        name: form.name.trim(),

        sku: form.sku.trim(),

        brand: form.brand.trim(),

        category_id: Number(
          form.category_id
        ),

        description:
          form.description.trim(),

        price: Number(form.price),

        discount_price:
          form.discount_price === ""
            ? null
            : Number(form.discount_price),

        stock: Number(form.stock),

        is_active:
          Boolean(form.is_active),

        is_featured:
          Boolean(form.is_featured),
      };

      console.log(
        "Creating product:",
        productData
      );

      const createResponse =
        await fetch(
          `${API_BASE_URL}/admin/products`,
          {
            method: "POST",

            headers: {
              "Content-Type":
                "application/json",

              Authorization:
                `Bearer ${token}`,
            },

            body: JSON.stringify(
              productData
            ),
          }
        );

      let createData;

      try {
        createData =
          await createResponse.json();
      } catch {
        throw new Error(
          `Server returned an invalid response. HTTP ${createResponse.status}`
        );
      }

      console.log(
        "Create product response:",
        createData
      );

      if (!createResponse.ok) {
        throw new Error(
          createData?.message ||
            createData?.msg ||
            "Unable to create product."
        );
      }

      const createdProduct =
        createData?.product;

      if (!createdProduct?.id) {
        throw new Error(
          "Product was created, but the server did not return a product ID."
        );
      }

      const productId =
        createdProduct.id;

      // =====================================================
      // STEP 2
      // UPLOAD PRODUCT IMAGE
      // =====================================================

      if (image) {
        console.log(
          "Uploading product image..."
        );

        const imageFormData =
          new FormData();

        imageFormData.append(
          "image",
          image
        );

        imageFormData.append(
          "alt_text",
          form.name.trim()
        );

        const uploadResponse =
          await fetch(
            `${API_BASE_URL}/admin/products/${productId}/images/upload`,
            {
              method: "POST",

              headers: {
                Authorization:
                  `Bearer ${token}`,
              },

              body: imageFormData,
            }
          );

        let uploadData;

        try {
          uploadData =
            await uploadResponse.json();
        } catch {
          throw new Error(
            `Image upload returned an invalid response. HTTP ${uploadResponse.status}`
          );
        }

        console.log(
          "Image upload response:",
          uploadData
        );

        if (!uploadResponse.ok) {
          throw new Error(
            uploadData?.message ||
              uploadData?.msg ||
              "Product was created, but image upload failed."
          );
        }
      }

      // =====================================================
      // SUCCESS
      // =====================================================

      setMessage(
        image
          ? "Product and image added successfully."
          : "Product added successfully."
      );

      resetForm();

    } catch (err) {
      console.error(
        "Add product error:",
        err
      );

      setError(
        err.message ||
          "Unable to add product."
      );
    } finally {
      setLoading(false);
    }
  }

  // =========================================================
  // RENDER
  // =========================================================

  return (
    <div className="add-product-page">

      {/* ===================================================
          HEADER
      =================================================== */}

      <div className="add-product-header">

        <div>
          <h1>
            Add Product
          </h1>

          <p>
            Add a new product to Shop To Door
          </p>
        </div>

        <button
          type="button"
          className="back-admin-button"
          onClick={() =>
            (window.location.href =
              "/admin")
          }
        >
          ← Back to Admin
        </button>

      </div>

      {/* ===================================================
          MESSAGES
      =================================================== */}

      {message && (
        <div className="success-message">
          {message}
        </div>
      )}

      {error && (
        <div className="error-message">
          {error}
        </div>
      )}

      {/* ===================================================
          FORM
      =================================================== */}

      <form
        className="add-product-form"
        onSubmit={handleSubmit}
      >

        {/* =================================================
            BASIC INFORMATION
        ================================================= */}

        <section className="form-section">

          <h2>
            Product Information
          </h2>

          <div className="form-grid">

            {/* PRODUCT NAME */}

            <div className="form-group">
              <label htmlFor="name">
                Product Name *
              </label>

              <input
                id="name"
                name="name"
                type="text"
                value={form.name}
                onChange={handleChange}
                placeholder="Enter product name"
                required
              />
            </div>

            {/* SKU */}

            <div className="form-group">
              <label htmlFor="sku">
                SKU
              </label>

              <input
                id="sku"
                name="sku"
                type="text"
                value={form.sku}
                onChange={handleChange}
                placeholder="Leave blank for automatic SKU"
              />
            </div>

            {/* BRAND */}

            <div className="form-group">
              <label htmlFor="brand">
                Brand
              </label>

              <input
                id="brand"
                name="brand"
                type="text"
                value={form.brand}
                onChange={handleChange}
                placeholder="Enter brand name"
              />
            </div>

            {/* CATEGORY */}

            <div className="form-group">
              <label htmlFor="category_id">
                Category *
              </label>

              <select
                id="category_id"
                name="category_id"
                value={form.category_id}
                onChange={handleChange}
                disabled={
                  loadingCategories
                }
                required
              >
                <option value="">
                  {loadingCategories
                    ? "Loading categories..."
                    : "Select category"}
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

          </div>

        </section>

        {/* =================================================
            DESCRIPTION
        ================================================= */}

        <section className="form-section">

          <h2>
            Description
          </h2>

          <div className="form-group">

            <label htmlFor="description">
              Product Description
            </label>

            <textarea
              id="description"
              name="description"
              value={form.description}
              onChange={handleChange}
              placeholder="Describe the product..."
              rows="6"
            />

          </div>

        </section>

        {/* =================================================
            PRICE & STOCK
        ================================================= */}

        <section className="form-section">

          <h2>
            Price & Stock
          </h2>

          <div className="form-grid">

            {/* PRICE */}

            <div className="form-group">

              <label htmlFor="price">
                Price *
              </label>

              <input
                id="price"
                name="price"
                type="number"
                min="0"
                step="0.01"
                value={form.price}
                onChange={handleChange}
                placeholder="0.00"
                required
              />

            </div>

            {/* DISCOUNT */}

            <div className="form-group">

              <label htmlFor="discount_price">
                Discount Price
              </label>

              <input
                id="discount_price"
                name="discount_price"
                type="number"
                min="0"
                step="0.01"
                value={
                  form.discount_price
                }
                onChange={handleChange}
                placeholder="0.00"
              />

            </div>

            {/* STOCK */}

            <div className="form-group">

              <label htmlFor="stock">
                Stock *
              </label>

              <input
                id="stock"
                name="stock"
                type="number"
                min="0"
                step="1"
                value={form.stock}
                onChange={handleChange}
                placeholder="0"
                required
              />

            </div>

          </div>

        </section>

        {/* =================================================
            PRODUCT IMAGE
        ================================================= */}

        <section className="form-section">

          <h2>
            Product Photo
          </h2>

          <div className="product-image-upload">

            <label
              htmlFor="product-image"
              className="image-upload-label"
            >
              <div className="upload-icon">
                📷
              </div>

              <strong>
                Choose Product Photo
              </strong>

              <span>
                JPG, JPEG, PNG or WEBP
                <br />
                Maximum size: 5 MB
              </span>
            </label>

            <input
              id="product-image"
              name="image"
              type="file"
              accept="image/jpeg,image/png,image/webp"
              onChange={
                handleImageChange
              }
            />

          </div>

          {/* =================================================
              IMAGE PREVIEW
          ================================================= */}

          {preview && (
            <div className="image-preview-container">

              <h3>
                Image Preview
              </h3>

              <div className="image-preview">

                <img
                  src={preview}
                  alt="Product preview"
                />

                <button
                  type="button"
                  className="remove-image-button"
                  onClick={removeImage}
                >
                  Remove Photo
                </button>

              </div>

            </div>
          )}

        </section>

        {/* =================================================
            STATUS
        ================================================= */}

        <section className="form-section">

          <h2>
            Product Settings
          </h2>

          <div className="checkbox-group">

            <label className="checkbox-label">

              <input
                type="checkbox"
                name="is_active"
                checked={
                  form.is_active
                }
                onChange={handleChange}
              />

              <span>
                Active Product
              </span>

            </label>

            <label className="checkbox-label">

              <input
                type="checkbox"
                name="is_featured"
                checked={
                  form.is_featured
                }
                onChange={handleChange}
              />

              <span>
                Featured Product
              </span>

            </label>

          </div>

        </section>

        {/* =================================================
            BUTTONS
        ================================================= */}

        <div className="form-actions">

          <button
            type="button"
            className="cancel-button"
            disabled={loading}
            onClick={resetForm}
          >
            Clear
          </button>

          <button
            type="submit"
            className="submit-product-button"
            disabled={loading}
          >
            {loading
              ? "Adding Product..."
              : "Add Product"}
          </button>

        </div>

      </form>

    </div>
  );
}

export default AddProduct;
