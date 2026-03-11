<?php

namespace App\Filament\Resources\Attendances\Schemas;

use Filament\Forms\Components\Select;
use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\TimePicker;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Schema;

class AttendanceForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('employee_id')
                    ->label(__('messages.models.employee'))
                    ->relationship('employee', 'nik')
                    ->getOptionLabelFromRecordUsing(fn ($record) => "{$record->nik} - {$record->user->name}")
                    ->required()
                    ->searchable()
                    ->preload(),
                Select::make('office_id')
                    ->label(__('messages.models.office'))
                    ->relationship('office', 'name')
                    ->required()
                    ->searchable()
                    ->preload(),
                DatePicker::make('date')
                    ->label(__('messages.attendance.date'))
                    ->required(),
                TimePicker::make('check_in')
                    ->label(__('messages.attendance.check_in')),
                TimePicker::make('check_out')
                    ->label(__('messages.attendance.check_out')),
                Select::make('status')
                    ->label(__('messages.attendance.status'))
                    ->options([
                        'present' => __('messages.attendance.present'),
                        'late' => __('messages.attendance.late'),
                        'early_out' => __('messages.attendance.early_out'),
                    ])
                    ->required(),
                TextInput::make('check_in_lat')
                    ->label('Check-in Lat')
                    ->numeric()
                    ->disabled(),
                TextInput::make('check_in_long')
                    ->label('Check-in Long')
                    ->numeric()
                    ->disabled(),
                TextInput::make('check_out_lat')
                    ->label('Check-out Lat')
                    ->numeric()
                    ->disabled(),
                TextInput::make('check_out_long')
                    ->label('Check-out Long')
                    ->numeric()
                    ->disabled(),
            ]);
    }
}
