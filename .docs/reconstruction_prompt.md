# K-Beauty Inventory & POS System: Reconstruction Prompt

This document provides a detailed technical prompt for reconstructuring the **K-Beauty Inventory System** from scratch. It is divided into core modules and features.

---

## 1. Project Overview & Tech Stack
**Goal**: Build a multi-platform system (Web Admin + Mobile App) for managing beauty salon inventory, staff attendance (with AI verification), and Point of Sale (POS) operations.

**Backend**:
- **Framework**: Laravel 11 (PHP 8.2+)
- **Admin Panel**: Filament v5
- **Authentication**: Laravel Sanctum (API) & Web Session
- **Permissions**: Spatie Laravel-Permission with Filament Shield
- **Media**: Spatie Laravel-MediaLibrary
- **Reporting**: Maatwebsite Excel & Barryvdh Laravel-DOMPDF

**Mobile**:
- **Framework**: Flutter (Android/iOS)
- **State Management**: Provider
- **Local Storage**: Flutter Secure Storage & Shared Preferences
- **Key Plugins**: 
  - `google_mlkit_face_detection` (AI Verification)
  - `geolocator` (Geofencing)
  - `blue_thermal_printer` (Thermal Printing)
  - `package_info_plus` (Versioning)

---

## 2. Core Database Architecture
The system requires the following entity relationships:
- **Inventory**: `locations`, `categories`, `products`, `units`, `inventory_movements`, `stock_opnames`.
- **Staff/HR**: `offices`, `employees`, `attendances`, `shifts`, `holidays`, `absent_attendances`.
- **POS**: `services`, `service_categories`, `service_variants`, `pos_transactions`, `pos_payments`, `pos_shifts`, `discounts`, `payment_types`.
- **CRM**: `customers`, `customer_portfolios`.

**Crucial Logic**:
- **Multi-UOM**: Products must support a `primary_unit` (smallest) and `secondary_unit` (bulk) with a `conversion_ratio`.
- **Polymorphic Transactions**: `inventory_movements` must link to `Product`, `Service` (materials), or `Bundle` items.

---

## 3. Backend Features (Filament Admin)
- **Dashboard**: Real-time stats for stock levels, daily sales, and attendance.
- **Master Data**: Full CRUD for Products, Services, Locations, and Employees.
- **Inventory Controls**:
  - `InventoryIns/Outs`: Direct stock adjustments.
  - `Stock Opname`: Periodic count verification with automatic discrepancy movements.
  - `Stock Card`: Detailed audit log of movements per item/location.
- **HR Module**:
  - Geofencing configuration per Office.
  - Attendance Recap View with Excel/PDF export.
  - Holiday management.
- **POS Configuration**:
  - General Settings: Store info, Receipt footer, POS layout (Grid/List).
  - App Versioning: Set `latest_version` and `apk_url` for mandatory updates.
- **Security**: Impersonation tool for Super Admins.

---

## 4. Mobile App Features
- **Authentication**: Persistent login via Sanctum tokens.
- **Smart Attendance**:
  - **Face Verification**: Integrate ML Kit to detect real human faces. Require eyes/mouth visibility and specific head orientation.
  - **Geofencing**: Block check-in if user is outside the office radius (using `geolocator`).
  - **History**: Grouped logs by month.
- **Inventory Browser**:
  - Searchable catalog with active/inactive status filtering.
  - Inactive products must be visually dimmed and badged "NON-AKTIF".
- **POS System**:
  - Item selection (Services/Products/Bundles).
  - **Designated Employee**: Multi-assignment for treatment commissions. Filter list for active users only (exclude super_admin).
  - **Checkout**: Support Tunai, Debit, Credit, and QRIS.
  - **Receipts**: Thermal print via Bluetooth and Share via WhatsApp.
- **Mandatory Update**:
  - On startup, compare `package_info` version with backend `latest_version`.
  - Show a blocking dialog if `is_mandatory_update` is true.

---

## 5. Key Integration Logic
- **Stock Deduction**: When a Service is sold in POS, the system must check the Service's "Materials" list and automatically deduct the corresponding Products from the "POS Display Location".
- **Permissions Bridge**: Ensure the Mobile API (`sanctum` guard) respects Filament Shield permissions (`web` guard) by mapping permission strings (e.g., `ViewAny:Product`).
- **Face Embedding**: Store a 128-float array (JSON) in the `employees` table for face matching.

---

## 6. Implementation Milestones
1.  **Phase 1**: Base Laravel setup + Filament Admin + Spatie Permission.
2.  **Phase 2**: Core Inventory & Multi-UOM logic + Reports.
3.  **Phase 3**: HR & Attendance API (Face + Geofence).
4.  **Phase 4**: POS System (Checkout, Prints, Commissions).
5.  **Phase 5**: Mobile App Shell + Inventory Sync.
6.  **Phase 6**: Advanced Mobile Features (Attendance, POS, Updates).
