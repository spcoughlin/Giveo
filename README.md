# Giveo

# Giveo - Swipe. Match. Donate.

Giveo is an innovative hackathon project built for **HackNYU2025**. The app reimagines charitable giving by letting you swipe through a curated selection of charities and matching you with those that align with your personal preferences. Whether you're looking to support education, healthcare, the environment, or any other cause, Giveo makes donating easy and engaging.

---

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Installation](#installation)
  - [Backend Setup (Python + FastAPI)](#backend-setup-python--fastapi)
  - [Frontend Setup (Swift)](#frontend-setup-swift)
- [Usage](#usage)
- [Contributing](#contributing)
- [Acknowledgements](#acknowledgements)
- [License](#license)

---

## Features

- **Swipe Interface**: Explore a list of charities with an intuitive, swipe-based UI.
- **Personalized Matching**: Get matched with charities based on your interests and preferences.
- **Seamless Donations**: Easily donate to your selected charities through integrated payment gateways.
- **Real-Time Updates**: Powered by FastAPI, ensuring fast and reliable API responses.

---

## Tech Stack

- **Backend**: Python with [FastAPI](https://fastapi.tiangolo.com/)
- **Frontend**: Swift (iOS)
- **Server**: Uvicorn for running the FastAPI application
- *(Optional: Add any additional services or databases if applicable)*

---

## Architecture

Giveo is designed with a clear separation between the frontend and backend:

- **Backend**: A robust Python service built using FastAPI handles all core functionalities such as user management, charity data handling, and matching logic. It exposes RESTful APIs that the frontend consumes.
  
- **Frontend**: Developed in Swift, the iOS app provides a sleek and responsive swipe-based interface for users to browse charities and manage their donation preferences.

---

## Installation

Follow the instructions below to set up the project locally.

### Backend Setup (Python + FastAPI)

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/yourusername/Giveo.git
   cd Giveo/backend
   ```

2. **Create and Activate a Virtual Environment:**

   ```bash
   python3 -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install Dependencies:**

   ```bash
   pip install -r requirements.txt
   ```

4. **Run the FastAPI Server:**

   ```bash
   uvicorn main:app --reload
   ```

   The backend should now be running at [http://127.0.0.1:8000](http://127.0.0.1:8000).

5. **Access API Documentation:**

   - **Swagger UI:** [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)
   - **Redoc:** [http://127.0.0.1:8000/redoc](http://127.0.0.1:8000/redoc)

### Frontend Setup (Swift)

1. **Open the Project in Xcode:**

   Navigate to the `Giveo/frontend` directory and open the `.xcodeproj` or `.xcworkspace` file.

2. **Configure the Project:**

   - Make sure your deployment target is set correctly (simulator or device).
   - Update the backend URL in your Swift code if necessary to match your local server (e.g., `http://127.0.0.1:8000`).

3. **Build and Run the App:**

   - Select your desired simulator or connect your iOS device.
   - Press the **Run** button in Xcode to build and launch the app.

---

## Usage

1. **Sign Up / Log In:**

   Create an account or log in to start exploring charity profiles.

2. **Swipe Through Charities:**

   - **Swipe Right:** Indicate interest in a charity.
   - **Swipe Left:** Pass on a charity.
   - Your swiping behavior helps the app curate and match charities that best align with your interests.

3. **Donate:**

   Once matched with a charity, proceed to donate directly through the app using our integrated donation process.

---

## Contributing

Contributions to Giveo are welcome! If you’d like to contribute, please follow these steps:

1. **Fork the Repository**

2. **Create a New Branch:**

   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Commit Your Changes:**

   ```bash
   git commit -m "Add feature: description of your changes"
   ```

4. **Push to Your Branch:**

   ```bash
   git push origin feature/your-feature-name
   ```

5. **Open a Pull Request:**

   Provide a detailed description of your changes and the motivation behind them.

---

## Acknowledgements

- **HackNYU2025:** A huge thank you to the organizers of HackNYU2025 for providing a platform to innovate.
- **Our Team:** [List team member names or GitHub handles]
- **Open Source Community:** Special thanks to the developers behind FastAPI, Swift, and all the libraries and tools used in this project.

---

## License

This project is licensed under the [MIT License](LICENSE).

---

*Happy Swiping & Donating!*
