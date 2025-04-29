# GangApp - Flutter Mobile Application

A Flutter mobile application with user authentication and profile management.

## Features

- User login and authentication
- User registration
- Profile viewing and editing
- Upload profile picture and background image
- Update personal information
- View other user profiles
- Password reset functionality

## Installation and Setup

1. Make sure you have Flutter installed on your machine. If not, follow the instructions at [flutter.dev](https://flutter.dev/docs/get-started/install).

2. Clone the repository:
```
git clone <repository-url>
cd gangapp
```

3. Install dependencies:
```
flutter pub get
```

4. Run the app:
```
flutter run
```

## Application Architecture

The app follows an MVC (Model-View-Controller) architecture:

- **Model**: Represented by API service that interacts with the backend
- **View**: UI components in the lib/views directory
- **Controller**: Business logic components in the lib/controllers directory

### Key Components

- **ApiService**: Centralizes all API calls with proper error handling
- **AuthController**: Manages authentication-related business logic
- **ProfileController**: Manages profile-related business logic
- **LoginPage**: UI for user authentication
- **SignUpPage**: UI for user registration
- **ProfilePage**: UI for viewing and editing profiles (both user's own and others')

## Controller Overview

### AuthController
Manages all authentication-related operations:
- User login
- User registration
- Password reset requests
- Password change
- Logout

### ProfileController
Manages all profile-related operations:
- Fetching user profiles (current user and other users)
- Updating profile information
- Uploading profile pictures
- Handling profile visibility

## API Endpoints

### Authentication
- **Login**: `POST /api/auth/login/`
- **Register**: `POST /api/auth/register/`
- **Logout**: `POST /api/auth/logout/`
- **Change Password**: `POST /api/auth/change-password/`
- **Reset Password Email**: `POST /api/auth/reset-password-email/`
- **Reset Password**: `POST /api/auth/reset-password/<str:uid>/`
- **Token**: `POST /api/auth/token/`
- **Refresh Token**: `POST /api/auth/token/refresh/`

### Profile
- **Current User Profile**: `GET /api/profiles/me/`
- **Update Profile**: `PATCH /api/profiles/me/update/`
- **Public Profile**: `GET /api/profiles/users/<str:username>/`
- **Upload File**: `POST /api/profiles/upload/`

## Dependencies

- **http**: For API requests
- **shared_preferences**: For token storage
- **image_picker**: For selecting images from gallery or camera
- **intl**: For date formatting
- **google_fonts**: For text styling
- **get**: For state management

## Notes

- The backend should be running at http://127.0.0.1:8000
- Make sure to update the API URLs for production deployment
- Profile images have a max size of 5MB
- Background images have a max size of 10MB
