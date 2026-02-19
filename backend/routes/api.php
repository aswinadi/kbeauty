<?php

use App\Http\Controllers\Api\AuthController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/products', [\App\Http\Controllers\Api\ProductController::class, 'index']);
    Route::get('/categories', [\App\Http\Controllers\Api\ProductController::class, 'categories']);

    Route::get('/locations', [\App\Http\Controllers\Api\StockOpnameController::class, 'locations']);
    Route::get('/stats', [\App\Http\Controllers\Api\StockOpnameController::class, 'stats']);
    Route::get('/opname-products', [\App\Http\Controllers\Api\StockOpnameController::class, 'products']);
    Route::post('/stock-opname', [\App\Http\Controllers\Api\StockOpnameController::class, 'store']);
    Route::post('/inventory/move', [\App\Http\Controllers\Api\StockOpnameController::class, 'move']);
    Route::post('/inventory/transfer', [\App\Http\Controllers\Api\StockOpnameController::class, 'transfer']);
    Route::post('/inventory/bulk-transaction', [\App\Http\Controllers\Api\StockOpnameController::class, 'bulkTransaction']);
    Route::post('/change-password', [AuthController::class, 'changePassword']);
});
