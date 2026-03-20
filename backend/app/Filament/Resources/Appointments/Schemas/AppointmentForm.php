<?php

namespace App\Filament\Resources\Appointments\Schemas;

use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TimePicker;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Schema;

class AppointmentForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('customer_id')
                    ->label(__('messages.models.customer'))
                    ->relationship('customer', 'full_name')
                    ->required()
                    ->searchable()
                    ->preload(),
                DatePicker::make('appointment_date')
                    ->required(),
                TimePicker::make('appointment_time')
                    ->required(),
                TextInput::make('treatment_name')
                    ->required(),
                TextInput::make('pax')
                    ->numeric()
                    ->default(1)
                    ->required(),
                Toggle::make('is_paid')
                    ->required(),
                Select::make('status')
                    ->options([
            'scheduled' => 'Scheduled',
            'completed' => 'Completed',
            'cancelled' => 'Cancelled',
            'no-show' => 'No show',
        ])
                    ->default('scheduled')
                    ->required(),
                Textarea::make('notes')
                    ->columnSpanFull(),
            ]);
    }
}
