<?php

namespace App\Filament\Resources\Products\Schemas;

use Filament\Schemas\Schema;

class ProductForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                \Filament\Forms\Components\Select::make('category_id')
                    ->relationship('category', 'name')
                    ->required()
                    ->searchable()
                    ->preload(),
                \Filament\Forms\Components\TextInput::make('name')
                    ->required()
                    ->maxLength(255),
                \Filament\Forms\Components\TextInput::make('sku')
                    ->label('SKU')
                    ->placeholder('Auto-generated')
                    ->disabled()
                    ->dehydrated(false)
                    ->maxLength(255),
                \Filament\Forms\Components\Select::make('unit_id')
                    ->label('Unit')
                    ->relationship('unit', 'name')
                    ->required()
                    ->searchable()
                    ->preload(),
                \Filament\Forms\Components\TextInput::make('price')
                    ->numeric()
                    ->default(0)
                    ->prefix('Rp'),
                \Filament\Forms\Components\SpatieMediaLibraryFileUpload::make('image')
                    ->collection('product_images')
                    ->image()
                    ->imageEditor()
                    ->columnSpanFull(),
            ]);
    }
}
