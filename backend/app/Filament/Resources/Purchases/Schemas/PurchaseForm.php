<?php

namespace App\Filament\Resources\Purchases\Schemas;

use Filament\Forms\Get;
use Filament\Forms\Set;
use Filament\Schemas\Schema;

class PurchaseForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                \Filament\Forms\Components\Select::make('supplier_id')
                    ->label(__('messages.fields.supplier'))
                    ->relationship('supplier', 'name')
                    ->required()
                    ->searchable()
                    ->preload(),
                \Filament\Forms\Components\DatePicker::make('buying_date')
                    ->label(__('messages.fields.buying_date'))
                    ->required()
                    ->default(now()),
                \Filament\Forms\Components\TextInput::make('total_amount')
                    ->label(__('messages.fields.total_amount'))
                    ->numeric()
                    ->readOnly()
                    ->prefix('Rp')
                    ->default(0),
                \Filament\Forms\Components\Textarea::make('notes')
                    ->label(__('messages.fields.notes'))
                    ->maxLength(65535)
                    ->columnSpanFull(),

                \Filament\Forms\Components\Repeater::make('items')
                    ->label(__('messages.fields.items'))
                    ->relationship()
                    ->schema([
                        \Filament\Forms\Components\Select::make('product_id')
                            ->label(__('messages.fields.product'))
                            ->relationship('product', 'name')
                            ->required()
                            ->searchable()
                            ->preload()
                            ->reactive()
                            ->afterStateUpdated(
                                fn($state, Set $set) =>
                                $set('price', \App\Models\Product::find($state)?->price ?? 0)
                            ),
                        \Filament\Forms\Components\TextInput::make('qty')
                            ->label(__('messages.fields.quantity'))
                            ->numeric()
                            ->required()
                            ->default(1)
                            ->reactive()
                            ->afterStateUpdated(
                                fn($state, Get $get, Set $set) =>
                                $set('subtotal', $state * $get('price'))
                            ),
                        \Filament\Forms\Components\TextInput::make('price')
                            ->label(__('messages.fields.price'))
                            ->numeric()
                            ->required()
                            ->prefix('Rp')
                            ->reactive()
                            ->afterStateUpdated(
                                fn($state, Get $get, Set $set) =>
                                $set('subtotal', $state * $get('qty'))
                            ),
                        \Filament\Forms\Components\TextInput::make('subtotal')
                            ->label(__('messages.fields.subtotal'))
                            ->numeric()
                            ->readOnly()
                            ->prefix('Rp')
                            ->required(),
                    ])
                    ->columns(4)
                    ->columnSpanFull()
                    ->afterStateUpdated(function (Get $get, Set $set) {
                        $items = $get('items');
                        $total = collect($items)->sum('subtotal');
                        $set('total_amount', $total);
                    }),
            ]);
    }
}
