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
                    ->label(__('messages.fields.category'))
                    ->relationship('category', 'name')
                    ->required()
                    ->searchable()
                    ->preload(),
                \Filament\Forms\Components\TextInput::make('name')
                    ->label(__('messages.fields.name'))
                    ->required()
                    ->maxLength(255),
                \Filament\Forms\Components\TextInput::make('sku')
                    ->label(__('messages.fields.sku'))
                    ->placeholder(__('messages.placeholders.auto_generated'))
                    ->disabled()
                    ->dehydrated(false)
                    ->maxLength(255),
                \Filament\Forms\Components\Select::make('unit_id')
                    ->label(__('messages.fields.primary_unit'))
                    ->helperText(__('messages.fields.primary_unit_helper'))
                    ->relationship('unit', 'name')
                    ->required()
                    ->searchable()
                    ->preload(),
                \Filament\Forms\Components\Select::make('secondary_unit_id')
                    ->label(__('messages.fields.secondary_unit'))
                    ->relationship('secondaryUnit', 'name')
                    ->searchable()
                    ->preload(),
                \Filament\Forms\Components\TextInput::make('conversion_ratio')
                    ->label(__('messages.fields.conversion_ratio'))
                    ->placeholder(__('messages.fields.conversion_ratio_hint'))
                    ->numeric(),
                \Filament\Forms\Components\TextInput::make('price')
                    ->label(__('messages.fields.price'))
                    ->numeric()
                    ->default(0)
                    ->prefix('Rp')
                    ->visible(fn() => auth()->user()->hasRole('Super Admin')),
                \Filament\Forms\Components\TextInput::make('min_stock')
                    ->label(__('messages.fields.min_stock') ?? 'Minimum Stock')
                    ->numeric()
                    ->default(0)
                    ->helperText('Alert will be shown when stock goes below this level.'),
                \Filament\Forms\Components\SpatieMediaLibraryFileUpload::make('image')
                    ->label(__('messages.fields.image'))
                    ->collection('product_images')
                    ->image()
                    ->imageEditor()
                    ->imageQuality(70)
                    ->extraInputAttributes(['capture' => 'camera'])
                    ->columnSpanFull(),
            ]);
    }
}
