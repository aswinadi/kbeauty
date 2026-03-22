<?php

use App\Http\Controllers\Api\AuthController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/offices', [\App\Http\Controllers\Api\AttendanceController::class, 'offices']);
    Route::get('/attendance/status', [\App\Http\Controllers\Api\AttendanceController::class, 'getStatus']);
    Route::get('/attendance/history', [\App\Http\Controllers\Api\AttendanceController::class, 'history']);
    Route::post('/attendance/check-in', [\App\Http\Controllers\Api\AttendanceController::class, 'checkIn']);
    Route::post('/attendance/check-out', [\App\Http\Controllers\Api\AttendanceController::class, 'checkOut']);
    Route::post('/attendance/request', [\App\Http\Controllers\Api\AttendanceController::class, 'requestAbsent']);

    Route::get('/products', [\App\Http\Controllers\Api\ProductController::class, 'index']);
    Route::post('/products', [\App\Http\Controllers\Api\ProductController::class, 'store']);
    Route::post('/products/{product}', [\App\Http\Controllers\Api\ProductController::class, 'update']);
    Route::get('/products/{product}/balance', [\App\Http\Controllers\Api\ProductController::class, 'stockBalance']);
    Route::get('/categories', [\App\Http\Controllers\Api\ProductController::class, 'categories']);
    Route::get('/units', [\App\Http\Controllers\Api\ProductController::class, 'units']);

    Route::get('/locations', [\App\Http\Controllers\Api\StockOpnameController::class, 'locations']);
    Route::get('/stats', [\App\Http\Controllers\Api\StockOpnameController::class, 'stats']);
    Route::get('/opname-products', [\App\Http\Controllers\Api\StockOpnameController::class, 'products']);
    Route::post('/stock-opname', [\App\Http\Controllers\Api\StockOpnameController::class, 'store']);
    Route::post('/inventory/move', [\App\Http\Controllers\Api\StockOpnameController::class, 'move']);
    Route::post('/inventory/transfer', [\App\Http\Controllers\Api\StockOpnameController::class, 'transfer']);
    Route::post('/inventory/bulk-transaction', [\App\Http\Controllers\Api\StockOpnameController::class, 'bulkTransaction']);
    Route::post('/change-password', [AuthController::class, 'changePassword']);
    Route::post('/profile/update-password', [AuthController::class, 'changePassword']); // Alias for clarity
    
    Route::post('/impersonate/{user}', [\App\Http\Controllers\Api\ImpersonateController::class, 'impersonate']);
    Route::get('/users', [\App\Http\Controllers\Api\ImpersonateController::class, 'index']);
    Route::get('/attendance/history', [\App\Http\Controllers\Api\AttendanceHistoryController::class, 'index']);

    // POS Routes
    Route::get('/pos/items', [\App\Http\Controllers\Api\PosController::class, 'items']);
    Route::get('/pos/customers', [\App\Http\Controllers\Api\PosController::class, 'customers']);
    Route::post('/pos/customers', [\App\Http\Controllers\Api\PosController::class, 'registerCustomer']);
    Route::get('/pos/customers/{customer}', [\App\Http\Controllers\Api\PosController::class, 'showCustomer']);
    Route::get('/pos/customers/{customer}/portfolios', [\App\Http\Controllers\Api\PosController::class, 'customerPortfolios']);
    Route::get('/pos/customers/{customer}/history', [\App\Http\Controllers\Api\PosController::class, 'customerHistory']);
    Route::post('/pos/customers/{customer}/portfolios', [\App\Http\Controllers\Api\PosController::class, 'addCustomerPortfolio']);
    Route::get('/pos/employees', [\App\Http\Controllers\Api\PosController::class, 'employees']);
    Route::post('/pos/transactions', [\App\Http\Controllers\Api\PosController::class, 'storeTransaction']);
    Route::get('/pos/transactions', [\App\Http\Controllers\Api\PosController::class, 'transactions']);
    Route::get('/pos/settings', [\App\Http\Controllers\Api\PosController::class, 'settings']);
    Route::get('/pos/performance', [\App\Http\Controllers\Api\PosController::class, 'performance']);
    Route::apiResource('/discounts', \App\Http\Controllers\Api\DiscountController::class);

    // Appointment Routes
    Route::get('/appointments', [\App\Http\Controllers\Api\AppointmentController::class, 'index']);
    Route::post('/appointments', [\App\Http\Controllers\Api\AppointmentController::class, 'store']);
    Route::patch('/appointments/{appointment}', [\App\Http\Controllers\Api\AppointmentController::class, 'update']);

    // Master Data Routes
    Route::get('/master/service-categories', [\App\Http\Controllers\Api\ServiceMasterController::class, 'categories']);
    Route::post('/master/service-categories', [\App\Http\Controllers\Api\ServiceMasterController::class, 'storeCategory']);
    Route::post('/master/service-categories/{category}', [\App\Http\Controllers\Api\ServiceMasterController::class, 'updateCategory']);
    Route::delete('/master/service-categories/{category}', [\App\Http\Controllers\Api\ServiceMasterController::class, 'deleteCategory']);

    Route::get('/master/services', [\App\Http\Controllers\Api\ServiceMasterController::class, 'services']);
    Route::post('/master/services', [\App\Http\Controllers\Api\ServiceMasterController::class, 'storeService']);
    Route::post('/master/services/{service}', [\App\Http\Controllers\Api\ServiceMasterController::class, 'updateService']);
    Route::delete('/master/services/{service}', [\App\Http\Controllers\Api\ServiceMasterController::class, 'deleteService']);
});
