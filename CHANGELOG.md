# Project Changelog

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
