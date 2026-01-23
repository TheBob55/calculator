# Geode

**Geode** is a powerful, cross-platform knowledge management system built with Flutter. Inspired by Obsidian, Geode provides a markdown-based approach to organizing your notes with bidirectional linking, graph visualization, and advanced features like daily notes, PDF export, block references, and cloud sync.

## ✨ Features

### Core Features
- **Vault Management**: Create and manage multiple vaults (local folders of markdown files)
- **Markdown Editor**: Full-featured markdown editor with live preview and split view
- **Wikilinks**: Internal linking between notes using `[[note]]` syntax
- **Backlinks**: Automatic detection of notes that link to the current note
- **Graph View**: Interactive force-directed graph visualization of note connections
- **File Explorer**: Hierarchical file browser with search and sorting
- **Tags**: Support for `#tags` with automatic extraction
- **Unlinked Mentions**: Find notes that mention a title but don't link to it
- **Dark/Light Themes**: Full theme support with Material Design 3

### Advanced Features ✨ NEW
- **Advanced Search**: Regex search with case-sensitive options and search filters
- **Daily Notes**: Automatic creation of daily notes with templates and navigation
- **Block References**: Reference specific paragraphs with `^block-id` syntax and link to them with `[[note#^block-id]]`
- **PDF Export**: Export single notes or collections to beautifully formatted PDFs with preview, save, and share options
- **Cloud Sync**: Synchronize your vault across devices with configurable server endpoints

### Technical Features
- **Cross-Platform**: Runs on iOS, Android, macOS, Linux, Windows, and Web
- **Local-First**: All data stored locally as plain markdown files
- **Fast Performance**: Native compilation with Flutter
- **Automatic Backlink Updates**: Links update automatically when notes are renamed
- **Real-time Link Detection**: Automatically extracts wikilinks and tags as you type
- **Conflict Resolution**: Smart sync with automatic conflict detection

## 🚀 Platform Support

| Platform | Status |
|----------|--------|
| Linux    | ✅ Fully Supported |
| macOS    | ✅ Fully Supported |
| Windows  | ✅ Fully Supported |
| iOS      | ✅ Fully Supported |
| Android  | ✅ Fully Supported |
| Web      | ✅ Fully Supported |

## 📦 Getting Started

### Prerequisites
- Flutter SDK 3.38.7 or higher
- Dart SDK 3.10.7 or higher

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd geode
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

## 📂 Project Structure

```
lib/
├── main.dart                     # Application entry point
├── models/                       # Data models
│   ├── note.dart                 # Note model with wikilinks & tags
│   ├── vault.dart                # Vault model
│   └── link.dart                 # Link model for graph
├── services/                     # Business logic
│   ├── vault_service.dart        # Vault & file management
│   ├── search_service.dart       # Search with regex support
│   ├── link_service.dart         # Links, backlinks & block references
│   ├── daily_notes_service.dart  # Daily notes functionality
│   ├── pdf_export_service.dart   # PDF generation & export
│   └── sync_service.dart         # Cloud sync functionality
├── providers/                    # State management (Provider pattern)
│   ├── vault_provider.dart       # Vault state
│   └── theme_provider.dart       # Theme state
├── screens/                      # UI screens
│   ├── home_screen.dart          # Main application screen
│   ├── vault_selector_screen.dart
│   ├── graph_screen.dart         # Graph visualization
│   └── advanced_search_screen.dart # Advanced search UI
└── widgets/                      # Reusable components
    ├── file_explorer.dart        # File browser
    ├── markdown_editor.dart      # Editor component
    └── backlinks_panel.dart      # Backlinks sidebar
```

## 🔧 Key Dependencies

- **flutter_markdown**: Markdown rendering
- **provider**: State management
- **path_provider**: File system access
- **graphview**: Graph visualization
- **file_picker**: Directory selection
- **pdf & printing**: PDF generation and export
- **http**: HTTP client for sync
- **shared_preferences**: Settings storage
- **sqflite**: Local database for search indexing

## 📖 Usage Guide

### Creating a Vault
1. Launch Geode
2. Click "Create New Vault"
3. Enter a vault name
4. The vault will be created in your Documents/Geode/Vaults folder

### Opening an Existing Vault
1. Click "Open Existing Vault"
2. Select a folder containing markdown files
3. Geode will index all `.md` files automatically

### Creating Notes
- Click the `+` floating action button
- Or press the "New Note" button in the file explorer
- Enter a note title and start writing

### Linking Notes
Use wikilink syntax: `[[Note Title]]`
- Links are clickable in preview mode
- If a linked note doesn't exist, create it with one click
- Backlinks appear automatically in the right sidebar

### Daily Notes
- Click the calendar icon (📅) in the app bar to open today's note
- Daily notes are automatically created with a template
- Navigate between days using the links in each daily note
- Daily notes are stored in the `Daily Notes` folder

### Advanced Search
- Click the search icon
- Enable "Regex" for pattern matching
- Use case-sensitive search
- Filter by file content or tags
- Example regex patterns:
  - `\d+` - Find all numbers
  - `^TODO` - Lines starting with TODO
  - `deadline.*2026` - Find deadlines in 2026

### Block References
1. Add a block ID to any line: `This is important ^block-123`
2. Reference it from another note: `[[My Note#^block-123]]`
3. Block references appear in backlinks
4. Use the link service to generate unique block IDs

### PDF Export
1. Select a note
2. Click the PDF icon
3. Choose:
   - **Preview**: View before saving
   - **Save**: Export to Documents folder
   - **Share**: Share via system dialog

### Cloud Sync
1. Click the sync icon
2. Configure sync on first use:
   - Server URL: `https://your-server.com`
   - Auth Token (optional): Your API token
3. Click sync to upload changes and download updates
4. Conflicts are detected automatically

### Viewing the Graph
- Click the graph icon (🌳) in the app bar
- Nodes represent notes
- Edges represent wikilinks
- Pinch to zoom, drag to pan
- Click "Reset View" to center the graph

## 🗺️ Roadmap

### Completed ✅
- [x] Vault management
- [x] Markdown editor with live preview
- [x] Wikilinks and backlinks
- [x] File explorer
- [x] Search functionality
- [x] Graph view
- [x] Tags support
- [x] Themes (dark/light)
- [x] Split view editing
- [x] Advanced regex search
- [x] Daily notes
- [x] Block references
- [x] PDF export
- [x] Cloud sync

### Future Enhancements 🚧
- [ ] Canvas (infinite whiteboard)
- [ ] Plugin system
- [ ] Templates with variables
- [ ] Note folders and hierarchies UI
- [ ] WebDAV sync support
- [ ] Code syntax highlighting in editor
- [ ] Note aliases
- [ ] Starred/favorites notes
- [ ] Note history/version control
- [ ] Mobile widgets for quick notes
- [ ] Web clipper browser extension
- [ ] Encrypted vaults
- [ ] Collaboration features

## 🏗️ Architecture

### State Management
The app uses the Provider pattern for state management:
- **VaultProvider**: Manages current vault, notes list, and file operations
- **ThemeProvider**: Manages theme state (light/dark/system)

### Data Flow
1. User selects a vault → VaultService loads all markdown files
2. Files are parsed into Note models
3. LinkService processes wikilinks, backlinks, and block references
4. Notes are stored in VaultProvider
5. UI updates reactively via Provider

### File Storage
- Vaults are plain folders on the file system
- Notes are stored as `.md` files
- No proprietary format - fully compatible with Obsidian and any markdown editor
- Metadata (vault list, settings, sync config) stored in SharedPreferences
- Daily notes stored in `Daily Notes` subfolder

### Sync Architecture
- Client-server model with RESTful API
- Incremental sync based on modification timestamps
- Conflict detection with manual resolution
- Supports custom auth tokens
- Falls back gracefully if offline

## 🤝 Contributing

Contributions are welcome! This project implements advanced knowledge management features and is open for enhancements.

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on multiple platforms
5. Run `flutter analyze` to ensure code quality
6. Submit a pull request

### Code Style
- Follow Flutter/Dart style guidelines
- Use meaningful variable and function names
- Add doc comments for public APIs
- Keep functions small and focused

## 📝 License

This is a demonstration project built for educational purposes.

## 🙏 Acknowledgments

- Inspired by [Obsidian](https://obsidian.md/)
- Built with [Flutter](https://flutter.dev/)
- Uses Material Design 3
- PDF generation powered by [pdf](https://pub.dev/packages/pdf) and [printing](https://pub.dev/packages/printing)

## 📸 Screenshots

### Main Editor
The main interface features a three-panel layout:
- **Left**: File explorer with search and sorting
- **Center**: Markdown editor with live preview and split view
- **Right**: Backlinks, outgoing links, and unlinked mentions panel

### Graph View
Interactive force-directed graph showing note connections. Zoom and pan to explore your knowledge base. Node size indicates note importance based on backlinks.

### Advanced Search
Powerful search interface with regex support, case-sensitive matching, and result filtering by content and tags.

### Daily Notes
Automatic daily note creation with customizable templates, previous/next day navigation, and calendar view.

### PDF Export
Export notes to beautifully formatted PDFs with proper typography, heading hierarchy, and metadata.

---

**Note**: Geode is a fully-featured knowledge management system that demonstrates modern cross-platform Flutter development. All features are production-ready and tested across multiple platforms.

## 🆘 Support

For issues, feature requests, or questions:
- Open an issue on GitHub
- Check the documentation
- Review existing issues for solutions

---

Built with ❤️ using Flutter
