import { useEffect, useState } from "react";
import { getToken } from "./auth";
import "./LocationPage.css";

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL ||
  "https://shop-to-door-backend-294288480400.asia-south2.run.app/api";

function LocationPage({ onBack }) {
  const [form, setForm] = useState({
    address: "",
    city: "",
    state: "",
    pincode: "",
  });

  const [latitude, setLatitude] = useState(null);
  const [longitude, setLongitude] = useState(null);

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [locating, setLocating] = useState(false);

  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  // =====================================================
  // LOAD SAVED LOCATION
  // =====================================================

  useEffect(() => {
    loadLocation();
  }, []);

  async function loadLocation() {
    const token = getToken();

    if (!token) {
      setError("Please login first.");
      setLoading(false);
      return;
    }

    try {
      const response = await fetch(
        `${API_BASE_URL}/users/location`,
        {
          method: "GET",
          headers: {
            Accept: "application/json",
            Authorization: `Bearer ${token}`,
          },
        }
      );

      const data = await response.json();

      if (!response.ok) {
        throw new Error(
          data?.message ||
            "Unable to load delivery location."
        );
      }

      if (data.location) {
        setForm({
          address: data.location.address || "",
          city: data.location.city || "",
          state: data.location.state || "",
          pincode: data.location.pincode || "",
        });

        setLatitude(
          data.location.latitude ?? null
        );

        setLongitude(
          data.location.longitude ?? null
        );
      }
    } catch (err) {
      console.error(
        "Load location error:",
        err
      );

      setError(
        err.message ||
          "Unable to load location."
      );
    } finally {
      setLoading(false);
    }
  }

  // =====================================================
  // HANDLE INPUT
  // =====================================================

  function handleChange(event) {
    const { name, value } = event.target;

    setForm((previous) => ({
      ...previous,
      [name]: value,
    }));

    setMessage("");
    setError("");
  }

  // =====================================================
  // GET CURRENT LOCATION
  // =====================================================

  function useCurrentLocation() {
    setMessage("");
    setError("");

    if (!navigator.geolocation) {
      setError(
        "Location services are not supported by this browser."
      );
      return;
    }

    setLocating(true);

    navigator.geolocation.getCurrentPosition(
      (position) => {
        const lat =
          position.coords.latitude;

        const lng =
          position.coords.longitude;

        setLatitude(lat);
        setLongitude(lng);

        setMessage(
          "Current location detected. Please enter or verify your address."
        );

        setLocating(false);
      },

      (locationError) => {
        console.error(
          "Location error:",
          locationError
        );

        if (
          locationError.code ===
          locationError.PERMISSION_DENIED
        ) {
          setError(
            "Location permission was denied. You can enter your address manually."
          );
        } else if (
          locationError.code ===
          locationError.POSITION_UNAVAILABLE
        ) {
          setError(
            "Your current location could not be detected."
          );
        } else {
          setError(
            "Unable to detect your current location."
          );
        }

        setLocating(false);
      },

      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 0,
      }
    );
  }

  // =====================================================
  // SAVE LOCATION
  // =====================================================

  async function handleSubmit(event) {
    event.preventDefault();

    setMessage("");
    setError("");

    const token = getToken();

    if (!token) {
      setError("Please login first.");
      return;
    }

    if (!latitude || !longitude) {
      setError(
        "Please use your current location first, or location coordinates are missing."
      );
      return;
    }

    if (!form.address.trim()) {
      setError("Please enter your address.");
      return;
    }

    if (!form.city.trim()) {
      setError("Please enter your city or town.");
      return;
    }

    if (!form.state.trim()) {
      setError("Please enter your state.");
      return;
    }

    if (!form.pincode.trim()) {
      setError("Please enter your PIN code.");
      return;
    }

    if (!/^[0-9]{6}$/.test(form.pincode.trim())) {
      setError(
        "Please enter a valid 6-digit PIN code."
      );
      return;
    }

    try {
      setSaving(true);

      const response = await fetch(
        `${API_BASE_URL}/users/location`,
        {
          method: "POST",

          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
          },

          body: JSON.stringify({
            latitude,
            longitude,
            address: form.address.trim(),
            city: form.city.trim(),
            state: form.state.trim(),
            pincode: form.pincode.trim(),
          }),
        }
      );

      const data = await response.json();

      console.log(
        "Save location response:",
        data
      );

      if (!response.ok) {
        throw new Error(
          data?.message ||
            "Unable to save delivery location."
        );
      }

      setMessage(
        "Delivery location saved successfully."
      );
    } catch (err) {
      console.error(
        "Save location error:",
        err
      );

      setError(
        err.message ||
          "Unable to save delivery location."
      );
    } finally {
      setSaving(false);
    }
  }

  // =====================================================
  // LOADING
  // =====================================================

  if (loading) {
    return (
      <main className="location-page">
        <div className="location-card">
          <p>Loading your delivery location...</p>
        </div>
      </main>
    );
  }

  // =====================================================
  // RENDER
  // =====================================================

  return (
    <main className="location-page">

      <div className="location-card">

        {/* HEADER */}

        <div className="location-header">

          <button
            type="button"
            className="location-back"
            onClick={onBack}
          >
            ← Back
          </button>

          <div className="location-title">

            <div className="location-icon">
              📍
            </div>

            <div>
              <h1>
                Delivery Location
              </h1>

              <p>
                Add your address for easy delivery
              </p>
            </div>

          </div>

        </div>

        {/* CURRENT LOCATION */}

        <button
          type="button"
          className="current-location-button"
          onClick={useCurrentLocation}
          disabled={locating || saving}
        >
          {locating
            ? "Detecting location..."
            : "📍 Use My Current Location"}
        </button>

        {/* COORDINATES */}

        {latitude !== null &&
          longitude !== null && (
            <div className="location-detected">

              <strong>
                Location detected
              </strong>

              <span>
                Latitude:{" "}
                {latitude.toFixed(6)}
              </span>

              <span>
                Longitude:{" "}
                {longitude.toFixed(6)}
              </span>

            </div>
          )}

        {/* MESSAGES */}

        {message && (
          <div className="location-success">
            {message}
          </div>
        )}

        {error && (
          <div className="location-error">
            {error}
          </div>
        )}

        {/* FORM */}

        <form
          className="location-form"
          onSubmit={handleSubmit}
        >

          <label htmlFor="address">
            Full Address
          </label>

          <textarea
            id="address"
            name="address"
            value={form.address}
            onChange={handleChange}
            placeholder="House number, street, locality, landmark..."
            rows="4"
            disabled={saving}
          />

          <label htmlFor="city">
            City / Town / Village
          </label>

          <input
            id="city"
            name="city"
            type="text"
            value={form.city}
            onChange={handleChange}
            placeholder="Enter city, town or village"
            disabled={saving}
          />

          <label htmlFor="state">
            State
          </label>

          <input
            id="state"
            name="state"
            type="text"
            value={form.state}
            onChange={handleChange}
            placeholder="Enter state"
            disabled={saving}
          />

          <label htmlFor="pincode">
            PIN Code
          </label>

          <input
            id="pincode"
            name="pincode"
            type="text"
            inputMode="numeric"
            maxLength="6"
            value={form.pincode}
            onChange={handleChange}
            placeholder="Enter 6-digit PIN code"
            disabled={saving}
          />

          <button
            type="submit"
            className="save-location-button"
            disabled={saving}
          >
            {saving
              ? "Saving..."
              : "Save Delivery Location"}
          </button>

        </form>

      </div>

    </main>
  );
}

export default LocationPage;
