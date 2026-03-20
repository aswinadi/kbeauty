<?php

namespace App\Filament\Resources\Services\Schemas;

use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Forms\Components\Repeater;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class ServiceForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Service Details')
                    ->components([
                        Toggle::make('is_active')
                            ->label('Active Status')
                            ->default(true)
                            ->columnSpanFull(),
                        Select::make('service_category_id')
                            ->label('Service Category')
                            ->relationship('serviceCategory', 'name')
                            ->searchable()
                            ->preload(),
                        TextInput::make('name')
                            ->required()
                            ->maxLength(255),
                        TextInput::make('price')
                            ->numeric()
                            ->required()
                            ->prefix('Rp'),
                    ])->columns(3),
                
                Section::make('Commission & Stock')
                    ->components([
                        Select::make('commission_type')
                            ->options([
                                'fixed' => 'Fixed Amount',
                                'percentage' => 'Percentage',
                            ])
                            ->required()
                            ->default('fixed')
                            ->live(),
                        TextInput::make('commission_value')
                            ->numeric()
                            ->required()
                            ->label(fn (callable $get) => $get('commission_type') === 'percentage' ? 'Commission (%)' : 'Commission (Rp)'),
                        Toggle::make('deduct_stock')
                            ->label('Deduct Stock from Inventory')
                            ->live(),
                    ])->columns(3),

                Section::make('Materials')
                    ->components([
                        Repeater::make('materials')
                            ->relationship('materials')
                            ->schema([
                                Select::make('product_id')
                                    ->relationship('product', 'name')
                                    ->required()
                                    ->searchable()
                                    ->preload(),
                                TextInput::make('quantity')
                                    ->numeric()
                                    ->required()
                                    ->default(1),
                            ])
                            ->columnSpanFull(),
                    ])
                    ->visible(fn (callable $get) => $get('deduct_stock')),
            ]);
    }
}
