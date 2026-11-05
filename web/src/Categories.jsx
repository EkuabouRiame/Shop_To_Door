
import { useEffect, useMemo, useState } from "react";
import Products from "./Products";
import "./Home.css";

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL ||
  "https://shop-to-door-backend-294288480400.asia-south2.run.app/api";

const BACKEND_URL = API_BASE_URL.replace(/\/api\/?$/, "");

export default function Categories({ onProductClick }) {
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [selectedMain, setSelectedMain] = useState(null);
  const [selectedSubcategory, setSelectedSubcategory] = useState(null);

  useEffect(() => {
    async function loadCategories() {
      try {
        setLoading(true);
        setError("");

        const response = await fetch(`${API_BASE_URL}/categories/`, {
          headers: { Accept: "application/json" },
        });

        const data = await response.json();

        if (!response.ok) {
          throw new Error(
            data?.message || data?.msg || "Unable to load categories."
          );
        }

        const list = Array.isArray(data?.categories)
          ? data.categories
          : Array.isArray(data?.data)
            ? data.data
            : Array.isArray(data)
              ? data
              : [];

        setCategories(
          list.filter(
            (category) =>
              category?.is_active === undefined ||
              category?.is_active === true
          )
        );
      } catch (err) {
        console.error("Categories loading error:", err);
        setError(err.message || "Unable to load categories.");
      } finally {
        setLoading(false);
      }
    }

    loadCategories();
  }, []);

  function getImageUrl(image) {
    if (!image) return "";

    const value = String(image).trim();
    if (!value) return "";

    if (
      value.startsWith("http://") ||
      value.startsWith("https://") ||
      value.startsWith("data:")
    ) {
      return value;
    }

    if (value.startsWith("/")) {
      return `${BACKEND_URL}${value}`;
    }

    return `${BACKEND_URL}/uploads/categories/${value}`;
  }

  function getParentId(category) {
    const value = category?.parent_id;

    return value === null || value === undefined || value === ""
      ? null
      : String(value);
  }

  const mainCategories = useMemo(
    () =>
      categories.filter(
        (category) => getParentId(category) === null
      ),
    [categories]
  );

  const subcategories = useMemo(
    () =>
      selectedMain
        ? categories.filter(
            (category) =>
              getParentId(category) === String(selectedMain.id)
          )
        : [],
    [categories, selectedMain]
  );

  function selectMainCategory(category) {
    setSelectedMain(category);
    setSelectedSubcategory(null);
  }

  function selectSubcategory(category) {
    setSelectedSubcategory(category);
  }

  function goBack() {
    if (selectedSubcategory) {
      setSelectedSubcategory(null);
      return;
    }

    setSelectedMain(null);
  }

  if (loading) {
    return (
      <section className="category-section">
        <p>Loading categories...</p>
      </section>
    );
  }

  if (error) {
    return (
      <section className="category-section">
        <p>{error}</p>
      </section>
    );
  }

  return (
    <section className="category-section">
      <div className="section-heading">
        <div>
          <h2>
            {selectedSubcategory
              ? selectedSubcategory.name
              : selectedMain
                ? selectedMain.name
                : "Shop by Category"}
          </h2>

          <p>
            {selectedSubcategory
              ? `Products in ${selectedSubcategory.name}`
              : selectedMain
                ? "Choose a subcategory"
                : "Browse our product categories"}
          </p>
        </div>
      </div>

      {(selectedMain || selectedSubcategory) && (
        <button
          type="button"
          className="category-back-button"
          onClick={goBack}
        >
          ← Back
        </button>
      )}

      {!selectedMain && (
        <div className="category-grid">
          {mainCategories.map((category) => {
            const image = getImageUrl(category.image);

            return (
              <button
                type="button"
                className="category-card"
                key={category.id}
                onClick={() => selectMainCategory(category)}
              >
                <div className="category-image-wrapper">
                  {image ? (
                    <img
                      src={image}
                      alt={category.name}
                      onError={(event) => {
                        event.currentTarget.style.display = "none";
                      }}
                    />
                  ) : (
                    <div className="product-placeholder">
                      {category.name?.charAt(0) || "C"}
                    </div>
                  )}
                </div>

                <span>{category.name}</span>
              </button>
            );
          })}
        </div>
      )}

      {selectedMain && !selectedSubcategory && (
        <>
          {subcategories.length > 0 ? (
            <div className="category-grid">
              {subcategories.map((category) => {
                const image = getImageUrl(category.image);

                return (
                  <button
                    type="button"
                    className="category-card"
                    key={category.id}
                    onClick={() => selectSubcategory(category)}
                  >
                    <div className="category-image-wrapper">
                      {image ? (
                        <img
                          src={image}
                          alt={category.name}
                          onError={(event) => {
                            event.currentTarget.style.display = "none";
                          }}
                        />
                      ) : (
                        <div className="product-placeholder">
                          {category.name?.charAt(0) || "C"}
                        </div>
                      )}
                    </div>

                    <span>{category.name}</span>
                  </button>
                );
              })}
            </div>
          ) : (
            <p>No subcategories available in {selectedMain.name}.</p>
          )}
        </>
      )}

      {selectedSubcategory && (
        <Products
          selectedCategory={{
            categoryId: selectedSubcategory.id,
            categoryName: selectedSubcategory.name,
            categorySlug: selectedSubcategory.slug,
            subcategoryIds: [],
          }}
          onProductClick={onProductClick}
        />
      )}
    </section>
  );
}
