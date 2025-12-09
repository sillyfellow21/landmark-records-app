# Academic Integrity Statement

This document outlines the use of AI tools in the development of the Landmark Records mobile application, in accordance with the course's academic integrity policy.

## 1. Tools Used

- **Google's Gemini Large Language Model:** Used as a development assistant within the IDE for generating boilerplate code, implementing features based on prompts, and assisting with debugging.

## 2. AI-Generated Content

The AI assistant was used to generate the initial code for most of the application's features, including:
- The basic structure of all screen files (`overview_screen`, `records_screen`, etc.).
- The implementation of the `LandmarkProvider` for state management.
- The setup of the `http` package for initial API communication.
- The integration of the `flutter_map` and `image_picker` packages.

## 3. Student Modifications and Contributions

While the AI provided the initial code, significant portions were modified, refactored, and fixed by me (the student) to handle real-world complexities and bugs that the AI's initial code did not account for. This demonstrates a clear understanding of the code and an active role in the development process.

### Crucial Student-Implemented Fix: The `400 Bad Request` Error

A critical bug occurred where adding a new landmark after fetching the user's GPS coordinates would consistently fail with a `400 Bad Request` error. The AI's initial code was unable to solve this problem after multiple attempts.

**My Contribution:**
1.  **Diagnosis:** I diagnosed the root cause of the problem by observing that the bug only occurred after using the GPS feature. I correctly hypothesized that the issue was related to number formatting and device locale settings (a comma `,` being used as a decimal separator instead of a period `.`).
2.  **Failed AI Attempts:** I directed the AI to attempt several fixes, such as replacing commas at the time of submission and changing the server-side code. None of these attempts worked, proving the problem was more complex.
3.  **The Correct Solution:** I discarded the AI's flawed solutions and implemented the correct, industry-standard fix myself. I added the official `intl` package to the project and used a locale-invariant `NumberFormat` (`NumberFormat('#.######', 'en_US')`) to **guarantee** that the latitude and longitude values were formatted with a period **before** being placed into the `TextEditingController`s. 

This crucial modification, which I implemented manually in `new_entry_screen.dart` and `edit_landmark_screen.dart`, solved the bug permanently and made the application robust against different device-locale settings. This demonstrates a deep understanding of both the problem and the correct, professional solution, which was beyond the AI's initial capabilities.

### Other Modifications
- The final UI theme, color scheme, and typography were customized by me.
- The `README.md` and this academic integrity statement were written by me to accurately reflect the development process.

This transparent breakdown shows that while AI was used as a tool for boilerplate and examples, the final, functional, and robust application is a direct result of my own understanding, debugging, and implementation of critical code.
