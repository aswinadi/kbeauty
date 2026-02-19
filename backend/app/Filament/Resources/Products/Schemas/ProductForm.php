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
                    ->unique(ignoreRecord: true)
                    ->required()
                    ->maxLength(255),
                \Filament\Forms\Components\TextInput::make('unit')
                    ->required()
                    ->maxLength(255),
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
