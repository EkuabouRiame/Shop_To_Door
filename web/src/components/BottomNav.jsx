import "./BottomNav.css";

function BottomNav({ activePage, setActivePage, cartCount = 0 }) {
  const items = [
    { id: "home", icon: "🏠", label: "Home" },
    { id: "shop", icon: "🛍️", label: "Shop" },
    { id: "cart", icon: "🛒", label: "Cart" },
    { id: "orders", icon: "📦", label: "Orders" },
    { id: "profile", icon: "👤", label: "Profile" },
  ];

  return (
    <nav className="bottom-nav">
      {items.map((item) => (
        <button
          key={item.id}
          className={`bottom-nav-item ${
            activePage === item.id ? "active" : ""
          }`}
          onClick={() => setActivePage(item.id)}
        >
          <span className="bottom-nav-icon">
            {item.icon}

            {item.id === "cart" && cartCount > 0 && (
              <span className="cart-badge">
                {cartCount}
              </span>
            )}
          </span>

          <span className="bottom-nav-label">
            {item.label}
          </span>
        </button>
      ))}
    </nav>
  );
}

export default BottomNav;
