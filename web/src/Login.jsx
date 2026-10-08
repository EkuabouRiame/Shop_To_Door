import { useState } from "react";

import {
  saveAuth,
  saveQrCustomerAuth,
  getQrCustomerToken,
} from "./auth";

import logo from "./assets/shop-to-door-logo.png";

import "./Login.css";

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL ||
  "http://127.0.0.1:5000/api";

function Login({
  onLogin,
  onSwitchToRegister,
  qrMode = false,
}) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  // =====================================================
  // FORGOT PASSWORD
  // =====================================================

  const [forgotPassword, setForgotPassword] = useState(false);
  const [resetStep, setResetStep] = useState("email");

  const [resetEmail, setResetEmail] = useState("");
  const [otp, setOtp] = useState("");

  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");

  const [resetLoading, setResetLoading] = useState(false);
  const [resetMessage, setResetMessage] = useState("");

  // =====================================================
  // NORMAL LOGIN
  // =====================================================

  async function handleSubmit(event) {
    event.preventDefault();

    setError("");

    const cleanedEmail = email.trim();

    if (!cleanedEmail) {
      setError("Please enter your email.");
      return;
    }

    if (!password) {
      setError("Please enter your password.");
      return;
    }

    try {
      setLoading(true);

      const response = await fetch(
        `${API_BASE_URL}/auth/login`,
        {
          method: "POST",

          headers: {
            "Content-Type": "application/json",
            Accept: "application/json",
          },

          body: JSON.stringify({
            email: cleanedEmail,
            password,
          }),
        }
      );

      let data;

      try {
        data = await response.json();
      } catch {
        throw new Error(
          `Server returned an invalid response. HTTP ${response.status}`
        );
      }

      console.log(
        "Login response:",
        data
      );

      if (!response.ok) {
        throw new Error(
          data?.message ||
            data?.msg ||
            `Login failed. HTTP ${response.status}`
        );
      }

      if (data?.status !== "success") {
        throw new Error(
          data?.message ||
            "Login failed."
        );
      }

      if (!data?.access_token) {
        throw new Error(
          "Login succeeded, but no access token was returned."
        );
      }

      if (!data?.user) {
        throw new Error(
          "Login succeeded, but user information was not returned."
        );
      }

      // =====================================================
      // QR CUSTOMER LOGIN
      // =====================================================

      if (qrMode) {
        console.log(
          "Saving QR customer authentication..."
        );

        saveQrCustomerAuth(
          data.access_token,
          data.user
        );

        // Verify that the QR customer token
        // was actually stored.
        const savedQrToken =
          getQrCustomerToken();

        if (!savedQrToken) {
          throw new Error(
            "Customer login succeeded, but the QR customer session could not be saved."
          );
        }

        console.log(
          "QR customer authentication saved successfully."
        );

        console.log(
          "QR customer token exists:",
          true
        );
      }

      // =====================================================
      // NORMAL LOGIN
      // =====================================================

      else {
        saveAuth(
          data.access_token,
          data.user
        );

        console.log(
          "Normal authentication saved successfully."
        );
      }

      // =====================================================
      // LOGIN CALLBACK
      // =====================================================

      if (onLogin) {
        onLogin(data.user);
      }
    } catch (error) {
      console.error(
        "Login error:",
        error
      );

      setError(
        error?.message ||
          "Unable to login. Please try again."
      );
    } finally {
      setLoading(false);
    }
  }

  // =====================================================
  // OPEN FORGOT PASSWORD
  // =====================================================

  function openForgotPassword() {
    setForgotPassword(true);
    setResetStep("email");

    setResetEmail(email.trim());

    setOtp("");
    setNewPassword("");
    setConfirmPassword("");

    setError("");
    setResetMessage("");
  }

  // =====================================================
  // BACK TO LOGIN
  // =====================================================

  function backToLogin() {
    setForgotPassword(false);
    setResetStep("email");

    setResetEmail("");
    setOtp("");
    setNewPassword("");
    setConfirmPassword("");

    setResetLoading(false);
    setResetMessage("");
    setError("");
  }

  // =====================================================
  // SEND RESET OTP
  // =====================================================

  async function handleForgotPasswordSubmit(event) {
    event.preventDefault();

    setError("");
    setResetMessage("");

    const cleanedEmail = resetEmail.trim();

    if (!cleanedEmail) {
      setError("Please enter your email.");
      return;
    }

    try {
      setResetLoading(true);

      const response = await fetch(
        `${API_BASE_URL}/auth/forgot-password`,
        {
          method: "POST",

          headers: {
            "Content-Type": "application/json",
            Accept: "application/json",
          },

          body: JSON.stringify({
            email: cleanedEmail,
          }),
        }
      );

      let data;

      try {
        data = await response.json();
      } catch {
        throw new Error(
          `Server returned an invalid response. HTTP ${response.status}`
        );
      }

      console.log(
        "Forgot password response:",
        data
      );

      if (!response.ok) {
        throw new Error(
          data?.message ||
            data?.msg ||
            `Unable to send OTP. HTTP ${response.status}`
        );
      }

      setResetMessage(
        data?.message ||
          "If an account exists with this email, a password reset OTP has been sent."
      );

      setResetStep("otp");
    } catch (error) {
      console.error(
        "Forgot password error:",
        error
      );

      setError(
        error?.message ||
          "Unable to send reset OTP. Please try again."
      );
    } finally {
      setResetLoading(false);
    }
  }

  // =====================================================
  // VERIFY OTP
  // =====================================================

  async function handleVerifyOtp(event) {
    event.preventDefault();

    setError("");
    setResetMessage("");

    const cleanedEmail = resetEmail.trim();
    const cleanedOtp = otp.trim();

    if (!cleanedEmail) {
      setError("Please enter your email.");
      return;
    }

    if (!cleanedOtp) {
      setError("Please enter the OTP.");
      return;
    }

    if (!/^\d{6}$/.test(cleanedOtp)) {
      setError("Please enter the 6-digit OTP.");
      return;
    }

    try {
      setResetLoading(true);

      const response = await fetch(
        `${API_BASE_URL}/auth/verify-reset-otp`,
        {
          method: "POST",

          headers: {
            "Content-Type": "application/json",
            Accept: "application/json",
          },

          body: JSON.stringify({
            email: cleanedEmail,
            otp: cleanedOtp,
          }),
        }
      );

      let data;

      try {
        data = await response.json();
      } catch {
        throw new Error(
          `Server returned an invalid response. HTTP ${response.status}`
        );
      }

      console.log(
        "OTP verification response:",
        data
      );

      if (!response.ok) {
        throw new Error(
          data?.message ||
            data?.msg ||
            `OTP verification failed. HTTP ${response.status}`
        );
      }

      setResetMessage(
        data?.message ||
          "OTP verified successfully."
      );

      setResetStep("password");
    } catch (error) {
      console.error(
        "OTP verification error:",
        error
      );

      setError(
        error?.message ||
          "Invalid or expired OTP."
      );
    } finally {
      setResetLoading(false);
    }
  }

  // =====================================================
  // RESET PASSWORD
  // =====================================================

  async function handleResetPassword(event) {
    event.preventDefault();

    setError("");
    setResetMessage("");

    const cleanedEmail = resetEmail.trim();

    if (!newPassword) {
      setError("Please enter a new password.");
      return;
    }

    if (newPassword.length < 6) {
      setError(
        "Password must be at least 6 characters."
      );
      return;
    }

    if (!confirmPassword) {
      setError(
        "Please confirm your new password."
      );
      return;
    }

    if (newPassword !== confirmPassword) {
      setError(
        "Passwords do not match."
      );
      return;
    }

    try {
      setResetLoading(true);

      const response = await fetch(
        `${API_BASE_URL}/auth/reset-password`,
        {
          method: "POST",

          headers: {
            "Content-Type": "application/json",
            Accept: "application/json",
          },

          body: JSON.stringify({
            email: cleanedEmail,
            new_password: newPassword,
            confirm_password: confirmPassword,
          }),
        }
      );

      let data;

      try {
        data = await response.json();
      } catch {
        throw new Error(
          `Server returned an invalid response. HTTP ${response.status}`
        );
      }

      console.log(
        "Reset password response:",
        data
      );

      if (!response.ok) {
        throw new Error(
          data?.message ||
            data?.msg ||
            `Password reset failed. HTTP ${response.status}`
        );
      }

      setResetMessage(
        data?.message ||
          "Password reset successfully. You can now login."
      );

      setNewPassword("");
      setConfirmPassword("");

      // Return to normal login after a short delay.
      setTimeout(() => {
        setForgotPassword(false);
        setResetStep("email");
        setResetEmail("");
        setOtp("");
        setResetMessage("");
        setError("");

        // Put the reset email into the normal login field.
        setEmail(cleanedEmail);
      }, 2000);
    } catch (error) {
      console.error(
        "Reset password error:",
        error
      );

      setError(
        error?.message ||
          "Unable to reset password. Please try again."
      );
    } finally {
      setResetLoading(false);
    }
  }

  return (
    <div className="auth-page">

      <div className="auth-card">

        {/* =================================================
            BRAND
        ================================================= */}

        <div className="auth-brand">

          <div className="auth-logo">
            <img
              src={logo}
              alt="Shop To Door Logo"
            />
          </div>

          <h1>
            Shop To Door
          </h1>

          <p>
            {qrMode
              ? "Customer login for delivery confirmation"
              : forgotPassword
              ? "Reset your password"
              : "Login to continue shopping"}
          </p>

        </div>

        {/* =================================================
            QR LOGIN MESSAGE
        ================================================= */}

        {qrMode && (
          <div
            style={{
              marginBottom: "15px",
              padding: "12px",
              borderRadius: "8px",
              background: "#eff6ff",
              color: "#1e40af",
              fontSize: "14px",
              textAlign: "center",
            }}
          >
            Please log in as the customer
            who placed this order.
          </div>
        )}

        {/* =================================================
            FORGOT PASSWORD
        ================================================= */}

        {forgotPassword && !qrMode ? (

          <div>

            {/* =================================================
                STEP 1 - EMAIL
            ================================================= */}

            {resetStep === "email" && (
              <form
                onSubmit={
                  handleForgotPasswordSubmit
                }
                className="auth-form"
              >

                <label htmlFor="reset-email">
                  Email
                </label>

                <input
                  id="reset-email"
                  type="email"
                  value={resetEmail}
                  placeholder="Enter your registered email"
                  autoComplete="email"
                  disabled={resetLoading}
                  onChange={(event) => {
                    setResetEmail(
                      event.target.value
                    );

                    setError("");
                    setResetMessage("");
                  }}
                />

                {error && (
                  <div className="auth-error">
                    {error}
                  </div>
                )}

                {resetMessage && (
                  <div
                    style={{
                      marginTop: "10px",
                      marginBottom: "10px",
                      padding: "10px",
                      borderRadius: "8px",
                      background: "#ecfdf5",
                      color: "#047857",
                      fontSize: "14px",
                    }}
                  >
                    {resetMessage}
                  </div>
                )}

                <button
                  type="submit"
                  className="auth-button"
                  disabled={resetLoading}
                >
                  {resetLoading
                    ? "Sending OTP..."
                    : "Send OTP"}
                </button>

                <button
                  type="button"
                  onClick={backToLogin}
                  disabled={resetLoading}
                  style={{
                    width: "100%",
                    marginTop: "10px",
                    padding: "10px",
                    border: "none",
                    background: "transparent",
                    cursor: "pointer",
                    color: "#2563eb",
                    fontSize: "14px",
                  }}
                >
                  ← Back to Login
                </button>

              </form>
            )}

            {/* =================================================
                STEP 2 - OTP
            ================================================= */}

            {resetStep === "otp" && (
              <form
                onSubmit={handleVerifyOtp}
                className="auth-form"
              >

                <label htmlFor="reset-otp">
                  Enter OTP
                </label>

                <input
                  id="reset-otp"
                  type="text"
                  inputMode="numeric"
                  maxLength={6}
                  value={otp}
                  placeholder="Enter 6-digit OTP"
                  autoComplete="one-time-code"
                  disabled={resetLoading}
                  onChange={(event) => {
                    const value =
                      event.target.value.replace(
                        /\D/g,
                        ""
                      );

                    setOtp(value);
                    setError("");
                    setResetMessage("");
                  }}
                />

                <p
                  style={{
                    marginTop: "4px",
                    marginBottom: "10px",
                    fontSize: "13px",
                    color: "#6b7280",
                    textAlign: "center",
                  }}
                >
                  We sent a 6-digit OTP to your
                  registered email.
                </p>

                {error && (
                  <div className="auth-error">
                    {error}
                  </div>
                )}

                {resetMessage && (
                  <div
                    style={{
                      marginTop: "10px",
                      marginBottom: "10px",
                      padding: "10px",
                      borderRadius: "8px",
                      background: "#ecfdf5",
                      color: "#047857",
                      fontSize: "14px",
                    }}
                  >
                    {resetMessage}
                  </div>
                )}

                <button
                  type="submit"
                  className="auth-button"
                  disabled={resetLoading}
                >
                  {resetLoading
                    ? "Verifying..."
                    : "Verify OTP"}
                </button>

                <button
                  type="button"
                  onClick={() => {
                    setResetStep("email");
                    setOtp("");
                    setError("");
                    setResetMessage("");
                  }}
                  disabled={resetLoading}
                  style={{
                    width: "100%",
                    marginTop: "10px",
                    padding: "10px",
                    border: "none",
                    background: "transparent",
                    cursor: "pointer",
                    color: "#2563eb",
                    fontSize: "14px",
                  }}
                >
                  ← Change Email
                </button>

              </form>
            )}

            {/* =================================================
                STEP 3 - NEW PASSWORD
            ================================================= */}

            {resetStep === "password" && (
              <form
                onSubmit={handleResetPassword}
                className="auth-form"
              >

                <label htmlFor="new-password">
                  New Password
                </label>

                <input
                  id="new-password"
                  type="password"
                  value={newPassword}
                  placeholder="Enter new password"
                  autoComplete="new-password"
                  disabled={resetLoading}
                  onChange={(event) => {
                    setNewPassword(
                      event.target.value
                    );

                    setError("");
                    setResetMessage("");
                  }}
                />

                <label htmlFor="confirm-password">
                  Confirm New Password
                </label>

                <input
                  id="confirm-password"
                  type="password"
                  value={confirmPassword}
                  placeholder="Confirm new password"
                  autoComplete="new-password"
                  disabled={resetLoading}
                  onChange={(event) => {
                    setConfirmPassword(
                      event.target.value
                    );

                    setError("");
                    setResetMessage("");
                  }}
                />

                <p
                  style={{
                    marginTop: "4px",
                    marginBottom: "10px",
                    fontSize: "13px",
                    color: "#6b7280",
                    textAlign: "center",
                  }}
                >
                  Password must be at least 6
                  characters.
                </p>

                {error && (
                  <div className="auth-error">
                    {error}
                  </div>
                )}

                {resetMessage && (
                  <div
                    style={{
                      marginTop: "10px",
                      marginBottom: "10px",
                      padding: "10px",
                      borderRadius: "8px",
                      background: "#ecfdf5",
                      color: "#047857",
                      fontSize: "14px",
                    }}
                  >
                    {resetMessage}
                  </div>
                )}

                <button
                  type="submit"
                  className="auth-button"
                  disabled={resetLoading}
                >
                  {resetLoading
                    ? "Resetting Password..."
                    : "Reset Password"}
                </button>

              </form>
            )}

          </div>

        ) : (

          /* =================================================
             NORMAL LOGIN FORM
          ================================================= */

          <form
            onSubmit={handleSubmit}
            className="auth-form"
          >

            <label htmlFor="login-email">
              Email
            </label>

            <input
              id="login-email"
              type="email"
              value={email}
              placeholder="Enter your email"
              autoComplete="email"
              disabled={loading}
              onChange={(event) => {
                setEmail(
                  event.target.value
                );

                setError("");
              }}
            />

            <label htmlFor="login-password">
              Password
            </label>

            <input
              id="login-password"
              type="password"
              value={password}
              placeholder="Enter your password"
              autoComplete="current-password"
              disabled={loading}
              onChange={(event) => {
                setPassword(
                  event.target.value
                );

                setError("");
              }}
            />

            {/* =================================================
                FORGOT PASSWORD LINK
            ================================================= */}

            {!qrMode && (
              <div
                style={{
                  textAlign: "right",
                  marginTop: "-5px",
                  marginBottom: "5px",
                }}
              >
                <button
                  type="button"
                  onClick={openForgotPassword}
                  disabled={loading}
                  style={{
                    border: "none",
                    background: "transparent",
                    color: "#2563eb",
                    cursor: "pointer",
                    padding: "4px 0",
                    fontSize: "14px",
                  }}
                >
                  Forgot Password?
                </button>
              </div>
            )}

            {/* =================================================
                ERROR
            ================================================= */}

            {error && (
              <div className="auth-error">
                {error}
              </div>
            )}

            {/* =================================================
                LOGIN BUTTON
            ================================================= */}

            <button
              type="submit"
              className="auth-button"
              disabled={loading}
            >
              {loading
                ? "Logging in..."
                : qrMode
                ? "Login & Continue"
                : "Login"}
            </button>

          </form>
        )}

        {/* =================================================
            REGISTER
        ================================================= */}

        {!qrMode && !forgotPassword && (
          <div className="auth-switch">

            <span>
              Don't have an account?
            </span>

            <button
              type="button"
              onClick={onSwitchToRegister}
              disabled={loading}
            >
              Create Account
            </button>

          </div>
        )}

      </div>

    </div>
  );
}

export default Login;