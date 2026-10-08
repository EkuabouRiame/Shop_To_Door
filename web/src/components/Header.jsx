import "./Header.css";

function Header({ user, cartCount = 0 }) {
  return (
    <header className="mobile-header">

      <div className="header-left">
        <div className="header-logo">
          🧳
        </div>

        <div>
          <h1>Shop To Door</h1>

          <p>
            Hello{user?.name ? `, ${user.name}` : ""} 👋
          </p>
        </div>
      </div>

      <button className="header-cart">
        🛒

        {cartCount > 0 && (
          <span className="header-cart-badge">
            {cartCount}
          </span>
        )}
      </button>

    </header>
  );
}

export default Header;
