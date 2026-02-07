# MacFileTransferApp

A native macOS dual-pane file manager for easy file transfers between your Mac, external drives, and devices.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Native-green.svg)
![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)

## Features

### 📁 Dual-Pane File Browser
- Independent navigation in left and right panes
- Side-by-side file comparison and management
- Drag-and-drop support between panes

### 💾 External Drive Support
- Automatic detection of USB drives, SD cards, and external HDDs
- Browse and manage files on any mounted volume
- Quick access via sidebar

### ↔️ File Operations
- **Copy** files and folders with progress tracking
- **Move** files and folders between locations
- **Delete** items (moves to Trash)
- **Create** new folders
- Transfer queue with status display

### 👁️ Multiple View Modes
- **Icons View** - Large icons in a grid layout
- **List View** - Compact list with file names
- **Details View** - Sortable table with customizable columns

### ⚙️ Customizable Details View
Choose which columns to display:
- Name (always visible)
- Size
- Type
- Kind
- Date Modified
- Date Created
- Date Accessed
- Permissions
- Owner

### 🎯 Native macOS Experience
- Built with SwiftUI for modern macOS
- Native look and feel
- Keyboard shortcuts for power users
- Tooltips on all controls
- Custom app icon

## Screenshots

*Coming soon*

## Requirements

- **macOS 13.0 (Ventura)** or later
- **Xcode 15.0+** (for building from source)

## Installation

### Build from Source

1. **Clone the repository:**
```bash
   git clone https://github.com/leaton79/MacFileTransferApp.git
   cd MacFileTransferApp
```

2. **Open in Xcode:**
```bash
   open MacFileTransferApp.xcodeproj
```

3. **Build and run:**
   - Press `⌘R` in Xcode, or
   - Go to **Product** → **Run**

### Create Standalone App

1. In Xcode, go to **Product** → **Archive**
2. Once archived, click **Distribute App**
3. Choose **Custom** → **Copy App**
4. Export to your **Applications** folder
5. Launch from Applications

### Grant File Access (Required)

For full functionality without permission prompts:

1. Open **System Settings** → **Privacy & Security**
2. Scroll to **Full Disk Access**
3. Click the lock icon and authenticate
4. Click **"+"** and add **MacFileTransferApp**
5. Toggle it **ON**

This is standard for file manager applications and allows the app to access files without repeated permission dialogs.

## Usage

### Navigation
- Click folders to navigate into them
- Use **← → ↑** buttons to go back, forward, or up
- Click items in the sidebar for quick access

### Transferring Files
1. Navigate to the source folder in one pane
2. Navigate to the destination folder in the other pane
3. Select file(s) in the source pane
4. Click **Copy →** or **Move →** in the toolbar
5. Watch the transfer queue at the bottom for progress

### View Modes
- Click the **grid icon** for Icons view
- Click the **list icon** for List view
- Click the **table icon** for Details view
- In Details view, click **Columns** button to customize visible columns

### Keyboard Shortcuts
- `⌘⇧C` - Copy selected files from left to right
- `⌘⌥C` - Copy selected files from right to left
- `⌘⇧M` - Move selected files from left to right
- `⌘⌥M` - Move selected files from right to left

## Project Structure
```
MacFileTransferApp/
├── MacFileTransferApp/
│   ├── Models/
│   │   ├── FileItem.swift              # File/folder data model
│   │   ├── FileSystemService.swift     # File operations
│   │   ├── TransferQueue.swift         # Copy/move queue management
│   │   └── ColumnConfiguration.swift   # Details view column settings
│   ├── ViewModels/
│   │   └── FileBrowserViewModel.swift  # Navigation & state logic
│   ├── Views/
│   │   ├── ContentView.swift           # Main window
│   │   ├── DualPaneView.swift          # Two-pane layout
│   │   ├── FileBrowserPane.swift       # Single pane browser
│   │   ├── SidebarView.swift           # Favorites & Devices sidebar
│   │   ├── FileIconView.swift          # Icons view mode
│   │   ├── FileListView.swift          # List view mode
│   │   ├── FileDetailsView.swift       # Details view with columns
│   │   └── TransferStatusView.swift    # Transfer queue UI
│   └── Assets.xcassets/
│       └── AppIcon.appiconset/         # Custom app icon
├── README.md
├── LICENSE
└── .gitignore
```

## Roadmap

### Phase 1 - ✅ Complete
- Dual-pane file browser
- External drive support
- Copy/Move operations with progress
- Multiple view modes
- Customizable Details view

### Phase 2 - Planned
- [ ] Android device support via MTP
- [ ] USB device auto-detection
- [ ] Phone ↔ Mac file transfers
- [ ] Bulk transfer optimization

### Phase 3 - Future
- [ ] File search within panes
- [ ] Filters (by type, size, date)
- [ ] Batch rename operations
- [ ] File comparison tools
- [ ] Preferences/Settings panel

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

**Lance Eaton**
- GitHub: [@leaton79](https://github.com/leaton79)

## Acknowledgments

- Built with SwiftUI for native macOS experience
- Icon design inspired by classic dual-pane file managers
- Thanks to the macOS developer community for best practices

## Support

If you encounter any issues or have questions:
- Open an issue on GitHub
- Check existing issues for solutions
- Review the [Installation](#installation) section for common setup problems

---

**Note:** This is a personal project for learning and productivity. While functional and tested, it's provided as-is without warranty. Always backup important files before performing file operations.
