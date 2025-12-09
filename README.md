# Landmark Records App

## 1. App Summary

A Flutter application for managing and visualizing landmark records in Bangladesh. The app communicates with a remote REST API to perform CRUD (Create, Read, Update, Delete) operations. It features a multi-tab interface for viewing landmarks on an interactive map, in a scrollable list, and for adding new entries.

This project uses OpenStreetMap for map services and a provider-based state management approach.

## 2. Feature List

- **Interactive Map View:** Displays all landmarks as tappable markers on an OpenStreetMap interface centered on Bangladesh.
- **List-Based View:** Shows all landmarks in a clean, scrollable list.
- **Add New Landmarks:** A dedicated form to add a new landmark, including fields for title, coordinates, and an image.
- **Auto-Fetch GPS Coordinates:** The "New Entry" form can automatically fetch the user's current latitude and longitude.
- **Image Handling:** Supports picking images from the gallery, with local asset fallbacks for default data.
- **Edit and Delete:** Users can update landmark details or delete records entirely through intuitive UI actions (swiping on the list, buttons on the map).
- **State Management:** Uses the `provider` package to efficiently manage and share landmark data across different screens.
- **Local Fallback Data:** If the remote API is empty or unreachable, the app loads a default set of well-known Bangladeshi landmarks to ensure a good user experience.

## 3. Setup Instructions

1.  **Ensure Flutter is installed** on your system.
2.  **Clone the repository.**
3.  **Create and add local image assets:**
    - In the project root, create a folder path: `assets/images/`.
    - Add your image files (e.g., `sajek_valley.jpg`) to this directory. The app will look for `.jpg` or `.jpeg` files.
4.  **Install dependencies** by running the following command in your terminal:
    ```sh
    flutter pub get
    ```
5.  **Run the app** on a connected device or emulator:
    ```sh
    flutter run
    ```

## 4. Known Limitations

- The app currently does not support user authentication. All users share the same landmark data.
- Image updates are not supported in the edit screen to simplify the API interaction. Only textual data can be modified.
- The app relies on a public, unauthenticated API, which is not suitable for production use.
- Offline caching for API-fetched data is not implemented. The default landmarks, however, are available offline.

---

## Changelog
- Added final documentation and readme update.
