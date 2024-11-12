# Habitly - Flutter Habit Tracking App


Habitly is a modern, feature-rich habit-tracking application built with Flutter. It helps users build and maintain good habits through an intuitive interface, detailed progress tracking, and smart reminders.



## ✨ Features

### Core Features
- 📱 Create and manage daily, weekly, or monthly habits
- 📊 Track progress with visual indicators
- 📅 Calendar view for habit completion tracking
- 🔥 Streak tracking and statistics
- 🔔 Smart reminders and notifications
- 🌓 Dark and light theme support
- 🎯 Category-based habit organization

### Calendar & Statistics
- Visual calendar with completion markers
- Current and best streak tracking
- Total completion days
- Progress statistics
- Daily completion indicators

### Smart Notifications
- Custom reminder times per habit
- Daily notification scheduling
- Persistent notification preferences
- Flexible reminder management

## 🎯 Key Components

### Models
```dart
// Example of Habit model structure
class Habit {
  final int id;
  String name;
  String category;
  int streak;
  String frequency;
  bool completedToday;
  double progress;
  DateTime? reminderTime;
  List<DateTime> completionDates;
  
  // ... methods for streak calculation and date handling
}
```

### Services
```dart
// Example of Notification Service
class NotificationService {
  Future<void> scheduleHabitReminder({
    required int id,
    required String habitName,
    required DateTime scheduledTime,
  }) async {
    // Implementation for scheduling notifications
  }
}
```

## 🚀 Getting Started

### Prerequisites
- Flutter 3.x or higher
- Dart 3.x or higher
- iOS 12.0+ / Android 5.0+
- Xcode for iOS development
- Android Studio for Android development

### Installation

1. Clone the repository
```bash
git clone https://github.com/callmeartan/habitly.git
```

2. Navigate to project directory
```bash
cd habitly
```

3. Install dependencies
```bash
flutter pub get
```

4. Run the app
```bash
flutter run
```

## 📁 Project Structure

```
lib/
├── models/
│   └── habit.dart          // Habit data model with completion tracking
├── screens/
│   ├── habit_dashboard.dart    // Main dashboard UI
│   └── habit_calendar_screen.dart  // Calendar and statistics view
├── widgets/
│   ├── habit_card.dart     // Individual habit display
│   └── habit_form.dart     // Habit creation/editing form
├── services/
│   └── notification_service.dart  // Local notifications handler
├── providers/
│   └── theme_provider.dart    // Theme management
├── repositories/
│   └── habit_repository.dart  // Data persistence
└── main.dart
```

## 🛠 Technical Features

### State Management
- Provider for state management
- Efficient UI updates
- Persistent storage

### UI/UX
- Custom animations
- Responsive design
- Form validation
- Interactive calendar
- Progress indicators

### Data Handling
- Local persistence with SharedPreferences
- JSON serialization
- Date normalization
- Streak calculations

## 🔜 Roadmap

- [ ] Cloud synchronization
- [ ] Social sharing features
- [ ] Advanced Analytics
- [ ] Widget support
- [ ] Custom themes
- [ ] Data export/import

## 🤝 Contributing

Contributions make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📫 Contact

Artan - [GitHub Profile](https://github.com/callmeartan)

Project Link: [https://github.com/callmeartan/habitly](https://github.com/callmeartan/habitly)

## 🌟 Show your support

If you found this project helpful, please consider giving it a ⭐️!

<p align="center">
Made with ❤️ by <a href="https://github.com/callmeartan">Artan</a>
</p>
