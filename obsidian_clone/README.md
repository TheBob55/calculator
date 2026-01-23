# Obsidian Clone

A fully-featured, cross-platform Obsidian clone built with Flutter. This application provides a markdown-based knowledge management system with bidirectional linking, graph visualization, and all the core features of Obsidian.

## Features

### Core Features ✅
- **Vault Management**: Create and manage multiple vaults (local folders of markdown files)
- **Markdown Editor**: Full-featured markdown editor with live preview and split view
- **Wikilinks**: Internal linking between notes using `[[note]]` syntax
- **Backlinks**: Automatic detection of notes that link to the current note
- **Graph View**: Interactive visualization of note connections and relationships
- **File Explorer**: Hierarchical file browser with search and sorting
- **Full-Text Search**: Search across all notes with highlighting
- **Tags**: Support for `#tags` with automatic extraction
- **Unlinked Mentions**: Find notes that mention a title but don't link to it
- **Multiple Views**: Edit mode, preview mode, and split view
- **Dark/Light Themes**: Full theme support with Material Design 3

### Technical Features
- **Cross-Platform**: Runs on iOS, Android, macOS, Linux, Windows, and Web
- **Local-First**: All data stored locally on device
- **Fast Performance**: Native compilation with Flutter
- **Automatic Backlink Updates**: Links update automatically when notes are renamed
- **Real-time Link Detection**: Automatically extracts wikilinks and tags as you type

## Platform Support

| Platform | Status |
|----------|--------|
| Linux    | ✅ Supported |
| macOS    | ✅ Supported |
| Windows  | ✅ Supported |
| iOS      | ✅ Supported |
| Android  | ✅ Supported |
| Web      | ✅ Supported |

## Getting Started

### Prerequisites
- Flutter SDK 3.38.7 or higher
- Dart SDK 3.10.7 or higher

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd obsidian_clone
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
# For desktop (Linux/macOS/Windows)
flutter run -d linux
flutter run -d macos
flutter run -d windows

# For mobile
flutter run -d ios
flutter run -d android

# For web
flutter run -d chrome
```

### Building for Production

```bash
# Linux
flutter build linux

# macOS
flutter build macos

# Windows
flutter build windows

# iOS
flutter build ios

# Android
flutter build apk

# Web
flutter build web
```

## Project Structure

```
lib/
├── main.dart                 # Application entry point
├── models/                   # Data models
│   ├── note.dart            # Note model
│   ├── vault.dart           # Vault model
│   └── link.dart            # Link model
├── services/                # Business logic
│   ├── vault_service.dart   # Vault management
│   ├── search_service.dart  # Search functionality
│   └── link_service.dart    # Link and backlink processing
├── providers/               # State management
│   ├── vault_provider.dart  # Vault state
│   └── theme_provider.dart  # Theme state
├── screens/                 # UI screens
│   ├── home_screen.dart     # Main application screen
│   ├── vault_selector_screen.dart
│   └── graph_screen.dart    # Graph visualization
└── widgets/                 # Reusable widgets
    ├── file_explorer.dart   # File browser
    ├── markdown_editor.dart # Editor component
    └── backlinks_panel.dart # Backlinks sidebar
```

## Key Dependencies

- **flutter_markdown**: Markdown rendering
- **provider**: State management
- **path_provider**: File system access
- **graphview**: Graph visualization
- **file_picker**: Directory selection
- **shared_preferences**: Settings storage
- **sqflite**: Local database (for future search indexing)

## Usage

### Creating a Vault
1. Launch the application
2. Click "Create New Vault"
3. Enter a vault name
4. The vault will be created in your Documents folder

### Opening an Existing Vault
1. Click "Open Existing Vault"
2. Select a folder containing markdown files
3. The app will index all `.md` files

### Creating Notes
- Click the `+` floating action button
- Or use the "New Note" button in the file explorer
- Enter a note title and start writing

### Linking Notes
Use wikilink syntax: `[[Note Title]]`
- Links are clickable in preview mode
- If a linked note doesn't exist, you can create it with one click
- Backlinks appear automatically in the right sidebar

### Viewing the Graph
- Click the graph icon in the app bar
- Nodes represent notes
- Edges represent wikilinks
- Pinch to zoom, drag to pan

### Search
- Click the search icon in the app bar
- Search by title, content, or tags
- Results show matching context

## Roadmap

### Implemented ✅
- [x] Vault management
- [x] Markdown editor with live preview
- [x] Wikilinks and backlinks
- [x] File explorer
- [x] Search functionality
- [x] Graph view
- [x] Tags support
- [x] Themes (dark/light)
- [x] Split view editing

### Future Enhancements 🚧
- [ ] Canvas (infinite whiteboard)
- [ ] Plugin system
- [ ] Templates
- [ ] Advanced search with regex
- [ ] Note folders and hierarchies
- [ ] Sync between devices
- [ ] PDF export
- [ ] Code syntax highlighting in editor
- [ ] Block references
- [ ] Daily notes
- [ ] Note aliases
- [ ] Starred notes
- [ ] Note history/version control

## Architecture

### State Management
The app uses the Provider pattern for state management:
- **VaultProvider**: Manages current vault, notes list, and file operations
- **ThemeProvider**: Manages theme state (light/dark/system)

### Data Flow
1. User selects a vault → VaultService loads all markdown files
2. Files are parsed into Note models
3. LinkService processes wikilinks and builds backlinks
4. Notes are stored in VaultProvider
5. UI updates reactively via Provider

### File Storage
- Vaults are plain folders on the file system
- Notes are stored as `.md` files
- No proprietary format - fully compatible with any markdown editor
- Metadata (vault list, settings) stored in SharedPreferences

## Contributing

Contributions are welcome! This project implements the core Obsidian features and is open for enhancements.

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on multiple platforms
5. Submit a pull request

## License

This is a demonstration project. See LICENSE file for details.

## Acknowledgments

- Inspired by [Obsidian](https://obsidian.md/)
- Built with [Flutter](https://flutter.dev/)
- Uses Material Design 3

## Screenshots

### Main Editor
The main interface features a three-panel layout:
- Left: File explorer with search and sorting
- Center: Markdown editor with live preview
- Right: Backlinks and outgoing links panel

### Graph View
Interactive force-directed graph showing note connections. Zoom and pan to explore your knowledge base.

### Vault Selector
Clean interface for creating new vaults or opening existing ones.

---

**Note**: This is an Obsidian clone for educational purposes. It demonstrates cross-platform Flutter development and implements markdown-based knowledge management features.
