<?php

namespace App\Filament\Widgets;

use App\Models\PosTransaction;
use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;
use Illuminate\Support\Number;

class PosStatsOverview extends StatsOverviewWidget
{
    protected function getStats(): array
    {
        $today = now()->toDateString();
        $startOfMonth = now()->startOfMonth()->toDateTimeString();
        $endOfMonth = now()->endOfMonth()->toDateTimeString();

        $todaySales = PosTransaction::whereDate('created_at', $today)->sum('final_amount');
        $mtdSales = PosTransaction::whereBetween('created_at', [$startOfMonth, $endOfMonth])->sum('final_amount');

        return [
            Stat::make('Today Sales', 'Rp ' . number_format($todaySales, 0, ',', '.'))
                ->description('Total sales generated today')
                ->descriptionIcon('heroicon-m-currency-dollar')
                ->color('success'),
            Stat::make('MTD Sales', 'Rp ' . number_format($mtdSales, 0, ',', '.'))
                ->description('Total sales this month')
                ->descriptionIcon('heroicon-m-banknotes')
                ->color('info'),
        ];
    }
}
