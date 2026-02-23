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
                    ->label('Primary Unit')
                    ->helperText('Satuan terkecil (misal: Pcs)')
                    ->relationship('unit', 'name')
                    ->required()
                    ->searchable()
                    ->preload(),
                \Filament\Forms\Components\Select::make('secondary_unit_id')
                    ->label('Secondary Unit')
                    ->relationship('secondaryUnit', 'name')
                    ->searchable()
                    ->preload(),
                \Filament\Forms\Components\TextInput::make('conversion_ratio')
                    ->label('Conversion Ratio (1 [Secondary] = ? [Primary])')
                    ->numeric()
                    ->placeholder('e.g. 12 for 1 Box = 12 Pcs'),
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
