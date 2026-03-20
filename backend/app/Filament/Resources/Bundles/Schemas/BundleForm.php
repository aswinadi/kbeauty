<?php

namespace App\Filament\Resources\Bundles\Schemas;

use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Repeater;
use Filament\Forms\Components\MorphToSelect;
use App\Models\Service;
use App\Models\Product;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class BundleForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Bundle Details')
                    ->components([
                        \Filament\Forms\Components\Toggle::make('is_active')
                            ->label('Active Status')
                            ->default(true)
                            ->columnSpanFull(),
                        TextInput::make('name')
                            ->required()
                            ->maxLength(255),
                        TextInput::make('price')
                            ->numeric()
                            ->required()
                            ->prefix('Rp'),
                    ])->columns(2),

                Section::make('Bundle Items')
                    ->components([
                        Repeater::make('items')
                            ->relationship('items')
                            ->schema([
                                MorphToSelect::make('item')
                                    ->types([
                                        MorphToSelect\Type::make(Service::class)
                                            ->titleAttribute('name'),
                                        MorphToSelect\Type::make(Product::class)
                                            ->titleAttribute('name'),
                                    ])
                                    ->required(),
                                TextInput::make('quantity')
                                    ->numeric()
                                    ->required()
                                    ->default(1),
                            ])
                            ->columnSpanFull(),
                    ]),
            ]);
    }
}
