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
                    ->label(__('messages.fields.product'))
                    ->relationship('product', 'name')
                    ->disabled(),
                \Filament\Forms\Components\Select::make('from_location_id')
                    ->label(__('messages.fields.from_location'))
                    ->relationship('fromLocation', 'name')
                    ->disabled(),
                \Filament\Forms\Components\Select::make('to_location_id')
                    ->label(__('messages.fields.to_location'))
                    ->relationship('toLocation', 'name')
                    ->disabled(),
                \Filament\Forms\Components\TextInput::make('qty')
                    ->label(__('messages.fields.quantity'))
                    ->numeric()
                    ->disabled(),
                \Filament\Forms\Components\TextInput::make('type')
                    ->label(__('messages.fields.status'))
                    ->disabled(),
            ])->columns(2);
    }
}
