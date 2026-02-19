<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        \Filament\Tables\Columns\TextColumn::configureUsing(function (\Filament\Tables\Columns\TextColumn $column): void {
            $column->timezone('Asia/Jakarta');
        });

        \Filament\Infolists\Components\TextEntry::configureUsing(function (\Filament\Infolists\Components\TextEntry $entry): void {
            $entry->timezone('Asia/Jakarta');
        });
    }
}
