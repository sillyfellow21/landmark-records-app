# API Documentation and Development Challenges

## Overview

This document provides comprehensive documentation for the "Landmark Records" Flutter application. The application is designed to manage and visualize geographic landmarks in Bangladesh by interacting with a remote RESTful API. It allows users to create, read, update, and delete landmark entries, each containing a title, geographic coordinates, and an associated image.

## API Configuration

The application communicates with a RESTful API hosted at **`https://labs.anontech.info/cse489/t3/api.php`**. This single endpoint serves as the gateway for all CRUD (Create, Read, Update, Delete) operations, differentiating tasks based on the HTTP method of the incoming request. The API processes `application/json`, `x-www-form-urlencoded`, and `multipart/form-data` content types depending on the operation.

## Core Functionality

*   **Read (GET):** Retrieves all existing landmarks from the server as a JSON array. The app parses this data into a list of `Landmark` objects for display in the map and record list views.
*   **Create (POST):** Submits a new landmark to the server. This operation uses a `multipart/form-data` request to handle the upload of an image file alongside the landmark's title and coordinates. To optimize performance and ensure server compatibility, images are automatically resized to a maximum of 800x600 pixels before being sent.
*   **Update (PUT / POST):** The app supports updating a landmark's textual data (title, coordinates) via a `PUT` request with `x-www-form-urlencoded` data. If an image is being updated, the app intelligently switches to a `POST` request with `multipart/form-data` to handle the file upload, a common workaround for servers with limited `PUT` functionality.
*   **Delete (DELETE):** A `DELETE` request is sent with the landmark's `id` as a query parameter to permanently remove the record from the server. This operation is fully functional.

## Technical Architecture

The application is built using a clean, provider-based architecture to ensure a clear separation of concerns.

*   **State Management:** Uses the **`Provider`** package, a Flutter Favorite, for state management. A central `LandmarkProvider` class acts as the single source of truth for the UI, managing the application state (e.g., `loading`, `loaded`, `error`) and the list of landmarks.
*   **Repository Pattern:** A `LandmarkRepository` handles all communication with the REST API and the local database. This isolates the data layer from the UI and state management logic.
*   **Model:** A `Landmark` data model is used for robust JSON serialization, safely parsing data from the API and converting it into strongly-typed Dart objects.
*   **Offline Caching (Bonus Feature):** The app implements offline caching using **`sqflite`**. When landmarks are successfully fetched from the API, they are saved to a local SQLite database. If the user opens the app without an internet connection, the app gracefully falls back to displaying the data from the last successful fetch.
*   **Location & Permissions:** Integrates the `geolocator` and `permission_handler` packages for robust GPS functionality. It properly requests location permission at runtime before automatically populating coordinate fields for new entries.

## Major Development Challenges

Several significant challenges were encountered and overcome during development, requiring deep debugging and the implementation of robust, industry-standard solutions.

1.  **Stubborn `400 Bad Request` Error During File Upload:**
    *   **The Challenge:** A persistent and critical bug occurred where creating a new landmark would consistently fail with a `400 Bad Request` error. Initial debugging suggested a number formatting issue related to device locales (comma vs. period decimal separators). However, simple string replacement fixes proved insufficient.
    *   **The Solution:** After extensive debugging, the root cause was identified as a server-side validation issue with the multipart file upload. The server was rejecting the request because the `http` package was not explicitly providing the file's `Content-Type` and `filename` in a way the server expected. The definitive solution was to manually construct the `http.MultipartFile` at a lower level: the image file was first read into raw bytes, and then sent using `http.MultipartFile.fromBytes`, where both the `filename` (with a `.jpg` extension) and the `contentType` (`MediaType('image', 'jpeg')`) were explicitly defined. This created a "perfect" request that satisfied the server's strict validation, permanently fixing the bug.

2.  **UI State Synchronization:**
    *   **The Challenge:** After successfully adding or deleting a landmark, the UI would not update to reflect the change. The new landmark would not appear, or the deleted landmark would remain visible until the app was restarted.
    *   **The Solution:** This was a classic state management failure. The initial "fire-and-forget" calls to the provider were incorrect. The solution was to refactor the `addLandmark`, `updateLandmark`, and `deleteLandmark` methods in the `LandmarkProvider`. Now, after any of these operations successfully completes, the provider immediately calls `fetchLandmarks(isRefresh: true)`. This forces a re-synchronization with the server (the single source of truth), ensuring the UI always displays the most current data.

## Dependencies and Performance

*   **Key Dependencies:** `provider` (State Management), `http` (Network), `flutter_map` (Maps), `geolocator` & `permission_handler` (Location/Permissions), `image_picker` (Image Selection), `sqflite` (Offline Caching), `cached_network_image` (Efficient Image Loading).
*   **Performance:** Performance is optimized through several mechanisms: `CachedNetworkImage` reduces network usage for previously loaded images, the `IndexedStack` in `main.dart` preserves the state of each tab to avoid rebuilding screens on every navigation, and image resizing prevents large uploads from blocking the UI.

## Conclusion

The "Landmark Records" application successfully meets all core requirements. It demonstrates robust interaction with a REST API for full CRUD functionality, seamless GPS and permission handling, efficient state management, and a polished user interface. Despite initial challenges with file uploads and state synchronization, the final implementation is stable, reliable, and adheres to professional software architecture principles, including the implementation of the optional offline caching feature.
