# KBeauty Inventory System

A comprehensive inventory management system with a Laravel/Filament backend and a Flutter mobile application.

## Key Features

### 📦 Product Management
- Full catalog management via Filament dashboard.
- **Mobile Creation**: Add new products directly from the Android app, including image uploads and category assignment.
- **Multi-UOM Support**: Configure Primary (Smallest) and Secondary (Larger) units of measure (e.g., Pcs and Box).
- **Automated SKU**: Standardized SKU generation for new products.

### 🔄 Inventory Tracking & Attendance
- **Stock Opname**: Mobile-first stock counting with support for dual-unit entry. Automatically calculates totals based on conversion ratios.
- **Stock Balance**: Real-time stock visibility per location with intuitive unit breakdowns (e.g., "1 Box 5 Pcs").
- **Movement Tracking**: Logging of stock-in, stock-out, and internal movements (Card Report).
- **Secure Attendance**: Geofenced check-in/out with **Advanced Face Recognition** (Triple-lock landmark detection + RGB similarity scoring).

### 📊 Reporting & Exports
- **Stock Card Report**: Detailed table view with location-based filtering.
- **Export Formats**: Professional PDF and Excel exports for inventory records.

## Technical Architecture

- **Backend**: Laravel 11, Filament PHP v4, MariaDB/MySQL.
- **Mobile**: Flutter, Provider pattern for state management.
- **Media**: Spatie Media Library for product images.
- **UOM Philosophy**: "Smallest-Unit-First". The `Primary Unit` always stores the smallest base unit to ensure 100% database integrity and avoid floating-point rounding issues.

## Getting Started

Refer to the [deployment_guide.md](./deployment_guide.md) for server setup and application deployment instructions.
