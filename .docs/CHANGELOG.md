# Project Changelog

## [1.12.0] - 2026-06-23

### Added
- **Tablet/PC 2-Pane Split Layouts (Adaptive Split Layout):**
  - **Inventory Transactions:** Split layout showing the store and item entry form on the left, and the live transaction items list on the right.
  - **Stock Movement:** Split layout showing the movement configurations on the left, and a visual planned movement summary card on the right.
  - **Stock Opname:** Split layout showing the locations and product list on the left, and a detail card to input actual stock quantities on the right.

### Changed
- **Mobile Responsiveness Improvements:**
  - **Product Details:** The secondary unit dropdown and ratio text field now stack vertically on mobile to prevent clipping, and remain side-by-side on tablet/PC.
  - **Customer Details Tab Bar:** Made the CRM customer details TabBar scrollable on mobile screen widths to prevent label truncation.
  - **POS Checkout Grid Columns:** Payment options now layout in 2 columns on mobile (instead of 4 columns) to allow text like "Debit Card" to fit properly. Employee lists layout in 2 columns (instead of 3) on mobile to prevent clipping of names.
  - **Responsive Dialog Widths:** Replaced hardcoded dialog widths (`width: 400`) in Customer Selection and Bill Preview dialogs with responsive widths relative to the mobile display (`MediaQuery.of(context).size.width * 0.85`), eliminating clipping errors on smaller phones.

## [1.11.0] - 2026-06-03

### Changed
- **Reverted Transaction History Layout**: Reverted the Transaction History screen back to its original 1-page layout. Selecting a transaction card now immediately opens the transaction details popup dialog instead of loading a split-screen detail pane on tablets.

### Fixed
- **Optimized 2-Pane Selections Lag**: Resolved the gesture selection lag on the remaining 2-pane tablet split layouts (Treatments list, CRM Customer list, Product Catalog, Stock Balance, and Appointment Calendar) by performing state updates synchronously in user gesture handlers (`onTap`, `onSelected`, `onPressed`) instead of wrapping them in post-frame callbacks.
- **Scroll Duplicate Fetch Guard**: Retained the `_isFetching` scroll lock in Transaction History to prevent duplicate API fetch requests during fast scroll events.

## [1.10.0] - 2026-05-30

### Added
- **Searchable Customer Selection Dialog**: Added a reusable, searchable popup dialog for selecting customers across both the POS Checkout and Appointment Scheduler screens.
  - Search by **Name** or **Phone Number**.
  - Displays customer phone numbers inline for easy cross-checking of duplicate names.
- **Enforced Customer Selection at POS Checkout**: Added validation to block checkouts without a selected customer, ensuring a customer profile is linked to send receipts via WhatsApp.
- **WhatsApp Customer Name**: Automatically includes the customer's name in the generated WhatsApp billing/receipt messages.

### Changed
- **Auto-Populate Designated Employee**: The POS designated employee field is now automatically initialized using the currently logged-in user session for a smoother checkout workflow.

### Fixed
- **POS Checkout Employee Validation**: Fixed the validation issue where checkouts were blocked with "Please select an employee first" despite therapists being assigned to individual cart items.
- **Customer Visit History Null Items**: Resolved an issue in the Customer Details screen where items in the history tab rendered as `null x1.00`.
- **Customer History Photos (Emulator Localhost URLs)**: Fixed rendering of visit photos on the emulator by dynamically translating backend-generated `localhost` / `127.0.0.1` URLs to the emulator's loopback IP (`10.0.2.2`).

## [1.9.0] - 2026-05-02

### Added
- **Mandatory App Update System**: 
  - Integrated a complete version tracking system across backend and mobile.
  - **Admin Control**: New "App Versioning" section in General Settings to manage `latest_version`, `apk_url`, and `is_mandatory_update`.
  - **Mobile Enforcement**: App automatically checks for updates on startup and forces a redirect to the APK download if a mandatory update is required.
- **Product Activity Management**:
  - Added `is_active` toggle for products on both backend and mobile.
  - **Visual Feedback**: Inactive products are now dimmed and marked with a "NON-AKTIF" badge in the mobile catalog and product browser.
- **Designated Employee Filtering**:
  - Enhanced POS employee selection to improve security and clarity.
  - The list now automatically filters for **active users** only and strictly **excludes the super_admin role**.

### Fixed
- **Mobile UI Syntax**: Resolved build failures in `ProductCard` and `ProductBrowserScreen` by correcting widget nesting and parentheses.
- **POS Logic**: Hardened the designated employee fetch to ensure real-time synchronization with user status changes.

## [1.8.0] - 2026-04-01

### Added
- **Permission-Based Menu Visibility (Mobile)**: 
  - Integrated **Filament Shield** permissions directly into the mobile dashboard.
  - Menus are now dynamically hidden/shown based on the user's specific permissions (e.g., `ViewAny:ServiceCategory`, `Create:PosTransaction`).
  - **Dynamic Sections**: Entire dashboard sections (Inventory, Master Data, etc.) now hide completely if the user has no authorized menus inside them.
- **Cross-Guard Permission Support**: Modified API to bridge the gap between Filament (`web` guard) and Mobile (`sanctum` guard), ensuring consistent authorization across all platforms.

### Fixed
- **Mobile Impersonation Stability**:
  - Resolved "No users found" issue by hardening JSON parsing to handle null/missing employee profile data (NIK, Office ID).
  - Fixed "Failed to impersonate" error by making backend authorization checks guard-agnostic.
- **Admin Security (Web)**: 
  - Strictly restricted **Roles** and **Users** management to the `super_admin` role only, preventing unauthorized access during impersonation sessions.
- **Filament Redirection**: Corrected the impersonation flow to ensure admins remain within the Filament dashboard after switching users.
- **Bug Fix**: Resolved a parsing crash in `employee.dart` for incomplete user records.

## [1.7.0] - 2026-03-23

### Added
- **Bluetooth Printer Configuration (Mobile)**: 
  - New **Printer Settings** screen in Profile for scanning and connecting thermal printers.
  - Integrated `permission_handler` for secure Bluetooth/Location access on Android/iOS.
  - Added **Test Print** functionality to verify hardware readiness.
- **Customizable Bill Footer**:
  - New **Bill Footer Message** field in POS General Settings (Dashboard).
  - Footer now appears on Printed Receipts, WhatsApp shares, and Checkout Previews.
- **Receipt Enhancements**:
  - **Dynamic Layout**: Moved Store Address and Phone to the receipt header for better professional framing.
  - **WhatsApp Resend**: Direct button in Transaction History to re-share past receipts easily.

### Fixed
- **Nailist Data Stability**: Hardened employee name mapping to prevent `null` or `(null)` from appearing in receipts; defaults to "Staff" if data is missing.
- **Filament Action Namespaces**: Resolved technical "Class Not Found" errors by correcting `CreateAction` and `DeleteAction` namespaces across multiple resources.
- **Mobile Dependencies**: Corrected `blue_thermal_printer` implementation to gracefully handle disconnection states.

## [1.6.0] - 2026-03-20

### Added
- **Service Master Data Management (Mobile)**: 
  - Complete control over Service Categories and Treatments directly from the mobile app.
  - Added `is_active` status toggle for both categories and treatments to manage availability dynamically.
  - Aligned mobile treatment forms with Filament backend, including **Commission Type**, **Commission Amount**, and **Stock Deduction** settings.
- **POS & CRM Enhancements**:
  - Integrated **Customer Treatment Photos** with POS transactions at checkout.
  - **Transaction History**: New mobile screen to view past sales, totals, and attached result photos.
  - **Auto-Portfolio Sync**: Photos taken during checkout are automatically linked to the Customer's Portfolio for easy reference.
- **Dashboard Optimization**: 
  - New **Master Data** and **Point of Sales** sections for better organization.
  - **Responsive Single-Page Layout**: Re-engineered the dashboard using dynamic grids (`GridView.extent`) to keep buttons compact and professional across all screen sizes (Phone, Tablet, Desktop).

### Fixed
- **Type Compatibility**: Resolved `int is not a bool` errors in mobile service views by handling database boolean casting (1/0 vs true/false).
- **UI Stability**: Corrected layout logic on the dashboard that caused build failures on certain screen sizes.
- **Data Integrity**: Ensured mandatory fields are clearly marked and validated in mobile master data forms.

## [1.5.0] - 2026-03-12

### Fixed
- **Product Image Visibility**: Aligned media collection naming (`product_images`) between backend and mobile API, ensuring images uploaded via web are correctly displayed in the app.
- **Mobile UI Truncation**: Implemented `SafeArea` across all critical screens to prevent bottom buttons and other components from being truncated by system navigation bars or notches.

## [1.4.0] - 2026-03-11

### Added
- **Advanced Face Verification Security**: 
  - **Triple-Lock Detection**: Mobile app now requires eyes, nose, and mouth detection to proceed.
  - **Humanity Checks**: Added aspect ratio and head orientation (Euler angles) validation to block 2D background patterns (like ceilings).
  - **Smart Center-Weighting**: Backend algorithm now focuses significantly more on the center of the frame (the face) during comparison.
  - **Dynamic State Management**: Instant reset of detection state after capture to prevent "stuck" UI.
- **Mobile Versioning**: Bumped app version to **v1.1.0+2** for consistent tracking.

### Changed
- **Similarity Threshold**: Adjusted to a rock-solid **80%** (validated via RGB comparison) for the perfect balance of security and speed.

### Fixed
- **Mobile Build**: Resolved `google_mlkit_face_detection` (v0.11.1) compatibility issues with `getLandmark`.
- **UI Stability**: Fixed detection "hang" occurring after failed check-in attempts.


## [1.3.0] - 2026-03-11

### Added
- **Attendance History**: New mobile screen to view monthly-grouped records (Dashboard Access).
- **Impersonation Feature**: Super Admins can now impersonate other users on both Web (Filament) and Mobile (API).
- **Environment Indicator**: Premium icon-based badge (Cloud/Developer) on Login and Dashboard for environment awareness.
- **Attendance Enhancements**: 
  - Radius-based button disabling on mobile (prevents check-in/out if too far).
  - Pull-to-refresh on Attendance screen.
- **Android Optimization**: Full support for Android 15 (Target SDK 35, 16 KB Page Size alignment).

### Changed
- **Mobile UX**: Added password visibility toggles to Login and Change Password screens.
- **Backend Security**: Case-insensitive and robust role checks for administrative tools.

### Fixed
- **Mobile Navigation**: Relocated History access to Dashboard for better accessibility.
- **Bug Fix**: Resolved empty user list issue in mobile selection screen.

## [1.2.0] - 2026-02-23

### Added
- **Multi-UOM Support**: Comprehensive system for Primary and Secondary units of measure.
- **Mobile Product Creation**: Added "Add Product" functionality to the mobile app with image upload and UOM configuration.
- **Stock Opname Enhancements**: Support for dual-unit input (e.g., Box & Pcs) with real-time total calculation.
- **Stock Balance Breakdown**: Displaying inventory in human-readable unit breakdowns (e.g., "1 Box 5 Pcs").
- **UI Guidance**: Added helpful instructions and Indonesian translations for technical fields like conversion ratios.

### Changed
- **Architecture Refactor**: Standardized on "Smallest-Unit-First" as Primary Unit to ensure database integrity and avoid decimal drift.
- **Mobile UI**: Refactored `ProductDetailScreen` to handle both creation and editing modes efficiently.

### Fixed
- **Mobile Build**: Resolved syntax errors and duplicate parameters in `ProductService` and `ProductDetailScreen`.
- **Logic Correction**: Aligned conversion formulas across backend and mobile to `1 Secondary = N Primary`.


## [1.1.0] - 2026-02-19

### Added
- **Mobile Stock Balance**: New screen to check product stock per location.
- **Role-Based Access**: Hidden "Stock Balance" feature for users with the `nailist` role.
- **Navigation**: "Back" buttons added to all Filament resource Create/Edit pages.
- **Refinement**: Automatic redirection to List View after creating/editing records in Filament.
- **UI Refactor**: Stock Card Report now uses a dedicated Filament Table interface.
- **Filtering**: Added specific Location filtering to the Stock Card Report.
- **Summary**: Grouped totals added to the footer of the Stock Card Report.

### Added
- **Export Capabilities**: Added Excel (.xlsx) and PDF export for the Stock Card Report.
- **Enhanced Filtering**: New "All Products" option in the Stock Card Report (calculates totals across all items).
- **Export Templates**: Custom Blade templates for professional-looking PDF reports.

### Fixed
- **Stability**: Resolved `QueryException` and `TypeError` in report footers by shifting to manual PHP summarization.
- **Resilience**: Made navigation traits robust to handle custom non-resource pages gracefully.

### Improvements
- **Dependencies**: Added `maatwebsite/excel` and `barryvdh/laravel-dompdf` to backend infrastructure.
- **Documentation**: Updated technical docs with export logic and virtual column handling.
