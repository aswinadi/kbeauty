<?php

namespace App\Filament\Resources\StockOpnames\Schemas;

use Filament\Schemas\Schema;

class StockOpnameForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                \Filament\Forms\Components\Group::make()
                    ->schema([
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
                    ])->columns(2),

                \Filament\Forms\Components\Fieldset::make('Stock Opname Items')
                    ->schema([
                        \Filament\Forms\Components\Repeater::make('items')
                            ->relationship()
                            ->schema([
                                \Filament\Forms\Components\Select::make('product_id')
                                    ->relationship('product', 'name')
                                    ->required()
                                    ->searchable()
                                    ->preload(),
                                \Filament\Forms\Components\TextInput::make('system_qty')
                                    ->numeric()
                                    ->required()
                                    ->default(0)
                                    ->label('System Qty'),
                                \Filament\Forms\Components\TextInput::make('actual_qty')
                                    ->numeric()
                                    ->required()
                                    ->default(0)
                                    ->reactive()
                                    ->afterStateUpdated(
                                        fn($state, \Filament\Forms\Get $get, \Filament\Forms\Set $set) =>
                                        $set('adjustment_qty', $state - $get('system_qty'))
                                    ),
                                \Filament\Forms\Components\TextInput::make('adjustment_qty')
                                    ->numeric()
                                    ->readOnly()
                                    ->label('Adjustment'),
                            ])
                            ->columns(4)
                            ->columnSpanFull(),
                    ]),
            ]);
    }
}
