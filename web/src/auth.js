const TOKEN_KEY = "shop_to_door_token";
const USER_KEY = "shop_to_door_user";

// Separate customer session used specifically
// for QR delivery confirmation
const QR_CUSTOMER_TOKEN_KEY =
  "shop_to_door_qr_customer_token";

const QR_CUSTOMER_USER_KEY =
  "shop_to_door_qr_customer_user";

// =========================================================
// NORMAL APP AUTHENTICATION
// =========================================================

export function saveAuth(token, user) {
  if (token) {
    localStorage.setItem(TOKEN_KEY, token);
  }

  if (user) {
    localStorage.setItem(
      USER_KEY,
      JSON.stringify(user)
    );
  }
}

export function getToken() {
  return localStorage.getItem(TOKEN_KEY);
}

// Delivery Dashboard uses its own named function.
// It uses the normal delivery-person session and
// does NOT use the QR customer session.
export function getDeliveryToken() {
  return localStorage.getItem(TOKEN_KEY);
}

export function getUser() {
  const user = localStorage.getItem(USER_KEY);

  if (!user) {
    return null;
  }

  try {
    return JSON.parse(user);
  } catch (error) {
    console.error(
      "Unable to read saved user:",
      error
    );

    return null;
  }
}

// =========================================================
// QR CUSTOMER AUTHENTICATION
// =========================================================

export function saveQrCustomerAuth(
  token,
  user
) {
  if (token) {
    localStorage.setItem(
      QR_CUSTOMER_TOKEN_KEY,
      token
    );
  }

  if (user) {
    localStorage.setItem(
      QR_CUSTOMER_USER_KEY,
      JSON.stringify(user)
    );
  }
}

export function getQrCustomerToken() {
  return localStorage.getItem(
    QR_CUSTOMER_TOKEN_KEY
  );
}

export function getQrCustomerUser() {
  const user = localStorage.getItem(
    QR_CUSTOMER_USER_KEY
  );

  if (!user) {
    return null;
  }

  try {
    return JSON.parse(user);
  } catch (error) {
    console.error(
      "Unable to read QR customer user:",
      error
    );

    return null;
  }
}

export function clearQrCustomerAuth() {
  localStorage.removeItem(
    QR_CUSTOMER_TOKEN_KEY
  );

  localStorage.removeItem(
    QR_CUSTOMER_USER_KEY
  );
}

// =========================================================
// LOGIN STATUS
// =========================================================

export function isLoggedIn() {
  return !!getToken();
}

// =========================================================
// ROLE HELPERS
// =========================================================

export function isAdmin(user = getUser()) {
  if (!user) {
    return false;
  }

  return (
    user.role === "admin" ||
    user.role === "ADMIN" ||
    user.is_admin === true ||
    user.isAdmin === true
  );
}

export function isDeliveryPerson(
  user = getUser()
) {
  if (!user) {
    return false;
  }

  return (
    String(user.role || "")
      .toLowerCase() ===
    "delivery_person"
  );
}

export function getUserRole(
  user = getUser()
) {
  if (!user) {
    return null;
  }

  if (user.role) {
    return String(
      user.role
    ).toLowerCase();
  }

  if (
    user.is_admin === true ||
    user.isAdmin === true
  ) {
    return "admin";
  }

  return "customer";
}

export function isCustomer(
  user = getUser()
) {
  return (
    !!user &&
    getUserRole(user) === "customer"
  );
}

// =========================================================
// NORMAL LOGOUT
// =========================================================

export function logout() {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(USER_KEY);
}