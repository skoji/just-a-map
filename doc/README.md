# Documentation Index

This directory contains technical documentation for the Just a Map project.

## Documentation

### 1. [Stage 1 Implementation Guide](stage1-implementation-guide.md)
Detailed explanation of the basic map display functionality implemented in Stage 1, at the code level.
- Project structure
- Roles of major components
- Location information acquisition flow
- SwiftUI and MapKit integration

### 2. [Stage 2 Implementation Guide](stage2-implementation-guide.md)
Explains the address display and sleep prevention features implemented in Stage 2.
- Development process using TDD
- Reverse geocoding service
- Utilization of async/await
- Sleep prevention implementation

### 3. [Stage 3 Implementation Guide](stage3-implementation-guide.md)
Explains the map controls and display mode switching implemented in Stage 3.
- Zoom control implementation
- Map style switching functionality
- Settings persistence (UserDefaults)
- Utilization of iOS 17 MapKit API

### 4. [iOS Development Fundamentals](ios-development-basics.md)
Summarizes basic knowledge for those new to iOS development.
- SwiftUI basics
- How to use property wrappers
- Asynchronous processing and threads
- Memory management fundamentals

### 5. [Settings Screen and Default Zoom Level Feature](settings-and-default-zoom.md)
Explains the implementation of the settings screen and default zoom level functionality.
- Settings screen implementation (SwiftUI Form)
- Application of default zoom level
- Issues and solutions for maintaining follow mode
- Feature development using TDD

### 6. [Troubleshooting Guide](troubleshooting-guide.md)
Records problems encountered during actual development and their solutions.
- Dealing with build errors
- Resolving runtime errors
- Simulator-specific issues
- Debugging tips

### 7. [xtool Migration Guide](xtool-migration-guide.md)
Explains the migration from Xcode projects to xtool-based SwiftPM workspaces.
- Project structure changes
- Build methods and use of Makefile
- Asset management mechanism
- CI/CD configuration

### 8. [Version Management System](version-management-system.md)
Explains the Git-based automatic version management system.
- Automatic version number generation
- Embedding version information during build
- Design that doesn't pollute Git tracking
- VersionInfo.plist mechanism

### 9. [Altitude Display Feature](altitude-display-feature.md)
Explains the implementation of the feature that displays altitude in real time.
- Altitude data acquisition and processing
- Unit conversion (meters/feet)
- Settings screen toggle functionality
- Error handling and display control
- Quality assurance using TDD

## Reading Order

For those new to iOS development:
1. iOS Development Fundamentals
2. Stage 1 Implementation Guide
3. Stage 2 Implementation Guide
4. Stage 3 Implementation Guide
5. Settings Screen and Default Zoom Level Feature
6. Altitude Display Feature
7. Troubleshooting Guide

For those experienced with iOS development:
1. Stage 1 Implementation Guide
2. Stage 2 Implementation Guide
3. Stage 3 Implementation Guide
4. Settings Screen and Default Zoom Level Feature
5. Altitude Display Feature
6. Troubleshooting Guide (as needed)

## Update History

- 2025-07-06: Initial version created (at Stage 1 completion)
- 2025-07-06: Added Stage 2 documentation (address display and sleep prevention)
- 2025-07-06: Added Stage 3 documentation (map controls and display mode switching)
- 2025-07-07: Added settings screen and default zoom level feature documentation (Issue #12 support)
- 2025-07-10: Added xtool migration guide and version management system documentation (PR #50 support)
- 2025-07-10: Added altitude display feature documentation (Issue #58 support)