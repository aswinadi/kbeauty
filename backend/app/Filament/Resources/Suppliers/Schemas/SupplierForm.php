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
                    ->label(__('messages.fields.name'))
                    ->required()
                    ->maxLength(255),
                \Filament\Forms\Components\TextInput::make('contact_info')
                    ->label(__('messages.fields.contact_info'))
                    ->maxLength(255),
                \Filament\Forms\Components\Textarea::make('address')
                    ->label(__('messages.fields.address'))
                    ->maxLength(65535)
                    ->columnSpanFull(),
            ]);
    }
}
