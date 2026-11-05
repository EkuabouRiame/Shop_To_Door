import React from "react";

export default function DeleteAccount() {
  const supportEmail = "shoptodoortamenglong@gmail.com";

  return (
    <main
      style={{
        maxWidth: "760px",
        margin: "0 auto",
        padding: "32px 20px 56px",
        fontFamily: "Arial, sans-serif",
        color: "#1f2937",
        lineHeight: 1.7,
      }}
    >
      <a href="/" style={{ color: "#6750a4" }}>
        ← Back to Shop To Door
      </a>

      <h1 style={{ color: "#111827", marginTop: "24px" }}>
        Request Account Deletion
      </h1>

      <p>
        Shop To Door users can request deletion of their account and
        associated personal data using the instructions below.
      </p>

      <h2>How to request deletion</h2>
      <ol>
        <li>
          Email{" "}
          <a href={`mailto:${supportEmail}?subject=Shop%20To%20Door%20Account%20Deletion`}>
            {supportEmail}
          </a>
          .
        </li>
        <li>
          Use the subject line <strong>Shop To Door Account Deletion</strong>.
        </li>
        <li>
          Include the email address registered to your Shop To Door account
          so we can identify it and verify your request.
        </li>
        <li>
          Do not include your password or payment card details in your email.
        </li>
      </ol>

      <h2>What happens after your request</h2>
      <p>
        We will review your request and aim to complete eligible account
        deletion requests within 30 days after verifying your identity.
        We may contact you if additional information is needed.
      </p>

      <h2>Data that may be deleted</h2>
      <p>
        Depending on the records associated with your account, deletion may
        include your account profile, contact details, saved cart, and other
        personal information that is not required to be retained.
      </p>

      <h2>Data that may be retained</h2>
      <p>
        Certain order, payment, tax, fraud-prevention, or dispute records may
        need to be retained for legal, accounting, security, or legitimate
        business requirements. Where retention is required, we will retain
        only the necessary information for the applicable period and handle
        it according to our Privacy Policy.
      </p>

      <h2>Need help?</h2>
      <p>
        Contact{" "}
        <a href={`mailto:${supportEmail}`}>{supportEmail}</a>
        {" "}if you have questions about account deletion.
      </p>

      <p style={{ marginTop: "32px", fontSize: "14px", color: "#6b7280" }}>
        Shop To Door · Account Deletion
      </p>

      <p>
        <a href="/privacy-policy" style={{ color: "#6750a4" }}>
          Read our Privacy Policy
        </a>
      </p>
    </main>
  );
}
