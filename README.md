# Momentum Planner

A beautiful, paper-inspired digital planner for macOS built with SwiftUI.

## Overview

Momentum Planner is a productivity app that combines the aesthetic of paper planners with the power of digital organization. Designed specifically for macOS, it provides an elegant interface for managing your daily tasks, events, and notes.

## Features

- **Multiple Planning Views**
  - Daily view with focus points and action lists
  - Weekly time-block view
  - Monthly calendar overview
  - Yearly planning view
  - Dedicated notes page

- **Smart Organization**
  - Focus Point section for your top priorities (up to 10 items)
  - Action List for comprehensive task management
  - Time-blocking for scheduled events and appointments

- **Search & Navigation**
  - Global search across all entries
  - Quick navigation between dates
  - Calendar popover for viewing upcoming time-blocked events

- **Clean Interface**
  - Warm cream (#FBF8F3) canvas background
  - Minimalist sidebar navigation
  - Contextual toolbar that adapts to your current view

## Tech Stack

- **SwiftUI** - Modern declarative UI framework
- **SwiftData** - Data persistence and management
- **PencilKit** - Future handwriting support (planned)

## Getting Started

1. Open the project in Xcode
2. Build and run on macOS
3. Start planning your day!

## Project Structure

```
Momentum/
├── App/
│   ├── ContentView.swift       # Main container with sidebar
│   └── AplyziaApp.swift        # App entry point
├── Views/
│   ├── DailyView.swift         # Daily planning interface
│   ├── WeeklyView.swift        # Time-block grid
│   ├── MonthlyView.swift       # Calendar overview
│   ├── YearlyView.swift        # Year planning
│   ├── NotesView.swift         # Notes page
│   ├── HomeView.swift          # Landing page
│   └── CalendarPopoverView.swift # Upcoming events
├── Models/
│   ├── Entry.swift             # Core data model
│   ├── Reminder.swift          # Reminder model
│   └── RoutingRecord.swift     # Navigation tracking
└── Services/
    ├── SearchManager.swift     # Search functionality
    └── NotificationService.swift # Reminder notifications
```

## Contributing

This project is currently in active development. Contributions, issues, and feature requests are welcome!

## Authors

- **aplyzia** - Initial work
- **claude** - AI assistant
- **changx02** - Contributor

## License

Copyright © 2026 Aplyzia
