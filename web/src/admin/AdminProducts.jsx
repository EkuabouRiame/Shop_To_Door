import { useState } from "react";

function AdminProducts() {
  const [message, setMessage] = useState("");

  return (
    <div style={{ padding: "30px" }}>
      <h1>Admin Products</h1>

      <p>
        This is the Shop To Door administrator page.
      </p>

      <button
        type="button"
        onClick={() => setMessage("Admin page is working!")}
      >
        Test Admin Page
      </button>

      {message && (
        <p style={{ marginTop: "20px" }}>
          {message}
        </p>
      )}
    </div>
  );
}

export default AdminProducts;
