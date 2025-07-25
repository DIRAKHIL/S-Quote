# S-Quote: Event Planner Quotation Generator

A professional macOS application for creating detailed event planning quotations, specifically designed for wedding planners, photographers, and event management companies.

## Features

### 🎯 Core Functionality
- **Event Management**: Create and manage multiple event quotations
- **Service Catalog**: Comprehensive library of event services and items
- **Dynamic Pricing**: Real-time calculation with taxes, discounts, and fees
- **Professional Export**: Generate formatted quotations for clients
- **Data Persistence**: Local storage with UserDefaults integration

### 📸 Photography & Videography Services
Based on real-world requirements, includes:
- Traditional still photography
- Candid photography with professional equipment
- 4K video recording
- Cinematic video production
- Drone photography and videography
- Wedding albums and promotional videos

### 🎉 Event Categories
- **Photography**: Traditional, candid, 4K video, cinematic, drone
- **Equipment**: LED screens, lighting, sound systems, cameras
- **Catering**: Dinners, cocktails, cakes, traditional meals
- **Decoration**: Mandap, stage, entrance, lighting setups
- **Entertainment**: DJ, live bands, dhol players, dance performers
- **Venue**: Wedding halls, outdoor spaces, parking
- **Staffing**: Coordinators, waitstaff, security, makeup artists
- **Transportation**: Bridal cars, guest transport, traditional entries
- **Flowers**: Bouquets, garlands, petals, floral jewelry
- **Other**: Invitations, mehendi artists, priests, return gifts

### 💰 Pricing Features
- Subtotal calculation
- Percentage-based discounts
- Additional fees
- Tax calculations
- Currency formatting (USD/INR)
- Real-time total updates

## System Requirements

- **macOS**: 15.5 or later
- **Xcode**: 16.4 or later
- **Apple Silicon**: M1 Pro or later (recommended)
- **Memory**: 16 GB RAM (recommended)

## Installation

### For Users
1. Download the latest DMG from [Releases](https://github.com/DIRAKHIL/S-Quote/releases)
2. Open the DMG file
3. Drag S-Quote.app to Applications folder
4. Launch from Applications or Spotlight

### For Developers

#### Prerequisites
```bash
# Install Xcode from App Store
# Install Xcode Command Line Tools
xcode-select --install

# Verify installation
xcodebuild -version
```

#### Clone and Build
```bash
# Clone the repository
git clone https://github.com/DIRAKHIL/S-Quote.git
cd S-Quote

# Build using the automated script
./build.sh

# Or build manually with Xcode
open "S Quote.xcodeproj"
```

## Build Automation

### Local Build Script
The project includes a comprehensive build script:

```bash
# Full build with tests
./build.sh

# Skip tests
./build.sh --skip-tests

# Skip archiving (development build)
./build.sh --skip-archive

# Build and upload to S3
./build.sh --upload-s3
```

### GitHub Actions CI/CD
Automated builds are configured for:
- **Push to main/develop**: Build and test
- **Pull requests**: Build and test
- **Releases**: Build, test, create DMG, upload to S3

#### Required Secrets
For S3 upload functionality, configure these GitHub secrets:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_S3_BUCKET`

### Build Outputs
- **Development**: `.app` bundle in DerivedData
- **Release**: `.xcarchive` and exported `.app`
- **Distribution**: `.dmg` installer
- **Artifacts**: Uploaded to GitHub Actions and optionally S3

## Project Structure

```
S-Quote/
├── S Quote/                    # Main application
│   ├── Models/                 # Data models
│   │   ├── Event.swift
│   │   ├── Quote.swift
│   │   └── QuoteItem.swift
│   ├── Views/                  # SwiftUI views
│   │   ├── NewQuoteView.swift
│   │   └── QuoteDetailView.swift
│   ├── ViewModels/             # View models
│   │   └── QuoteViewModel.swift
│   ├── Services/               # Business logic
│   │   └── QuoteService.swift
│   ├── Assets.xcassets/        # App icons and images
│   ├── ContentView.swift       # Main view
│   ├── S_QuoteApp.swift       # App entry point
│   └── S_Quote.entitlements   # App permissions
├── S QuoteTests/              # Unit tests
├── S QuoteUITests/            # UI tests
├── .github/workflows/         # CI/CD configuration
├── build.sh                   # Build automation script
└── README.md                  # This file
```

## Development

### Architecture
- **SwiftUI**: Modern declarative UI framework
- **MVVM**: Model-View-ViewModel architecture
- **ObservableObject**: State management
- **UserDefaults**: Local data persistence
- **Combine**: Reactive programming

### Key Components

#### Models
- `Event`: Client and event information
- `Quote`: Complete quotation with items and pricing
- `QuoteItem`: Individual service/product items

#### Services
- `QuoteService`: Business logic and data management
- Default items creation and management
- Quote export functionality

#### Views
- `ContentView`: Main split view interface
- `NewQuoteView`: Multi-step quote creation wizard
- `QuoteDetailView`: Quote viewing and editing

### Adding New Features

#### Adding New Service Categories
1. Update `ItemCategory` enum in `QuoteItem.swift`
2. Add icon and color properties
3. Update default items in `QuoteService.swift`

#### Adding New Export Formats
1. Extend `QuoteService.generateQuoteText()` method
2. Add new export options in `ExportQuoteView`
3. Implement format-specific generation logic

## Testing

### Unit Tests
```bash
# Run all tests
xcodebuild test -project "S Quote.xcodeproj" -scheme "S-Quote" -destination 'platform=macOS'

# Run specific test class
xcodebuild test -project "S Quote.xcodeproj" -scheme "S-Quote" -destination 'platform=macOS' -only-testing:S_QuoteTests/QuoteServiceTests
```

### UI Tests
```bash
# Run UI tests
xcodebuild test -project "S Quote.xcodeproj" -scheme "S-Quote" -destination 'platform=macOS' -only-testing:S_QuoteUITests
```

## Deployment

### Manual Release
1. Update version in project settings
2. Create git tag: `git tag v1.0.0`
3. Push tag: `git push origin v1.0.0`
4. GitHub Actions will automatically build and create release

### Automated Deployment
The CI/CD pipeline automatically:
1. Builds the app on every push
2. Runs tests and static analysis
3. Creates DMG installer
4. Uploads artifacts to GitHub
5. Optionally uploads to S3 for distribution

## Troubleshooting

### Common Build Issues

#### Code Signing
```bash
# Check signing identity
security find-identity -v -p codesigning

# Update provisioning profiles
# Xcode → Preferences → Accounts → Download Manual Profiles
```

#### Missing Dependencies
```bash
# Clean build folder
rm -rf ~/Library/Developer/Xcode/DerivedData

# Clean project
xcodebuild clean -project "S Quote.xcodeproj" -scheme "S-Quote"
```

#### Scheme Issues
```bash
# List available schemes
xcodebuild -list -project "S Quote.xcodeproj"

# Ensure scheme is shared
# Xcode → Product → Scheme → Manage Schemes → Check "Shared"
```

### Runtime Issues

#### Data Persistence
- Data is stored in UserDefaults
- Location: `~/Library/Preferences/DIR.S-Quote.plist`
- Reset: Delete the plist file to clear all data

#### Performance
- Large quote lists may impact performance
- Consider implementing Core Data for production use
- Optimize image assets for better memory usage

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-feature`
3. Make changes and test thoroughly
4. Commit changes: `git commit -am 'Add new feature'`
5. Push to branch: `git push origin feature/new-feature`
6. Create Pull Request

### Code Style
- Follow Swift API Design Guidelines
- Use SwiftLint for code formatting
- Write unit tests for new functionality
- Update documentation for public APIs

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue on GitHub
- Email: openhands@all-hands.dev

## Roadmap

### Version 1.1
- [ ] PDF export functionality
- [ ] Email integration
- [ ] Template management
- [ ] Multi-currency support

### Version 1.2
- [ ] Cloud synchronization
- [ ] Client management
- [ ] Invoice generation
- [ ] Payment tracking

### Version 2.0
- [ ] iOS companion app
- [ ] Web dashboard
- [ ] Team collaboration
- [ ] Advanced reporting

## Acknowledgments

- Built with SwiftUI and modern macOS development practices
- Inspired by real-world event planning requirements
- Sample data based on Ashok's wedding quotation structure
- Designed for professional event planners and photographers