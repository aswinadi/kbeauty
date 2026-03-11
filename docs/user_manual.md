# KBeauty Inventory System User Manual

Welcome to the KBeauty Inventory System User Manual. This guide provides comprehensive instructions on how to use both the Web Dashboard (Filament) and the Mobile Application (Flutter) to manage your inventory effectively.

---

## 1. System Overview & Core Concepts

The KBeauty Inventory System is designed to provide real-time visibility and control over stock movements across multiple locations.

### 🔄 Multi-UOM Philosophy ("Smallest-Unit-First")
To ensure 100% database integrity and avoid rounding issues, we use a "Smallest-Unit-First" approach:
*   **Primary Unit**: The smallest possible unit of an item (e.g., "Pcs" or "Gram").
*   **Secondary Unit**: A larger packaging unit (e.g., "Box" or "Pack").
*   **Conversion Ratio**: The number of primary units contained within one secondary unit (e.g., 1 Box = 12 Pcs).

### 📍 Locations
Inventory is tracked per **Location** (e.g., "Warehouse A", "Store B"). All transactions must specify a location to maintain accurate stock balances.

---

## 2. Web Dashboard (Filament)

The web dashboard is the central hub for administrative tasks, reporting, and bulk data management.

### 🔑 Getting Started
1.  Navigate to the web application URL.
2.  Log in using your administrative credentials.
3.  Use the **Sidebar** to navigate between resources like Products, Inventory, and Reports.

### 📦 Product Management
*   **Catalog**: View and search all products in the **Products** resource.
*   **Creating Products**: Click "New Product" to add items. Ensure you specify the SKU, Category, and UOM settings.
*   **UOM Configuration**: In the product form, define the `Primary Unit` and `Secondary Unit` (optional) along with the conversion ratio.

### 🔄 Inventory Transactions
*   **Stock In**: Use **Inventory Ins** to record new stock arrivals (e.g., from suppliers).
*   **Stock Out**: Use **Inventory Outs** to record stock reductions (e.g., sales, usage).
*   **Stock Move**: Use **Inventory Movements** to track internal transfers between locations.

*   **Stock Card Report**: A detailed log of every movement for a specific item at a specific location.
*   **Attendance Recap**: Generate monthly attendance summaries for all employees with PDF and Excel exports.
*   **Impersonation**: Super Admins can use the "Impersonate" action in the Users table to view the system as another user for troubleshooting.
*   **Exports**: Most tables support **PDF** and **Excel** exports for offline analysis or auditing.

---

## 3. Mobile Application (Flutter)

The mobile app is optimized for fast, on-the-floor operations like scanning and quick stock updates.

### 📱 Dashboard & Navigation
The dashboard provides a quick overview of total products and movements. Large action buttons allow you to jump directly into common tasks:
*   **Catalog**: Browse products and view detailed information.
*   **Stock In / Out**: Quickly record transactions while physically handling items.
*   **Stock Opname**: The primary tool for periodic stock counts.

### 🔍 Product Scanner
Use the camera icon (if available) or the search bar in the Catalog to find products quickly by SKU or QR Code.

### 📝 Recording Transactions
1.  Select **Stock In** or **Stock Out** from the dashboard.
2.  Choose the **Location**.
3.  Add items by searching or scanning.
4.  Enter the **Quantity**. You can toggle between Primary and Secondary units if a conversion ratio is defined.
5.  Review the items and tap **Submit**.

### 📍 Smart Attendance (Check-In / Out)
1.  Tap **Check In / Out** from the dashboard.
2.  The app automatically detects the nearest **Office**.
3.  **Advanced Face Verification**:
    *   The camera will **only turn green** when a real human face is detected.
    *   **Requirements**: You must face the camera directly (upright), eyes and mouth must be visible, and you must be close enough (approx. 30cm - 50cm).
    *   **Anti-Friction**: The system automatically ignores non-human patterns like ceiling tiles or square lights using built-in "Humanity Checks".
4.  **Geofencing**: You must be within the office radius (e.g., 50m) to check in or out.
5.  **Instant Feedback**: After capture, the system shows your similarity percentage. Success requires at least **80%** match.

### 📅 Attendance History
*   Access your personal attendance logs via the **History** button on the dashboard.
*   Records are grouped by **Month** for easy viewing.
*   Includes check-in/out times, absence details, and working hours.

### 🤒 Leave & Permissions (Izin)
1.  Tap **Izin** to request time off (Sick or Permission).
2.  Select the date range and reason.
3.  **Photos**: You can upload multiple photos (e.g., doctor's note) directly from your camera.

### 👤 Impersonation (Super Admin Only)
*   Super Admins can find the **Impersonate User** button in the **Profile** screen.
*   This allows admins to switch to any user's account on the mobile app to verify their view and permissions.
*   To stop impersonating, simply Log Out.

---

## 4. Frequently Asked Questions (FAQ)

**Q: I entered a quantity in "Boxes", but it shows as "Pcs" in the report. Why?**
**A**: The system converts everything to the Primary Unit for database storage to ensure accuracy. If your product has a conversion ratio of 12, 1 Box will appear as 12 Pcs in the logs.

**Q: Can I add a new product from the mobile app?**
**A**: Yes! High-level users can create new products directly from the mobile catalog, including uploading photos.

**Q: How do I fix a mistake in a submitted transaction?**
**A**: Transactions should be "reversed" by creating a counter-transaction (e.g., if you mistakenly Stocked In 10 Pcs, perform a Stock Out of 10 Pcs with a note explaining the error).

---

## 5. Support & Troubleshooting
If you encounter any technical issues or need further assistance:
*   Check your internet connection (Mobile).
*   Contact your system administrator for permission resets.
*   Refer to the [Technical README](../README.md) for server-side maintenance.
