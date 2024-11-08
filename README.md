# Habitly - Flutter Habit Tracking App

![Flutter Version](https://img.shields.io/badge/Flutter-3.x-blue.svg)
![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-green.svg)
[![GitHub stars](https://img.shields.io/github/stars/callmeartan/habitly.svg)](https://github.com/callmeartan/habitly/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/callmeartan/habitly.svg)](https://github.com/callmeartan/habitly/network)

Habitly is a modern, feature-rich habit tracking application built with Flutter. It helps users build and maintain good habits through an intuitive interface, detailed progress tracking, and smart reminders.

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

## 🎯 Features in Detail

### Habit Management
- Create habits with custom names and categories
- Set frequency (daily, weekly, monthly)
- Track completion with progress indicators
- Manage reminders for each habit

### Calendar Tracking
- Monthly calendar view
- Visual completion indicators
- Streak tracking
- Statistical overview
- Historical data viewing

### Theme Support
- Dynamic theme switching
- Dark/Light mode
- Persistent theme preferences
- Custom color schemes

## 🛠 Technical Features
- Local data persistence using SharedPreferences
- State management with Provider
- Responsive design
- Custom animations
- Form validation
- Local notifications
- Date handling and normalization
- Streak calculations

## 🤝 Contributing

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

Give a ⭐️ if this project helped you!
