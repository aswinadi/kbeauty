<?php

namespace App\Filament\Widgets;

use App\Models\Product;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\DB;

class LowStockAlert extends TableWidget
{
    protected static ?string $heading = 'Stok Menipis';
    
    protected int | string | array $columnSpan = 'full';

    public function table(Table $table): Table
    {
        return $table
            ->query(function () {
                // Calculate stock per product
                $stockQuery = DB::table('inventory_movements')
                    ->select('product_id', DB::raw("SUM(CASE WHEN to_location_id IS NOT NULL THEN qty ELSE -qty END) as current_stock"))
                    ->groupBy('product_id');

                return Product::query()
                    ->joinSub($stockQuery, 'stock_info', 'products.id', '=', 'stock_info.product_id')
                    ->whereColumn('stock_info.current_stock', '<=', 'products.min_stock')
                    ->where('products.min_stock', '>', 0);
            })
            ->columns([
                TextColumn::make('sku')
                    ->label('SKU')
                    ->searchable(),
                TextColumn::make('name')
                    ->label('Produk')
                    ->searchable()
                    ->weight('bold'),
                TextColumn::make('current_stock')
                    ->label('Stok Saat Ini')
                    ->numeric()
                    ->color('danger')
                    ->weight('bold'),
                TextColumn::make('min_stock')
                    ->label('Batas Minimum')
                    ->numeric()
                    ->color('gray'),
                TextColumn::make('unit.name')
                    ->label('Satuan'),
            ])
            ->paginated(false);
    }
}
