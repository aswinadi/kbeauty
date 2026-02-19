<?php

namespace App\Filament\Resources\InventoryMovements\Schemas;

use Filament\Schemas\Schema;

class InventoryMovementForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                \Filament\Forms\Components\Select::make('product_id')
                    ->relationship('product', 'name')
                    ->disabled(),
                \Filament\Forms\Components\Select::make('from_location_id')
                    ->relationship('fromLocation', 'name')
                    ->disabled(),
                \Filament\Forms\Components\Select::make('to_location_id')
                    ->relationship('toLocation', 'name')
                    ->disabled(),
                \Filament\Forms\Components\TextInput::make('qty')
                    ->numeric()
                    ->disabled(),
                \Filament\Forms\Components\TextInput::make('type')
                    ->disabled(),
            ])->columns(2);
    }
}
