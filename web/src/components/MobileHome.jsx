import "./MobileHome.css";

function MobileHome({ user }) {
  return (
    <main className="mobile-home">

      {/* SEARCH */}

      <div className="search-box">
        <span>🔍</span>

        <input
          type="text"
          placeholder="Search products..."
        />
      </div>

      {/* BANNER */}

      <section className="offer-banner">

        <div>
          <span className="offer-small">
            SPECIAL OFFER
          </span>

          <h2>
            Shop smarter.
            <br />
            Save more.
          </h2>

          <button>
            Shop Now
          </button>
        </div>

        <div className="offer-image">
          🛍️
        </div>

      </section>

      {/* CATEGORIES */}

      <section className="home-section">

        <div className="section-heading">
          <h2>Categories</h2>

          <button>
            See all
          </button>
        </div>

        <div className="category-list">

          <button className="category-item">
            <span>📱</span>
            <small>Electronics</small>
          </button>

          <button className="category-item">
            <span>👕</span>
            <small>Fashion</small>
          </button>

          <button className="category-item">
            <span>👟</span>
            <small>Footwear</small>
          </button>

          <button className="category-item">
            <span>🏠</span>
            <small>Home</small>
          </button>

          <button className="category-item">
            <span>🥦</span>
            <small>Grocery</small>
          </button>

        </div>

      </section>

      {/* PRODUCTS */}

      <section className="home-section">

        <div className="section-heading">

          <h2>Popular Products</h2>

          <button>
            See all
          </button>

        </div>

        <div className="product-grid">

          <div className="product-card">

            <div className="product-image">
              📱
            </div>

            <h3>Smartphone</h3>

            <p>Latest smartphone</p>

            <strong>₹19,999</strong>

            <button className="add-cart">
              Add to Cart
            </button>

          </div>

          <div className="product-card">

            <div className="product-image">
              👟
            </div>

            <h3>Running Shoes</h3>

            <p>Comfortable shoes</p>

            <strong>₹2,499</strong>

            <button className="add-cart">
              Add to Cart
            </button>

          </div>

        </div>

      </section>

    </main>
  );
}

export default MobileHome;