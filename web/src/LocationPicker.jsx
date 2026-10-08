import { useEffect, useRef, useState } from "react";

import {
  MapContainer,
  TileLayer,
  Marker,
  Popup,
  useMap,
} from "react-leaflet";

import L from "leaflet";

import "leaflet/dist/leaflet.css";
import "./LocationPicker.css";

import { getToken } from "./auth";

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL ||
  "https://shop-to-door-backend-294288480400.asia-south2.run.app/api";

// =========================================================
// FIX LEAFLET DEFAULT MARKER ICON
// =========================================================

delete L.Icon.Default.prototype._getIconUrl;

L.Icon.Default.mergeOptions({
  iconRetinaUrl:
    "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon-2x.png",

  iconUrl:
    "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon.png",

  shadowUrl:
    "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png",
});

// =========================================================
// MAP CONTROLLER
// =========================================================

function MapController({ position, tracking }) {
  const map = useMap();

  useEffect(() => {
    if (!position) {
      return;
    }

    map.setView(
      position,
      tracking ? 17 : 16,
      {
        animate: true,
      }
    );
  }, [position, tracking, map]);

  return null;
}

// =========================================================
// LOCATION PICKER
// =========================================================

function LocationPicker() {
  // Current latitude + longitude
  const [position, setPosition] = useState(null);

  // One-time location loading
  const [loading, setLoading] = useState(false);

  // Saving location to backend
  const [saving, setSaving] = useState(false);

  // Live tracking state
  const [tracking, setTracking] = useState(false);

  // Messages
  const [message, setMessage] = useState("");

  // Errors
  const [error, setError] = useState("");

  // Browser watchPosition ID
  const watchIdRef = useRef(null);

  // =========================================================
  // STOP LIVE LOCATION
  // =========================================================

  function stopLiveLocation(showMessage = true) {
    if (
      watchIdRef.current !== null &&
      navigator.geolocation
    ) {
      navigator.geolocation.clearWatch(
        watchIdRef.current
      );

      watchIdRef.current = null;
    }

    setTracking(false);
    setLoading(false);

    if (showMessage) {
      setMessage(
        "Live location tracking stopped."
      );
    }
  }

  // =========================================================
  // START LIVE LOCATION
  // =========================================================

  function startLiveLocation() {
    setError("");
    setMessage("");

    if (!navigator.geolocation) {
      setError(
        "Geolocation is not supported by your browser."
      );

      return;
    }

    // Prevent duplicate tracking
    if (watchIdRef.current !== null) {
      navigator.geolocation.clearWatch(
        watchIdRef.current
      );

      watchIdRef.current = null;
    }

    setLoading(true);

    const watchId =
      navigator.geolocation.watchPosition(
        (location) => {
          const latitude =
            location.coords.latitude;

          const longitude =
            location.coords.longitude;

          console.log(
            "Live location:",
            latitude,
            longitude
          );

          setPosition([
            latitude,
            longitude,
          ]);

          setLoading(false);
          setTracking(true);

          setMessage(
            "📍 Live location is updating."
          );
        },

        (locationError) => {
          console.error(
            "Live location error:",
            locationError
          );

          let errorMessage =
            "Unable to get your live location.";

          if (
            locationError.code ===
            locationError.PERMISSION_DENIED
          ) {
            errorMessage =
              "Location permission was denied. Please allow location access in your browser.";
          } else if (
            locationError.code ===
            locationError.POSITION_UNAVAILABLE
          ) {
            errorMessage =
              "Your current location is unavailable.";
          } else if (
            locationError.code ===
            locationError.TIMEOUT
          ) {
            errorMessage =
              "Location request timed out. Please try again.";
          }

          setError(errorMessage);

          setLoading(false);
          setTracking(false);

          if (
            watchIdRef.current !== null
          ) {
            navigator.geolocation.clearWatch(
              watchIdRef.current
            );

            watchIdRef.current = null;
          }
        },

        {
          enableHighAccuracy: true,

          timeout: 15000,

          maximumAge: 0,
        }
      );

    watchIdRef.current = watchId;
  }

  // =========================================================
  // GET CURRENT LOCATION ONCE
  // =========================================================

  function getCurrentLocation() {
    setLoading(true);

    setError("");
    setMessage("");

    if (!navigator.geolocation) {
      setError(
        "Geolocation is not supported by your browser."
      );

      setLoading(false);

      return;
    }

    navigator.geolocation.getCurrentPosition(
      (location) => {
        const latitude =
          location.coords.latitude;

        const longitude =
          location.coords.longitude;

        console.log(
          "Current location:",
          latitude,
          longitude
        );

        setPosition([
          latitude,
          longitude,
        ]);

        setLoading(false);

        setMessage(
          "📍 Current location detected successfully."
        );
      },

      (locationError) => {
        console.error(
          "Location error:",
          locationError
        );

        let errorMessage =
          "Unable to get your location.";

        if (
          locationError.code ===
          locationError.PERMISSION_DENIED
        ) {
          errorMessage =
            "Location permission was denied. Please allow location access in your browser.";
        } else if (
          locationError.code ===
          locationError.POSITION_UNAVAILABLE
        ) {
          errorMessage =
            "Your location is currently unavailable.";
        } else if (
          locationError.code ===
          locationError.TIMEOUT
        ) {
          errorMessage =
            "Location request timed out. Please try again.";
        }

        setError(errorMessage);

        setLoading(false);
      },

      {
        enableHighAccuracy: true,

        timeout: 15000,

        maximumAge: 0,
      }
    );
  }

  // =========================================================
  // SAVE LOCATION TO FLASK BACKEND
  // =========================================================

  async function saveLocation() {
    const token = getToken();

    setError("");
    setMessage("");

    if (!token) {
      setError(
        "Please login before saving your location."
      );

      return;
    }

    if (!position) {
      setError(
        "Please detect your location first."
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
            "Content-Type":
              "application/json",

            Accept:
              "application/json",

            Authorization:
              `Bearer ${token}`,
          },

          body: JSON.stringify({
            latitude: position[0],

            longitude: position[1],
          }),
        }
      );

      let data;

      try {
        data = await response.json();
      } catch {
        throw new Error(
          `Invalid server response. HTTP ${response.status}`
        );
      }

      console.log(
        "Save location response:",
        data
      );

      if (!response.ok) {
        throw new Error(
          data?.message ||
            data?.msg ||
            `Unable to save location. HTTP ${response.status}`
        );
      }

      setMessage(
        "📍 Your delivery location has been saved successfully."
      );
    } catch (error) {
      console.error(
        "Save location error:",
        error
      );

      setError(
        error.message ||
          "Unable to save your location."
      );
    } finally {
      setSaving(false);
    }
  }

  // =========================================================
  // CLEANUP
  // =========================================================

  useEffect(() => {
    return () => {
      if (
        watchIdRef.current !== null &&
        navigator.geolocation
      ) {
        navigator.geolocation.clearWatch(
          watchIdRef.current
        );

        watchIdRef.current = null;
      }
    };
  }, []);

  // =========================================================
  // DEFAULT MAP LOCATION
  // =========================================================

  const defaultPosition = [
    24.817,
    93.9368,
  ];

  const mapPosition =
    position || defaultPosition;

  // =========================================================
  // RENDER
  // =========================================================

  return (
    <div className="location-page">

      <div className="location-card">

        {/* =====================================================
            HEADER
        ===================================================== */}

        <div className="location-header">

          <div>
            <h1>
              📍 My Location
            </h1>

            <p>
              Set your delivery location
            </p>
          </div>

        </div>

        {/* =====================================================
            CONTROLS
        ===================================================== */}

        <div className="location-controls">

          {/* ONE-TIME LOCATION */}

          <button
            type="button"
            className="location-button"
            onClick={getCurrentLocation}
            disabled={loading}
          >
            {loading
              ? "Detecting Location..."
              : "📍 Use My Current Location"}
          </button>

          {/* LIVE LOCATION */}

          {!tracking ? (
            <button
              type="button"
              className="location-button"
              onClick={startLiveLocation}
              disabled={loading}
            >
              🔴 Start Live Location
            </button>
          ) : (
            <button
              type="button"
              className="location-button"
              onClick={() =>
                stopLiveLocation(true)
              }
            >
              ⏹️ Stop Live Location
            </button>
          )}

          {/* SAVE LOCATION */}

          <button
            type="button"
            className="save-location-button"
            onClick={saveLocation}
            disabled={
              saving ||
              !position
            }
          >
            {saving
              ? "Saving..."
              : "💾 Save Location"}
          </button>

        </div>

        {/* =====================================================
            LIVE STATUS
        ===================================================== */}

        {tracking && (
          <div
            className="location-success"
            role="status"
          >
            🔴 <strong>
              Live location tracking is active
            </strong>

            <br />

            Your position will update as your
            device location changes.
          </div>
        )}

        {/* =====================================================
            NORMAL MESSAGE
        ===================================================== */}

        {message && !tracking && (
          <div
            className="location-success"
            role="status"
          >
            {message}
          </div>
        )}

        {/* =====================================================
            ERROR
        ===================================================== */}

        {error && (
          <div
            className="location-error"
            role="alert"
          >
            ⚠️ {error}
          </div>
        )}

        {/* =====================================================
            COORDINATES
        ===================================================== */}

        {position && (
          <div className="coordinates-box">

            <strong>
              {tracking
                ? "🔴 Live Coordinates"
                : "📍 Current Coordinates"}
            </strong>

            <p>
              Latitude:{" "}
              {position[0].toFixed(6)}
            </p>

            <p>
              Longitude:{" "}
              {position[1].toFixed(6)}
            </p>

          </div>
        )}

        {/* =====================================================
            MAP
        ===================================================== */}

        <div className="map-wrapper">

          <MapContainer
            center={mapPosition}
            zoom={
              position
                ? tracking
                  ? 17
                  : 16
                : 12
            }
            scrollWheelZoom={true}
            className="location-map"
          >

            <TileLayer
              attribution='&copy; OpenStreetMap contributors'
              url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            />

            <MapController
              position={position}
              tracking={tracking}
            />

            {position && (
              <Marker
                position={position}
              >
                <Popup>

                  <strong>
                    {tracking
                      ? "🔴 Live Location"
                      : "📍 Your Location"}
                  </strong>

                  <br />

                  Latitude:{" "}
                  {position[0].toFixed(6)}

                  <br />

                  Longitude:{" "}
                  {position[1].toFixed(6)}

                </Popup>
              </Marker>
            )}

          </MapContainer>

        </div>

        {/* =====================================================
            INSTRUCTIONS
        ===================================================== */}

        {!position && (
          <div className="location-instruction">

            <p>
              Click{" "}
              <strong>
                "Use My Current Location"
              </strong>{" "}
              to detect your location once.
            </p>

            <p>
              Or click{" "}
              <strong>
                "Start Live Location"
              </strong>{" "}
              to continuously update your
              position.
            </p>

            <p>
              Your browser will ask for
              permission to access your location.
            </p>

          </div>
        )}

        {/* =====================================================
            TRACKING INFORMATION
        ===================================================== */}

        {tracking && (
          <div className="location-instruction">

            <p>
              🔴 Your browser is currently
              watching your location.
            </p>

            <p>
              The marker will move when your
              device reports a new position.
            </p>

            <p>
              Click{" "}
              <strong>
                "Stop Live Location"
              </strong>{" "}
              when you no longer want to
              share your live position.
            </p>

          </div>
        )}

      </div>

    </div>
  );
}

export default LocationPicker;
