# Task Management App

A beautiful and intuitive Flutter application for managing your daily tasks, connected to a Node.js/Express backend with MongoDB Atlas.
<img width="1920" height="1080" alt="file cover - 1" src="https://github.com/user-attachments/assets/7ebedae7-94fa-4960-8a5c-973f4733118d" />



## Features

- 📅 View tasks by date with intuitive date picker
- 🔍 Search functionality to quickly find tasks
- ✅ Mark tasks as complete with checkbox toggle
- ✏️ Edit existing tasks
- 🗑️ Delete tasks
- 📱 Responsive design for all screen sizes
- 🎨 Attractive UI with amber color scheme
- 📱 Cross-platform (iOS & Android)

## Technologies Used

- Flutter (Dart)
- [tasks-api](https://github.com/viraalfita/tasks-api) (Custom Node.js/Express backend)
- HTTP for API communication
- Provider for state management (if used)
- Intl for date/time formatting

## API Integration

This app connects to a custom REST API built with Node.js and Express. The API repository can be found at:
[https://github.com/viraalfita/tasks-api](https://github.com/viraalfita/tasks-api)

The app uses the following API endpoints:
- `GET /api/tasks` - Retrieve all tasks
- `POST /api/tasks` - Create new task
- `PUT /api/tasks/:id` - Update existing task
- `DELETE /api/tasks/:id` - Delete task

## Installation

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio/Xcode (for emulator/simulator)
- Physical device (optional)

### Steps
1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/task-app-flutter.git
   cd task-app-flutter
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure API base URL:
   - Open `lib/services/api.dart`
   - Update the `baseUrl` to point to your API server

4. Run the app:
   ```bash
   flutter run
   ```

## App Structure

```
lib/
├── main.dart            # Entry point
├── screens/
│   └── home_screen.dart # Main task management screen
├── services/
│   └── api.dart         # API service layer
├── models/              # Data models
└── widgets/             # Reusable widgets
```

## Key Components

### Home Screen (`home_screen.dart`)
- Displays greeting with user avatar
- Horizontal date picker
- Search functionality
- Task list with CRUD operations
- Floating action button for adding new tasks

### API Service (`api.dart`)
- Handles all HTTP requests to backend
- Methods for:
  - Fetching tasks
  - Creating tasks
  - Updating tasks
  - Deleting tasks

## Screenshots

<div align="center">
  <table>
    <tr>
      <td align="center" width="33%">
        <img src="https://github.com/user-attachments/assets/03770d97-2fb9-44b1-a56d-abed23c81f89" alt="Date Picker" width="300"/>
        <br><strong>Date Picker</strong>
      </td>
      <td align="center" width="33%">
        <img src="https://github.com/user-attachments/assets/ee6372bd-e613-420f-b74f-160a42c0d96f" alt="Task List" width="300"/>
        <br><strong>Task List</strong>
      </td>
      <td align="center" width="33%">
        <img src="https://github.com/user-attachments/assets/c161368a-3b04-4deb-b055-033e8a8fe77b" alt="Add Task Dialog" width="300"/>
        <br><strong>Add Task</strong>
      </td>
    </tr>
  </table>
</div>

## Customization


To customize the app:
1. **Colors**: Modify the amber color scheme in `home_screen.dart`
2. **API**: Update API endpoints in `lib/services/api.dart`
3. **UI**: Adjust padding and styling in widget build methods

## Future Improvements

- [ ] Add user authentication
- [ ] Implement task categories
- [ ] Add recurring tasks feature
- [ ] Include push notifications
- [ ] Add dark mode support

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.
