<?php

namespace App\Filament\Resources\StockOpnames\Schemas;

use Filament\Forms\Get;
use Filament\Forms\Set;
use Filament\Schemas\Schema;

class StockOpnameForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                \Filament\Forms\Components\Select::make('location_id')
                    ->relationship('location', 'name')
                    ->required()
                    ->searchable()
                    ->preload(),
                \Filament\Forms\Components\Hidden::make('user_id')
                    ->default(auth()->id()),
                \Filament\Forms\Components\Select::make('status')
                    ->options([
                        'pending' => 'Pending',
                        'completed' => 'Completed',
                    ])
                    ->default('pending')
                    ->required(),

                \Filament\Forms\Components\Repeater::make('items')
                    ->relationship()
                    ->schema([
                        \Filament\Forms\Components\Select::make('product_id')
                            ->relationship('product', 'name')
                            ->required()
                            ->searchable()
                            ->preload()
                            ->reactive()
                            ->afterStateUpdated(function ($state, \Filament\Forms\Set $set, \Filament\Forms\Get $get) {
                                if (!$state) {
                                    $set('system_qty', 0);
                                    $set('adjustment_qty', $get('actual_qty') ?? 0);
                                    return;
                                }

                                $locationId = $get('../../location_id');
                                if (!$locationId) {
                                    return;
                                }

                                $stock = \App\Models\InventoryMovement::where('product_id', $state)
                                    ->where('to_location_id', $locationId)
                                    ->sum('qty') -
                                    \App\Models\InventoryMovement::where('product_id', $state)
                                        ->where('from_location_id', $locationId)
                                        ->sum('qty');

                                $systemQty = $stock ?? 0;
                                $set('system_qty', $systemQty);
                                $set('adjustment_qty', ($get('actual_qty') ?? 0) - $systemQty);
                            }),
                        \Filament\Forms\Components\Hidden::make('system_qty')
                            ->default(0),
                        \Filament\Forms\Components\TextInput::make('actual_qty')
                            ->numeric()
                            ->required()
                            ->default(0)
                            ->reactive()
                            ->afterStateUpdated(
                                fn($state, \Filament\Forms\Get $get, \Filament\Forms\Set $set) =>
                                $set('adjustment_qty', $state - $get('system_qty'))
                            ),
                        \Filament\Forms\Components\Hidden::make('adjustment_qty')
                            ->default(0),
                    ])
                    ->columns(4)
                    ->columnSpanFull(),
            ]);
    }
}
