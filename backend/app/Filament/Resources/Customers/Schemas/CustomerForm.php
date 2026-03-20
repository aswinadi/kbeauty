<?php

namespace App\Filament\Resources\Customers\Schemas;

use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\KeyValue;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class CustomerForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Customer Info')
                    ->components([
                        TextInput::make('name')
                            ->required()
                            ->maxLength(255),
                        TextInput::make('phone')
                            ->tel()
                            ->maxLength(255),
                        TextInput::make('email')
                            ->email()
                            ->maxLength(255),
                        TextInput::make('loyalty_points')
                            ->numeric()
                            ->default(0)
                            ->disabled(),
                    ])->columns(2),

                Section::make('Additional Details')
                    ->components([
                        KeyValue::make('metadata')
                            ->label('Customer Preferences')
                            ->keyLabel('Category')
                            ->valueLabel('Notes'),
                    ]),
            ]);
    }
}
