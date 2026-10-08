import { useState } from "react";
import logo from "./assets/shop-to-door-logo.png";

import {
  saveAuth,
} from "./auth";

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL ||
  "http://127.0.0.1:5000/api";

function Register({
  onRegister,
  onSwitchToLogin,
}) {
  const [form, setForm] = useState({
    name: "",
    email: "",
    phone: "",
    password: "",
    confirmPassword: "",
  });

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  // =========================================================
  // FORM CHANGE
  // =========================================================

  function handleChange(event) {
    const {
      name,
      value,
    } = event.target;

    setForm((previous) => ({
      ...previous,
      [name]: value,
    }));

    setError("");
    setSuccess("");
  }

  // =========================================================
  // REGISTER
  // =========================================================

  async function handleSubmit(event) {
    event.preventDefault();

    setError("");
    setSuccess("");

    const name = form.name.trim();
    const email = form.email.trim();
    const phone = form.phone.trim();

    if (!name) {
      setError(
        "Please enter your name."
      );
      return;
    }

    if (!email) {
      setError(
        "Please enter your email."
      );
      return;
    }

    if (!form.password) {
      setError(
        "Please enter a password."
      );
      return;
    }

    if (form.password.length < 6) {
      setError(
        "Password must contain at least 6 characters."
      );
      return;
    }

    if (
      form.password !==
      form.confirmPassword
    ) {
      setError(
        "Passwords do not match."
      );
      return;
    }

    try {
      setLoading(true);

      const response = await fetch(
        `${API_BASE_URL}/auth/register`,
        {
          method: "POST",

          headers: {
            "Content-Type":
              "application/json",

            Accept:
              "application/json",
          },

          body: JSON.stringify({
            name,
            email,
            phone,
            password:
              form.password,
          }),
        }
      );

      let data;

      try {
        data =
          await response.json();
      } catch {
        throw new Error(
          `Invalid server response. HTTP ${response.status}`
        );
      }

      console.log(
        "Register response:",
        data
      );

      if (!response.ok) {
        throw new Error(
          data?.message ||
            data?.msg ||
            `Registration failed. HTTP ${response.status}`
        );
      }

      if (
        data?.status !==
          "success"
      ) {
        throw new Error(
          data?.message ||
            "Registration failed."
        );
      }

      /*
       * CASE 1:
       *
       * Backend registers the user
       * and logs the user in immediately.
       *
       * Expected:
       *
       * {
       *   status: "success",
       *   access_token: "...",
       *   user: {...}
       * }
       */

      if (
        data?.access_token &&
        data?.user
      ) {
        saveAuth(
          data.access_token,
          data.user
        );

        console.log(
          "Registration authentication saved."
        );

        if (onRegister) {
          onRegister(data.user);
        }

        return;
      }

      /*
       * CASE 2:
       *
       * Backend creates the account
       * but does not automatically login.
       */

      setSuccess(
        "Account created successfully. Please login."
      );

      setForm({
        name: "",
        email: "",
        phone: "",
        password: "",
        confirmPassword: "",
      });

      setTimeout(() => {
        if (onSwitchToLogin) {
          onSwitchToLogin();
        }
      }, 1200);

    } catch (error) {
      console.error(
        "Registration error:",
        error
      );

      setError(
        error?.message ||
          "Unable to create account. Please try again."
      );
    } finally {
      setLoading(false);
    }
  }

  // =========================================================
  // UI
  // =========================================================

  return (
    <div
      style={{
        minHeight: "100vh",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        padding: "30px 20px",
        background:
          "linear-gradient(135deg, #f5f7fb 0%, #eef4ff 100%)",
        fontFamily:
          "Arial, sans-serif",
      }}
    >
      {/* REGISTER CARD */}

      <div
        style={{
          width: "100%",
          maxWidth: "450px",
          background: "#ffffff",
          borderRadius: "18px",
          padding: "35px 30px",
          boxShadow:
            "0 10px 35px rgba(0,0,0,0.10)",
        }}
      >
        {/* LOGO */}

        <div
          style={{
            textAlign: "center",
            marginBottom: "20px",
          }}
        >
          <img
            src={logo}
            alt="Shop To Door Logo"
            style={{
              width: "190px",
              maxWidth: "80%",
              height: "auto",
              display: "block",
              margin: "0 auto",
              objectFit: "contain",
            }}
          />
        </div>

        {/* TITLE */}

        <div
          style={{
            textAlign: "center",
            marginBottom: "25px",
          }}
        >
          <h1
            style={{
              margin: "0 0 8px",
              fontSize: "28px",
              color: "#111827",
            }}
          >
            Create Account
          </h1>

          <p
            style={{
              margin: 0,
              color: "#6b7280",
              fontSize: "14px",
            }}
          >
            Create your Shop To Door account
          </p>
        </div>

        {/* ERROR */}

        {error && (
          <div
            style={{
              background: "#fef2f2",
              border:
                "1px solid #fecaca",
              color: "#b91c1c",
              padding: "12px 14px",
              borderRadius: "8px",
              marginBottom: "18px",
              fontSize: "14px",
            }}
          >
            {error}
          </div>
        )}

        {/* SUCCESS */}

        {success && (
          <div
            style={{
              background: "#f0fdf4",
              border:
                "1px solid #bbf7d0",
              color: "#15803d",
              padding: "12px 14px",
              borderRadius: "8px",
              marginBottom: "18px",
              fontSize: "14px",
            }}
          >
            {success}
          </div>
        )}

        {/* FORM */}

        <form
          onSubmit={handleSubmit}
        >
          {/* NAME */}

          <div
            style={{
              marginBottom: "16px",
            }}
          >
            <label
              style={{
                display: "block",
                marginBottom: "7px",
                fontWeight: "600",
                color: "#374151",
                fontSize: "14px",
              }}
            >
              Full Name
            </label>

            <input
              type="text"
              name="name"
              value={form.name}
              onChange={handleChange}
              placeholder="Enter your name"
              autoComplete="name"
              disabled={loading}
              style={{
                width: "100%",
                boxSizing: "border-box",
                padding: "12px 14px",
                border:
                  "1px solid #d1d5db",
                borderRadius: "8px",
                outline: "none",
                fontSize: "15px",
              }}
            />
          </div>

          {/* EMAIL */}

          <div
            style={{
              marginBottom: "16px",
            }}
          >
            <label
              style={{
                display: "block",
                marginBottom: "7px",
                fontWeight: "600",
                color: "#374151",
                fontSize: "14px",
              }}
            >
              Email
            </label>

            <input
              type="email"
              name="email"
              value={form.email}
              onChange={handleChange}
              placeholder="Enter your email"
              autoComplete="email"
              disabled={loading}
              style={{
                width: "100%",
                boxSizing: "border-box",
                padding: "12px 14px",
                border:
                  "1px solid #d1d5db",
                borderRadius: "8px",
                outline: "none",
                fontSize: "15px",
              }}
            />
          </div>

          {/* PHONE */}

          <div
            style={{
              marginBottom: "16px",
            }}
          >
            <label
              style={{
                display: "block",
                marginBottom: "7px",
                fontWeight: "600",
                color: "#374151",
                fontSize: "14px",
              }}
            >
              Phone
            </label>

            <input
              type="tel"
              name="phone"
              value={form.phone}
              onChange={handleChange}
              placeholder="Enter your phone number"
              autoComplete="tel"
              disabled={loading}
              style={{
                width: "100%",
                boxSizing: "border-box",
                padding: "12px 14px",
                border:
                  "1px solid #d1d5db",
                borderRadius: "8px",
                outline: "none",
                fontSize: "15px",
              }}
            />
          </div>

          {/* PASSWORD */}

          <div
            style={{
              marginBottom: "16px",
            }}
          >
            <label
              style={{
                display: "block",
                marginBottom: "7px",
                fontWeight: "600",
                color: "#374151",
                fontSize: "14px",
              }}
            >
              Password
            </label>

            <input
              type="password"
              name="password"
              value={form.password}
              onChange={handleChange}
              placeholder="Create a password"
              autoComplete="new-password"
              disabled={loading}
              style={{
                width: "100%",
                boxSizing: "border-box",
                padding: "12px 14px",
                border:
                  "1px solid #d1d5db",
                borderRadius: "8px",
                outline: "none",
                fontSize: "15px",
              }}
            />
          </div>

          {/* CONFIRM PASSWORD */}

          <div
            style={{
              marginBottom: "22px",
            }}
          >
            <label
              style={{
                display: "block",
                marginBottom: "7px",
                fontWeight: "600",
                color: "#374151",
                fontSize: "14px",
              }}
            >
              Confirm Password
            </label>

            <input
              type="password"
              name="confirmPassword"
              value={
                form.confirmPassword
              }
              onChange={handleChange}
              placeholder="Confirm your password"
              autoComplete="new-password"
              disabled={loading}
              style={{
                width: "100%",
                boxSizing: "border-box",
                padding: "12px 14px",
                border:
                  "1px solid #d1d5db",
                borderRadius: "8px",
                outline: "none",
                fontSize: "15px",
              }}
            />
          </div>

          {/* REGISTER BUTTON */}

          <button
            type="submit"
            disabled={loading}
            style={{
              width: "100%",
              border: "none",
              background:
                loading
                  ? "#93b4f5"
                  : "#2878ff",
              color: "#ffffff",
              padding: "13px 18px",
              borderRadius: "8px",
              cursor:
                loading
                  ? "not-allowed"
                  : "pointer",
              fontWeight: "700",
              fontSize: "16px",
            }}
          >
            {loading
              ? "Creating Account..."
              : "Create Account"}
          </button>
        </form>

        {/* LOGIN LINK */}

        <div
          style={{
            textAlign: "center",
            marginTop: "22px",
            color: "#6b7280",
            fontSize: "14px",
          }}
        >
          Already have an account?{" "}

          <button
            type="button"
            onClick={
              onSwitchToLogin
            }
            disabled={loading}
            style={{
              border: "none",
              background:
                "transparent",
              color: "#2878ff",
              cursor:
                loading
                  ? "not-allowed"
                  : "pointer",
              fontWeight: "700",
              padding: 0,
              fontSize: "14px",
            }}
          >
            Login
          </button>
        </div>

        {/* FOOTER */}

        <p
          style={{
            textAlign: "center",
            marginTop: "25px",
            marginBottom: 0,
            color: "#9ca3af",
            fontSize: "12px",
          }}
        >
          © {new Date().getFullYear()} Shop To Door
        </p>
      </div>
    </div>
  );
}

export default Register;