# Technical Documentation

This document outlines the technical implementation and features added to the Inventory System during the recent development phases.

## 1. Mobile Stock Balance Feature

Provides mobile users (except those with the 'nailist' role) with real-time stock information per location.

### Backend Implementation
- **Controller**: `App\Http\Controllers\Api\ProductController`
- **Method**: `stockBalance(Product $product)`
- **Route**: `GET /api/products/{product}/balance`
- **Logic**: Calculates current stock by summing `qty` from `inventory_movements` where the location matches, differentiating between `to_location_id` (addition) and `from_location_id` (subtraction).

### Mobile App Implementation
- **Service**: `InventoryService.getStockBalance(productId)`
- **Screen**: `StockBalanceScreen`
- **Role-Based Access**: The `DashboardScreen` checks the current user's roles. If the user has the `nailist` role, the "Stock Balance" card is hidden.
- **Error Handling**: Implemented explicit feedback for various API states:
    - Initial prompt to select product.
    - Loading indicator while fetching.
    - Detailed error messages for failed requests (e.g., 404, Connection timeout).
    - Empty state if no data is found for the selected product.

## 2. Filament UI Navigation Refinements

Improved the administrative user experience by standardizing navigation and workflow.

### Custom Page Trait
- **File**: `App\Traits\HasStandardPageActions.php`
- **Purpose**: Provides a reusable `getBackAction()` and `getRedirectUrl()` method.
- **Implementation**:
    - **Back Button**: Added to the header of all "Create" and "Edit" resource pages.
    - **Redirect Logic**: Overrides the default Filament behavior to redirect users back to the **List View** instead of staying on the Edit page after saving.

### Affected Resources
The following 11 resources (22+ pages) have been updated:
- Products, Purchases, StockOpnames, Suppliers, Units, Users, Categories, Locations, InventoryMovements, InventoryIns, and InventoryOuts.

## 3. Stock Card Report Refactor

Modernized the report generator to use native Filament components for a "premium" feel.

### Refactored Logic
- **File**: `App\Filament\Pages\StockCardReport.php`
- **UI Components**: Removed custom Blade templates in favor of `Filament\Tables\Table`.
- **Location Filtering**: Replaced the "Summary/Detail" toggle with a dynamic **Location** selector (including an "All Locations" option).
- **Table Columns**:
    - **Initial**: Stock balance prior to the selected start date.
    - **In/Out**: Inventory movements within the period.
    - **Stock**: Real-time balance as of the end date (Initial + In - Out).
- **Summary Footer**: Added a "Total" row at the bottom of the table to summarize quantities across all filtered locations.
- **Reactive UI**: The table refreshes automatically when filters are applied.
