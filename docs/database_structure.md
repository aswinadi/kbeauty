# Database Structure & Purpose

This document outlines the database schema for the KBeauty Inventory System, explaining the purpose of each table and the relationships between them.

---

## 🏗️ Core Architecture: The "Ledger-First" Design
The system uses `inventory_movements` as the single source of truth for stock levels. Every change in stock (Stock In, Stock Out, Move, Opname Adjustment) MUST record an entry in this table.

---

## 📋 Tables Overview

### 1. Product & Catalog
*   **`products`**: Stores the main item records. Each product belongs to a `category` and has a `unit` (UOM). It also stores `conversion_ratio` and `secondary_unit_id` for dual-unit tracking.
*   **`categories`**: Grouping for products (e.g., Eyelash, Tools).
*   **`units`**: Defines available Units of Measure (e.g., Pcs, Box, Gram).

### 2. Location Management
*   **`locations`**: Defines physical storage spots (e.g., Warehouse, Main Store).

### 3. Inventory Operations (The Ledger)
*   **`inventory_movements`**: The central log.
    *   `type`: IN (increase), OUT (decrease), MOVE (transfer).
    *   `from_location_id` / `to_location_id`: Tracks where stock came from and where it went.
    *   `qty`: Always stored in the **Primary (Smallest) Unit**.
    *   `reference`: Morphable relationship to the source transaction (e.g., a specific Purchase or Opname).

### 4. Grouped Transactions
*   **`inventory_transactions`**: A wrapper for bulk actions performed via the mobile app or dashboard.
*   **`inventory_transaction_items`**: The individual items contained within a transaction.

### 5. Stock Opname (Reconciliation)
*   **`stock_opnames`**: Represents a counting session at a specific location.
*   **`stock_opname_items`**: Stores the physical counts entered by users. Discrepancies between this and the ledger trigger "Adjustment" movements in the `inventory_movements` table.

*   **`purchase_items`**: Detailed items and prices in a purchase.

### 7. Human Resources & Attendance
*   **`employees`**: Central personnel records. Links to `users` and `offices`. Stores NIK, join date, and face recognition embeddings.
*   **`offices`**: Physical office locations with coordinates (`lat`, `lng`) and a `radius` (in meters) for attendance validation.
*   **`attendances`**: Daily check-in/out logs.
    *   `status`: ONTIME, LATE, EARLY_CHECKOUT.
    *   Tracks GPS coordinates for every action to ensure geofence compliance.
*   **`absent_attendances`**: Handles leaves of absence (Sick, Permission). Stores start/end dates and supporting photo documentation.
*   **`shifts`**: Defines working hours and days of the week.
*   **`holidays`**: Calendar events where attendance is not required.

---

## 🔗 Key Relationships

*   **Product → Movement**: One-to-many. A product can have many movements across different locations.
*   **Location → Movement**: A location can be the source (`from_location_id`) or destination (`to_location_id`) for many movements.
*   **Transaction → Items**: One-to-many. A single Stock-In transaction usually contains multiple items.

---

## 📏 Data Integrity Rules

1.  **Smallest-Unit-First**: All quantities in `inventory_movements` and `stock_balance` calculations MUST be in the primary unit. Secondary units (like Boxes) are only used for display and data entry logic in the UI.
2.  **Location Required**: Any movement that affects stock volume must be tied to a location.
3.  **Unique SKU**: Every product must have a unique SKU for reliable scanning and identification.
