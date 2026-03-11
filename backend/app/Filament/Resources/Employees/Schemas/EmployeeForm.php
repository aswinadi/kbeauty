<?php

namespace App\Filament\Resources\Employees\Schemas;

use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\SpatieMediaLibraryFileUpload;
use Filament\Schemas\Schema;

class EmployeeForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('user_id')
                    ->label(__('messages.models.user'))
                    ->relationship('user', 'name')
                    ->required()
                    ->searchable()
                    ->preload(),
                Select::make('office_id')
                    ->label(__('messages.models.office'))
                    ->relationship('office', 'name')
                    ->required()
                    ->searchable()
                    ->preload(),
                Select::make('shift_id')
                    ->label('Shift')
                    ->relationship('shift', 'name')
                    ->required()
                    ->searchable()
                    ->preload(),
                TextInput::make('full_name')
                    ->label('Nama Lengkap')
                    ->required()
                    ->maxLength(255),
                TextInput::make('nik')
                    ->label(__('messages.attendance.nik'))
                    ->unique(ignoreRecord: true)
                    ->maxLength(255),
                \Filament\Forms\Components\DatePicker::make('join_date')
                    ->label('Tanggal Bergabung'),
                TextInput::make('phone')
                    ->label(__('messages.fields.phone'))
                    ->tel()
                    ->maxLength(255),
                SpatieMediaLibraryFileUpload::make('photo')
                    ->label(__('messages.fields.image'))
                    ->collection('photo')
                    ->avatar(),
            ]);
    }
}
