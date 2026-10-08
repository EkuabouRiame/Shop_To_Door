import { useState } from "react";
import { getToken } from "./auth";

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL ||
  "http://127.0.0.1:5000/api";

function DeliveryAccountForm({ onCreated }) {
  const [form, setForm] = useState({
    name: "",
    email: "",
    phone: "",
    password: "",
    confirm_password: "",
  });

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  const handleChange = (event) => {
    const { name, value } = event.target;
    setForm((previous) => ({
      ...previous,
      [name]: value,
    }));
  };

  const handleSubmit = async (event) => {
    event.preventDefault();

    setError("");
    setSuccess("");

    if (form.password.length < 6) {
      setError("Password must contain at least 6 characters.");
      return;
    }

    if (form.password !== form.confirm_password) {
      setError("Passwords do not match.");
      return;
    }

    const token = getToken();

    if (!token) {
      setError("Your admin session has expired. Please log in again.");
      return;
    }

    setLoading(true);

    try {
      const response = await fetch(
        `${API_BASE_URL}/auth/admin/delivery-accounts`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify(form),
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
            `Request failed with status ${response.status}`
        );
      }

      setSuccess(
        data.message ||
          "Delivery account created successfully."
      );

      setForm({
        name: "",
        email: "",
        phone: "",
        password: "",
        confirm_password: "",
      });

      if (typeof onCreated === "function") {
        onCreated(data.user);
      }
    } catch (err) {
      console.error(err);
      setError(err.message || "Unable to create delivery account.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div
      style={{
        marginBottom: "28px",
        padding: "24px",
        border: "1px solid #dbe3ef",
        borderRadius: "16px",
        background: "#ffffff",
        boxShadow: "0 8px 24px rgba(15, 23, 42, 0.06)",
      }}
    >
      <div style={{ marginBottom: "18px" }}>
        <h3 style={{ margin: 0 }}>Create Delivery Account</h3>
        <p style={{ margin: "6px 0 0", color: "#64748b" }}>
          Create an active delivery-person account for assigning customer orders.
        </p>
      </div>

      {error && (
        <div
          style={{
            marginBottom: "14px",
            padding: "12px 14px",
            borderRadius: "10px",
            background: "#fee2e2",
            color: "#991b1b",
          }}
        >
          {error}
        </div>
      )}

      {success && (
        <div
          style={{
            marginBottom: "14px",
            padding: "12px 14px",
            borderRadius: "10px",
            background: "#dcfce7",
            color: "#166534",
          }}
        >
          {success}
        </div>
      )}

      <form onSubmit={handleSubmit}>
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))",
            gap: "14px",
          }}
        >
          <input
            type="text"
            name="name"
            placeholder="Full name"
            value={form.name}
            onChange={handleChange}
            required
            autoComplete="name"
            style={inputStyle}
          />

          <input
            type="email"
            name="email"
            placeholder="Email address"
            value={form.email}
            onChange={handleChange}
            required
            autoComplete="email"
            style={inputStyle}
          />

          <input
            type="tel"
            name="phone"
            placeholder="Phone number"
            value={form.phone}
            onChange={handleChange}
            autoComplete="tel"
            style={inputStyle}
          />

          <input
            type="password"
            name="password"
            placeholder="Password"
            value={form.password}
            onChange={handleChange}
            required
            minLength={6}
            autoComplete="new-password"
            style={inputStyle}
          />

          <input
            type="password"
            name="confirm_password"
            placeholder="Confirm password"
            value={form.confirm_password}
            onChange={handleChange}
            required
            minLength={6}
            autoComplete="new-password"
            style={inputStyle}
          />
        </div>

        <button
          type="submit"
          disabled={loading}
          style={{
            marginTop: "16px",
            padding: "12px 18px",
            border: "none",
            borderRadius: "10px",
            background: loading ? "#94a3b8" : "#2563eb",
            color: "#ffffff",
            fontWeight: 700,
            cursor: loading ? "not-allowed" : "pointer",
          }}
        >
          {loading ? "Creating..." : "Create Delivery Account"}
        </button>
      </form>
    </div>
  );
}

const inputStyle = {
  width: "100%",
  boxSizing: "border-box",
  padding: "12px 13px",
  border: "1px solid #cbd5e1",
  borderRadius: "10px",
  outline: "none",
  fontSize: "14px",
  background: "#ffffff",
};

export default DeliveryAccountForm;
