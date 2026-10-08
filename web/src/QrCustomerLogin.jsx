import Login from "./Login";

function QrCustomerLogin({
  onLogin,
  onBack,
}) {
  return (
    <div>
      <button
        type="button"
        onClick={onBack}
        style={{
          position: "fixed",
          top: "20px",
          left: "20px",
          zIndex: 1000,
          padding: "10px 16px",
          border: "none",
          borderRadius: "8px",
          cursor: "pointer",
          background: "#e5e7eb",
        }}
      >
        ← Back
      </button>

      <Login
        qrMode={true}
        onLogin={onLogin}
      />
    </div>
  );
}

export default QrCustomerLogin;