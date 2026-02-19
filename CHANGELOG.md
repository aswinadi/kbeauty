# Project Changelog

## [1.1.0] - 2026-02-19

### Added
- **Mobile Stock Balance**: New screen to check product stock per location.
- **Role-Based Access**: Hidden "Stock Balance" feature for users with the `nailist` role.
- **Navigation**: "Back" buttons added to all Filament resource Create/Edit pages.
- **Refinement**: Automatic redirection to List View after creating/editing records in Filament.
- **UI Refactor**: Stock Card Report now uses a dedicated Filament Table interface.
- **Filtering**: Added specific Location filtering to the Stock Card Report.
- **Summary**: Grouped totals added to the footer of the Stock Card Report.

### Fixed
- **Mobile Feedback**: Improved empty states and error handling when "Check Stock" is clicked.
- **API Performance**: Eager loaded roles in authentication endpoints to speed up role checks.

### Improvements
- **Technical**: Introduced `HasStandardPageActions` trait for consistent Filament UI management.
- **Documentation**: Added technical implementation guide and comprehensive changelog.
