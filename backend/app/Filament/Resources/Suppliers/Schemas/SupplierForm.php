<?php

namespace App\Filament\Resources\Suppliers\Schemas;

use Filament\Schemas\Schema;

class SupplierForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                \Filament\Forms\Components\TextInput::make('name')
                    ->required()
                    ->maxLength(255),
                \Filament\Forms\Components\TextInput::make('contact_info')
                    ->maxLength(255),
                \Filament\Forms\Components\Textarea::make('address')
                    ->maxLength(65535)
                    ->columnSpanFull(),
            ]);
    }
}
