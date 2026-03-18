# DELOX

A minimalist, high-fidelity task management ecosystem combining productivity with premium design.

DELOX is a high-performance task management application built using Flutter. It is designed for users who value both efficiency and aesthetics, delivering a seamless cross-platform experience with a local-first architecture for speed, reliability, and offline capability.

---

## Features

* Minimalist and premium UI/UX
* Dynamic Light and Dark mode
* Smooth animations and optimized performance
* Cross-platform support (Android and iOS)
* Local-first data storage (offline ready)
* Smart reminders with precise scheduling
* Secure authentication (Google and Email)

---

## Architecture Overview

DELOX follows a clean, reactive architecture designed for scalability and maintainability.

### State Management

* Powered by Provider
* Efficient UI updates
* Decoupled business logic and UI

### Local-First System

* Built with SQLite (sqflite)
* Fully offline functionality
* Instant data access

### Notification Engine

* Built using flutter_local_notifications and timezone
* Accurate, location-aware reminders

---

## Database Design

DELOX uses a structured relational database for performance and reliability.

### Tables

* tasks → title, description, status, due date
* categories → color-based grouping
* user_prefs → theme and settings

### Why SQLite?

* Fast querying and sorting
* Reliable persistent storage
* Offline-first capability
* Maintains strong data relationships

---

## Design System

* Typography: Google Fonts (Poppins / Outfit)
* Theme: Premium Lavender palette
* UX Focus: Simplicity and clarity

---

## Tech Stack

* Framework: Flutter 3.x
* Language: Dart 3.x
* State Management: Provider
* Database: SQLite (sqflite)
* Authentication: Google Sign-In / Email
* Notifications: Flutter Local Notifications


## Purpose

This is my first Flutter project, built for personal productivity and to improve my skills in mobile development, UI/UX design, and app architecture.

---

Prabath Thilina

---

