<?php

namespace App\Filament\Resources\Holidays\Schemas;

use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\DatePicker;
use Filament\Schemas\Schema;

class HolidayForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('name')
                    ->label(__('messages.fields.name'))
                    ->required()
                    ->maxLength(255),
                DatePicker::make('start_date')
                    ->label(__('messages.attendance.date') . ' Mulai')
                    ->required(),
                DatePicker::make('end_date')
                    ->label(__('messages.attendance.date') . ' Selesai')
                    ->required()
                    ->afterOrEqual('start_date'),
            ]);
    }
}
