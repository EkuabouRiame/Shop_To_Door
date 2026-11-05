import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import "./index.css";
import App from "./App.jsx";
import PrivacyPolicy from "./PrivacyPolicy.jsx";
import DeleteAccount from "./DeleteAccount.jsx";

const pathname = window.location.pathname.replace(/\/+$/, "");

const isPrivacyPolicy = pathname === "/privacy-policy";
const isDeleteAccount = pathname === "/delete-account";

createRoot(document.getElementById("root")).render(
  <StrictMode>
    {isPrivacyPolicy ? (
      <PrivacyPolicy />
    ) : isDeleteAccount ? (
      <DeleteAccount />
    ) : (
      <App />
    )}
  </StrictMode>
);
