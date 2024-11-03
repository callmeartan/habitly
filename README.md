# Habitly - Flutter Habit Tracking App

Habitly is a modern, feature-rich habit tracking application built with Flutter. It helps users build and maintain good habits through an intuitive interface, reminders, and progress tracking.

## Features

### Core Features
- ✨ Create and manage daily, weekly, or monthly habits
- 📊 Track progress with visual indicators
- 🔔 Custom reminders and notifications
- 🌓 Dark and light theme support
- 📈 Progress statistics and streaks
- 🎯 Category-based habit organization

### Technical Features
- 💾 Local data persistence
- 🔄 State management with Provider
- 📱 Responsive design
- 🎨 Custom animations
- 📋 Form validation
- 🔔 Local notifications

## Getting Started

### Prerequisites
- Flutter (3.x or higher)
- Dart (3.x or higher)
- Android Studio / VS Code
- iOS Simulator / Android Emulator

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

## Project Structure

```
lib/
├── models/
│   └── habit.dart
├── screens/
│   ├── habit_dashboard.dart
│   └── habit_calendar_screen.dart
├── widgets/
│   ├── habit_card.dart
│   └── habit_form.dart
├── services/
│   └── notification_service.dart
├── providers/
│   └── theme_provider.dart
├── repositories/
│   └── habit_repository.dart
└── main.dart
```

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^[version]
  shared_preferences: ^[version]
  flutter_local_notifications: ^[version]
  google_fonts: ^[version]
  table_calendar: ^[version]
  timezone: ^[version]
```

## Features in Detail

### Habit Management
- Create new habits with customizable names and categories
- Set frequency (daily, weekly, monthly)
- Track completion with progress indicators
- Delete or edit existing habits

### Reminder System
- Set custom reminder times for each habit
- Receive local notifications
- Customize notification messages
- Enable/disable reminders per habit

### Theme Support
- Toggle between light and dark themes
- Persistent theme preference
- Custom color schemes for both themes

### Progress Tracking
- Visual progress indicators
- Streak counting
- Completion statistics
- Category-based progress


## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

## Acknowledgments

- Flutter team for the amazing framework
- All contributors who participate in this project

## Contact

Artanahmadi@icloud.com

Project Link: [https://github.com/callmeartan/habitly](https://github.com/callmeartan/habitly)
