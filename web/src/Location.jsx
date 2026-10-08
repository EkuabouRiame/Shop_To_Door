import { useEffect, useState } from "react";

import {
  getToken,
  getUser,
  saveAuth,
} from "./auth";


// =========================================================
// API
// =========================================================

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL ||
  "https://shop-to-door-backend-294288480400.asia-south2.run.app/api";


// =========================================================
// LOCATION
// =========================================================

function Location({ onBack, onSaved }) {

  // =======================================================
  // STATE
  // =======================================================

  const [loading, setLoading] = useState(true);

  const [saving, setSaving] = useState(false);

  const [gettingLocation, setGettingLocation] =
    useState(false);

  const [message, setMessage] = useState("");

  const [error, setError] = useState("");


  // =======================================================
  // FORM
  // =======================================================

  const [form, setForm] = useState({

    latitude: "",

    longitude: "",

    address: "",

    city: "",

    state: "",

    pincode: "",

  });


  // =======================================================
  // LOAD EXISTING LOCATION
  // =======================================================

  useEffect(() => {

    async function loadLocation() {

      const token = getToken();


      // ---------------------------------------------------
      // CHECK LOGIN
      // ---------------------------------------------------

      if (!token) {

        setError(
          "You are not logged in."
        );

        setLoading(false);

        return;
      }


      // ---------------------------------------------------
      // GET LOCATION
      // ---------------------------------------------------

      try {

        const response = await fetch(
          `${API_BASE_URL}/users/location`,
          {
            method: "GET",

            headers: {
              Accept: "application/json",

              Authorization:
                `Bearer ${token}`,
            },
          }
        );


        // -------------------------------------------------
        // READ RESPONSE SAFELY
        // -------------------------------------------------

        let data;

        try {

          data = await response.json();

        } catch {

          throw new Error(
            `Invalid server response. HTTP ${response.status}`
          );

        }


        // -------------------------------------------------
        // CHECK RESPONSE
        // -------------------------------------------------

        if (!response.ok) {

          throw new Error(
            data.message ||
            "Failed to load delivery location"
          );

        }


        // -------------------------------------------------
        // LOAD LOCATION DATA
        // -------------------------------------------------

        if (data.location) {

          setForm({

            latitude:
              data.location.latitude ?? "",

            longitude:
              data.location.longitude ?? "",

            address:
              data.location.address ?? "",

            city:
              data.location.city ?? "",

            state:
              data.location.state ?? "",

            pincode:
              data.location.pincode ?? "",

          });

        }

      } catch (err) {

        console.error(
          "Load location error:",
          err
        );

        setError(
          err.message ||
          "Unable to load delivery location"
        );

      } finally {

        setLoading(false);

      }

    }


    loadLocation();

  }, []);


  // =======================================================
  // HANDLE INPUT
  // =======================================================

  function handleChange(event) {

    const {
      name,
      value,
    } = event.target;


    setForm((previous) => ({

      ...previous,

      [name]: value,

    }));

  }


  // =======================================================
  // GET CURRENT LOCATION
  // =======================================================

  function getCurrentLocation() {

    setMessage("");

    setError("");


    // -----------------------------------------------------
    // CHECK BROWSER SUPPORT
    // -----------------------------------------------------

    if (!navigator.geolocation) {

      setError(
        "Location services are not supported by this browser."
      );

      return;
    }


    setGettingLocation(true);


    // -----------------------------------------------------
    // GET GPS LOCATION
    // -----------------------------------------------------

    navigator.geolocation.getCurrentPosition(

      (position) => {

        const latitude =
          position.coords.latitude;

        const longitude =
          position.coords.longitude;


        setForm((previous) => ({

          ...previous,

          latitude:
            latitude.toFixed(6),

          longitude:
            longitude.toFixed(6),

        }));


        setMessage(
          "Current location detected successfully. Please enter or check your address details before saving."
        );


        setGettingLocation(false);

      },


      (locationError) => {

        console.error(
          "Geolocation error:",
          locationError
        );


        let errorMessage =
          "Unable to get your current location.";


        // -------------------------------------------------
        // PERMISSION DENIED
        // -------------------------------------------------

        if (
          locationError.code === 1
        ) {

          errorMessage =
            "Location permission was denied. Please allow location access in your browser.";

        }


        // -------------------------------------------------
        // POSITION UNAVAILABLE
        // -------------------------------------------------

        else if (
          locationError.code === 2
        ) {

          errorMessage =
            "Your location could not be determined.";

        }


        // -------------------------------------------------
        // TIMEOUT
        // -------------------------------------------------

        else if (
          locationError.code === 3
        ) {

          errorMessage =
            "Location request timed out. Please try again.";

        }


        setError(errorMessage);

        setGettingLocation(false);

      },


      // ---------------------------------------------------
      // GEOLOCATION OPTIONS
      // ---------------------------------------------------

      {
        enableHighAccuracy: true,

        timeout: 15000,

        maximumAge: 0,
      }

    );

  }


  // =======================================================
  // SAVE LOCATION
  // =======================================================

  async function handleSave(event) {

    event.preventDefault();


    setMessage("");

    setError("");


    // -----------------------------------------------------
    // GET TOKEN
    // -----------------------------------------------------

    const token = getToken();


    // -----------------------------------------------------
    // CHECK TOKEN
    // -----------------------------------------------------

    if (!token) {

      setError(
        "Your login session has expired. Please login again."
      );

      return;
    }


    // -----------------------------------------------------
    // VALIDATE LATITUDE / LONGITUDE
    // -----------------------------------------------------

    if (
      form.latitude === "" ||
      form.longitude === ""
    ) {

      setError(
        "Please use 'Use My Current Location' or enter latitude and longitude."
      );

      return;
    }


    // -----------------------------------------------------
    // CONVERT COORDINATES
    // -----------------------------------------------------

    const latitude =
      Number(form.latitude);

    const longitude =
      Number(form.longitude);


    // -----------------------------------------------------
    // VALIDATE COORDINATES
    // -----------------------------------------------------

    if (
      !Number.isFinite(latitude) ||
      !Number.isFinite(longitude)
    ) {

      setError(
        "Latitude and longitude must be valid numbers."
      );

      return;
    }


    if (
      latitude < -90 ||
      latitude > 90
    ) {

      setError(
        "Latitude must be between -90 and 90."
      );

      return;
    }


    if (
      longitude < -180 ||
      longitude > 180
    ) {

      setError(
        "Longitude must be between -180 and 180."
      );

      return;
    }


    // -----------------------------------------------------
    // VALIDATE ADDRESS
    // -----------------------------------------------------

    if (!form.address.trim()) {

      setError(
        "Please enter your delivery address."
      );

      return;
    }


    // -----------------------------------------------------
    // VALIDATE CITY
    // -----------------------------------------------------

    if (!form.city.trim()) {

      setError(
        "Please enter your city."
      );

      return;
    }


    // -----------------------------------------------------
    // VALIDATE STATE
    // -----------------------------------------------------

    if (!form.state.trim()) {

      setError(
        "Please enter your state."
      );

      return;
    }


    // -----------------------------------------------------
    // VALIDATE PINCODE
    // -----------------------------------------------------

    const pincode =
      form.pincode.trim();


    if (!pincode) {

      setError(
        "Please enter your PIN code."
      );

      return;
    }


    if (!/^\d{6}$/.test(pincode)) {

      setError(
        "Please enter a valid 6-digit PIN code."
      );

      return;
    }


    setSaving(true);


    // =====================================================
    // SEND TO BACKEND
    // =====================================================

    try {

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

            latitude:

              latitude,

            longitude:

              longitude,

            address:

              form.address.trim(),

            city:

              form.city.trim(),

            state:

              form.state.trim(),

            pincode:

              pincode,

          }),

        }
      );


      // ---------------------------------------------------
      // READ RESPONSE SAFELY
      // ---------------------------------------------------

      let data;

      try {

        data =
          await response.json();

      } catch {

        throw new Error(
          `Invalid server response. HTTP ${response.status}`
        );

      }


      // ---------------------------------------------------
      // CHECK RESPONSE
      // ---------------------------------------------------

      if (!response.ok) {

        throw new Error(
          data.message ||
          "Failed to save delivery location"
        );

      }


      // ===================================================
      // UPDATE STORED USER
      // ===================================================

      const currentUser =
        getUser();


      if (
        currentUser &&
        data.location
      ) {

        const updatedUser = {

          ...currentUser,

          latitude:
            data.location.latitude,

          longitude:
            data.location.longitude,

          address:
            data.location.address,

          city:
            data.location.city,

          state:
            data.location.state,

          pincode:
            data.location.pincode,

        };


        // IMPORTANT:
        // Reuse the existing token.
        // Do NOT declare another const token here.

        saveAuth(
          token,
          updatedUser
        );

      }


      // ===================================================
      // SUCCESS
      // ===================================================

      setMessage(
        "Delivery location saved successfully."
      );


      // ---------------------------------------------------
      // UPDATE FORM WITH SERVER DATA
      // ---------------------------------------------------

      if (data.location) {

        setForm({

          latitude:
            data.location.latitude ?? "",

          longitude:
            data.location.longitude ?? "",

          address:
            data.location.address ?? "",

          city:
            data.location.city ?? "",

          state:
            data.location.state ?? "",

          pincode:
            data.location.pincode ?? "",

        });

      }


      // ---------------------------------------------------
      // CALLBACK
      // ---------------------------------------------------

      if (onSaved) {

        onSaved(
          data.location
        );

      }

    } catch (err) {

      console.error(
        "Save location error:",
        err
      );


      setError(
        err.message ||
        "Failed to save delivery location"
      );

    } finally {

      setSaving(false);

    }

  }


  // =======================================================
  // LOADING SCREEN
  // =======================================================

  if (loading) {

    return (

      <main
        style={{
          maxWidth:
            "700px",

          margin:
            "0 auto",

          padding:
            "30px 20px",

          textAlign:
            "center",
        }}
      >

        <h2>
          Loading delivery address...
        </h2>

      </main>

    );

  }


  // =======================================================
  // PAGE
  // =======================================================

  return (

    <main
      style={{
        maxWidth:
          "800px",

        margin:
          "0 auto",

        padding:
          "25px 20px",
      }}
    >

      <div
        style={{
          background:
            "#ffffff",

          borderRadius:
            "16px",

          padding:
            "30px",

          boxShadow:
            "0 4px 20px rgba(0,0,0,0.06)",
        }}
      >

        {/* =================================================
            HEADER
        ================================================= */}

        <div
          style={{
            display:
              "flex",

            alignItems:
              "center",

            gap:
              "15px",

            marginBottom:
              "25px",
          }}
        >

          <button
            type="button"

            onClick={onBack}

            style={{
              border:
                "none",

              background:
                "#f3f4f6",

              width:
                "42px",

              height:
                "42px",

              borderRadius:
                "10px",

              cursor:
                "pointer",

              fontSize:
                "20px",
            }}
          >
            ←
          </button>


          <div>

            <h2
              style={{
                margin:
                  0,

                color:
                  "#111827",
              }}
            >
              Delivery Address
            </h2>


            <p
              style={{
                margin:
                  "5px 0 0",

                color:
                  "#6b7280",
              }}
            >
              Add your location for easy delivery
            </p>

          </div>

        </div>


        {/* =================================================
            SUCCESS MESSAGE
        ================================================= */}

        {message && (

          <div
            style={{
              background:
                "#ecfdf5",

              border:
                "1px solid #a7f3d0",

              color:
                "#065f46",

              padding:
                "14px",

              borderRadius:
                "10px",

              marginBottom:
                "20px",
            }}
          >

            ✓ {message}

          </div>

        )}


        {/* =================================================
            ERROR MESSAGE
        ================================================= */}

        {error && (

          <div
            style={{
              background:
                "#fef2f2",

              border:
                "1px solid #fecaca",

              color:
                "#991b1b",

              padding:
                "14px",

              borderRadius:
                "10px",

              marginBottom:
                "20px",
            }}
          >

            {error}

          </div>

        )}


        {/* =================================================
            CURRENT LOCATION
        ================================================= */}

        <button
          type="button"

          onClick={
            getCurrentLocation
          }

          disabled={
            gettingLocation
          }

          style={{
            width:
              "100%",

            border:
              "none",

            background:
              "#2563eb",

            color:
              "#ffffff",

            padding:
              "14px",

            borderRadius:
              "10px",

            cursor:
              gettingLocation
                ? "not-allowed"
                : "pointer",

            fontWeight:
              "600",

            fontSize:
              "15px",

            marginBottom:
              "25px",

            opacity:
              gettingLocation
                ? 0.7
                : 1,
          }}
        >

          {gettingLocation

            ? "📍 Detecting Location..."

            : "📍 Use My Current Location"

          }

        </button>


        {/* =================================================
            FORM
        ================================================= */}

        <form
          onSubmit={
            handleSave
          }
        >

          {/* =================================================
              ADDRESS
          ================================================= */}

          <label
            style={{
              display:
                "block",

              fontWeight:
                "600",

              marginBottom:
                "7px",

              color:
                "#374151",
            }}
          >
            Delivery Address
          </label>


          <textarea
            name="address"

            value={
              form.address
            }

            onChange={
              handleChange
            }

            placeholder=
              "House no., street, locality"

            rows={4}

            style={{
              width:
                "100%",

              boxSizing:
                "border-box",

              padding:
                "12px",

              border:
                "1px solid #d1d5db",

              borderRadius:
                "10px",

              resize:
                "vertical",

              marginBottom:
                "18px",

              fontSize:
                "15px",
            }}
          />


          {/* =================================================
              CITY
          ================================================= */}

          <label
            style={{
              display:
                "block",

              fontWeight:
                "600",

              marginBottom:
                "7px",

              color:
                "#374151",
            }}
          >
            City
          </label>


          <input
            type="text"

            name="city"

            value={
              form.city
            }

            onChange={
              handleChange
            }

            placeholder=
              "City"

            style={{
              width:
                "100%",

              boxSizing:
                "border-box",

              padding:
                "12px",

              border:
                "1px solid #d1d5db",

              borderRadius:
                "10px",

              marginBottom:
                "18px",

              fontSize:
                "15px",
            }}
          />


          {/* =================================================
              STATE
          ================================================= */}

          <label
            style={{
              display:
                "block",

              fontWeight:
                "600",

              marginBottom:
                "7px",

              color:
                "#374151",
            }}
          >
            State
          </label>


          <input
            type="text"

            name="state"

            value={
              form.state
            }

            onChange={
              handleChange
            }

            placeholder=
              "State"

            style={{
              width:
                "100%",

              boxSizing:
                "border-box",

              padding:
                "12px",

              border:
                "1px solid #d1d5db",

              borderRadius:
                "10px",

              marginBottom:
                "18px",

              fontSize:
                "15px",
            }}
          />


          {/* =================================================
              PIN CODE
          ================================================= */}

          <label
            style={{
              display:
                "block",

              fontWeight:
                "600",

              marginBottom:
                "7px",

              color:
                "#374151",
            }}
          >
            PIN Code
          </label>


          <input
            type="text"

            name="pincode"

            value={
              form.pincode
            }

            onChange={
              handleChange
            }

            placeholder=
              "6-digit PIN code"

            maxLength={6}

            inputMode=
              "numeric"

            style={{
              width:
                "100%",

              boxSizing:
                "border-box",

              padding:
                "12px",

              border:
                "1px solid #d1d5db",

              borderRadius:
                "10px",

              marginBottom:
                "18px",

              fontSize:
                "15px",
            }}
          />


          {/* =================================================
              COORDINATES
          ================================================= */}

          <div
            style={{
              background:
                "#f9fafb",

              borderRadius:
                "12px",

              padding:
                "15px",

              marginBottom:
                "20px",
            }}
          >

            <h3
              style={{
                marginTop:
                  0,

                color:
                  "#374151",

                fontSize:
                  "16px",
              }}
            >
              📍 Location Coordinates
            </h3>


            <p
              style={{
                margin:
                  "6px 0",

                fontSize:
                  "14px",

                color:
                  "#6b7280",
              }}
            >
              Latitude:{" "}

              {form.latitude ||
                "Not selected"}

            </p>


            <p
              style={{
                margin:
                  "6px 0",

                fontSize:
                  "14px",

                color:
                  "#6b7280",
              }}
            >
              Longitude:{" "}

              {form.longitude ||
                "Not selected"}

            </p>

          </div>


          {/* =================================================
              SAVE
          ================================================= */}

          <button
            type="submit"

            disabled={
              saving
            }

            style={{
              width:
                "100%",

              border:
                "none",

              background:
                "#111827",

              color:
                "#ffffff",

              padding:
                "14px",

              borderRadius:
                "10px",

              cursor:
                saving
                  ? "not-allowed"
                  : "pointer",

              fontWeight:
                "700",

              fontSize:
                "16px",

              opacity:
                saving
                  ? 0.7
                  : 1,
            }}
          >

            {saving

              ? "Saving Location..."

              : "Save Delivery Address"

            }

          </button>

        </form>

      </div>

    </main>

  );

}


export default Location;
