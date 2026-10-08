import { useEffect, useState } from "react";
import "./AdminDashboard.css";
import { getToken } from "../auth";

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL ||
  "http://127.0.0.1:5000/api";

function AdminDashboard() {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  useEffect(() => {
    loadProducts();
  }, []);

  async function loadProducts() {
    try {
      setLoading(true);
      setError("");

      const response = await fetch(
        `${API_BASE_URL}/products/`
      );

      const data = await response.json();

      if (!response.ok) {
        throw new Error(
          data?.message ||
            data?.msg ||
            "Unable to load products."
        );
      }

      if (Array.isArray(data)) {
        setProducts(data);
      } else if (Array.isArray(data.products)) {
        setProducts(data.products);
      } else {
        setProducts([]);
      }
    } catch (err) {
      console.error(err);
      setError(
        err.message ||
          "Unable to load products."
      );
    } finally {
      setLoading(false);
    }
  }

  async function deleteProduct(productId) {
    const token = getToken();

    if (!token) {
      setMessage("Please login first.");
      return;
    }

    const confirmed = window.confirm(
      "Are you sure you want to delete this product?"
    );

    if (!confirmed) {
      return;
    }

    try {
      setMessage("");

      const response = await fetch(
        `${API_BASE_URL}/products/${productId}`,
        {
          method: "DELETE",
          headers: {
            Accept: "application/json",
            Authorization: `Bearer ${token}`,
          },
        }
      );

      const data = await response.json();

      if (!response.ok) {
        throw new Error(
          data?.message ||
            data?.msg ||
            "Unable to delete product."
        );
      }

      setMessage(
        "Product deleted successfully."
      );

      loadProducts();
    } catch (err) {
      console.error(err);

      setMessage(
        err.message ||
          "Unable to delete product."
      );
    }
  }

  return (
    <div className="admin-dashboard">

      {/* HEADER */}

      <div className="admin-header">

        <div>
          <h1>Admin Dashboard</h1>

          <p>
            Manage Shop To Door products
          </p>
        </div>

        <button
          className="admin-refresh-button"
          onClick={loadProducts}
          disabled={loading}
        >
          {loading
            ? "Loading..."
            : "↻ Refresh"}
        </button>

      </div>


      {/* MESSAGE */}

      {message && (
        <div className="admin-message">
          {message}
        </div>
      )}


      {/* ERROR */}

      {error && (
        <div className="admin-error">
          {error}
        </div>
      )}


      {/* ACTIONS */}

      <div className="admin-actions">

        <button
          className="admin-add-button"
          onClick={() => {
            window.location.href =
              "/admin/products/add";
          }}
        >
          + Add Product
        </button>

      </div>


      {/* STATISTICS */}

      <div className="admin-stats">

        <div className="admin-stat-card">

          <span>
            Total Products
          </span>

          <strong>
            {products.length}
          </strong>

        </div>

        <div className="admin-stat-card">

          <span>
            Active Products
          </span>

          <strong>
            {
              products.filter(
                (product) =>
                  product.is_active !== false
              ).length
            }
          </strong>

        </div>

        <div className="admin-stat-card">

          <span>
            Out of Stock
          </span>

          <strong>
            {
              products.filter(
                (product) =>
                  Number(product.stock) === 0
              ).length
            }
          </strong>

        </div>

      </div>


      {/* PRODUCTS */}

      <div className="admin-products">

        <div className="admin-products-header">

          <h2>
            Products
          </h2>

          <span>
            {products.length} products
          </span>

        </div>


        {loading ? (

          <div className="admin-loading">
            Loading products...
          </div>

        ) : products.length === 0 ? (

          <div className="admin-empty">

            <div className="admin-empty-icon">
              🛍️
            </div>

            <h3>
              No Products
            </h3>

            <p>
              Add your first product
              to Shop To Door.
            </p>

            <button
              className="admin-add-button"
              onClick={() =>
                (window.location.href =
                  "/admin/products/add")
              }
            >
              + Add Product
            </button>

          </div>

        ) : (

          <div className="admin-table-wrapper">

            <table className="admin-table">

              <thead>

                <tr>

                  <th>
                    Product
                  </th>

                  <th>
                    Category
                  </th>

                  <th>
                    Price
                  </th>

                  <th>
                    Stock
                  </th>

                  <th>
                    Status
                  </th>

                  <th>
                    Actions
                  </th>

                </tr>

              </thead>


              <tbody>

                {products.map(
                  (product) => (

                    <tr
                      key={product.id}
                    >

                      <td>

                        <div className="admin-product-name">

                          <strong>
                            {product.name}
                          </strong>

                          <small>
                            SKU:{" "}
                            {product.sku ||
                              "N/A"}
                          </small>

                        </div>

                      </td>


                      <td>

                        {typeof product.category ===
                        "object"
                          ? product.category?.name
                          : product.category ||
                            "N/A"}

                      </td>


                      <td>

                        ₹
                        {Number(
                          product.discount_price ??
                            product.price ??
                            0
                        ).toLocaleString(
                          "en-IN"
                        )}

                      </td>


                      <td>

                        {product.stock ?? 0}

                      </td>


                      <td>

                        <span
                          className={
                            product.is_active !==
                            false
                              ? "status-active"
                              : "status-inactive"
                          }
                        >
                          {product.is_active !==
                          false
                            ? "Active"
                            : "Inactive"}
                        </span>

                      </td>


                      <td>

                        <div className="admin-actions-cell">

                          <button
                            className="admin-edit-button"
                            onClick={() =>
                              (window.location.href =
                                `/admin/products/edit/${product.id}`)
                            }
                          >
                            Edit
                          </button>

                          <button
                            className="admin-delete-button"
                            onClick={() =>
                              deleteProduct(
                                product.id
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

          </div>

        )}

      </div>

    </div>
  );
}

export default AdminDashboard;