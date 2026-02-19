<?php

namespace App\Filament\Resources\Purchases\Schemas;

use Filament\Schemas\Schema;

class PurchaseForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                \Filament\Forms\Components\Section::make()
                    ->schema([
                        \Filament\Forms\Components\Select::make('supplier_id')
                            ->relationship('supplier', 'name')
                            ->required()
                            ->searchable()
                            ->preload(),
                        \Filament\Forms\Components\DatePicker::make('buying_date')
                            ->required()
                            ->default(now()),
                        \Filament\Forms\Components\TextInput::make('total_amount')
                            ->numeric()
                            ->readOnly()
                            ->prefix('Rp')
                            ->default(0),
                        \Filament\Forms\Components\Textarea::make('notes')
                            ->maxLength(65535)
                            ->columnSpanFull(),
                    ])->columns(2),

                \Filament\Forms\Components\Section::make('Purchase Items')
                    ->schema([
                        \Filament\Forms\Components\Repeater::make('items')
                            ->relationship()
                            ->schema([
                                \Filament\Forms\Components\Select::make('product_id')
                                    ->relationship('product', 'name')
                                    ->required()
                                    ->searchable()
                                    ->preload()
                                    ->reactive()
                                    ->afterStateUpdated(
                                        fn($state, \Filament\Forms\Set $set) =>
                                        $set('price', \App\Models\Product::find($state)?->price ?? 0)
                                    ),
                                \Filament\Forms\Components\TextInput::make('qty')
                                    ->numeric()
                                    ->required()
                                    ->default(1)
                                    ->reactive()
                                    ->afterStateUpdated(
                                        fn($state, \Filament\Forms\Get $get, \Filament\Forms\Set $set) =>
                                        $set('subtotal', $state * $get('price'))
                                    ),
                                \Filament\Forms\Components\TextInput::make('price')
                                    ->numeric()
                                    ->required()
                                    ->prefix('Rp')
                                    ->reactive()
                                    ->afterStateUpdated(
                                        fn($state, \Filament\Forms\Get $get, \Filament\Forms\Set $set) =>
                                        $set('subtotal', $state * $get('qty'))
                                    ),
                                \Filament\Forms\Components\TextInput::make('subtotal')
                                    ->numeric()
                                    ->readOnly()
                                    ->prefix('Rp')
                                    ->required(),
                            ])
                            ->columns(4)
                            ->columnSpanFull()
                            ->afterStateUpdated(function (\Filament\Forms\Get $get, \Filament\Forms\Set $set) {
                                $items = $get('items');
                                $total = collect($items)->sum('subtotal');
                                $set('total_amount', $total);
                            }),
                    ]),
            ]);
    }
}
