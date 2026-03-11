<?php

namespace App\Filament\Resources\AbsentAttendances\Schemas;

use Filament\Forms\Components\Select;
use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\SpatieMediaLibraryFileUpload;
use Filament\Schemas\Schema;

class AbsentAttendanceForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('employee_id')
                    ->label(__('messages.models.employee'))
                    ->relationship('employee', 'nik')
                    ->getOptionLabelFromRecordUsing(fn ($record) => ($record->nik ? "{$record->nik} - " : "") . $record->full_name)
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
                Select::make('type')
                    ->label(__('messages.attendance.type'))
                    ->options([
                        'sick' => __('messages.attendance.sick'),
                        'leave' => __('messages.attendance.leave'),
                        'late' => __('messages.attendance.late'),
                        'early_out' => __('messages.attendance.early_out'),
                    ])
                    ->required(),
                Textarea::make('reason')
                    ->label(__('messages.attendance.reason'))
                    ->maxLength(65535)
                    ->columnSpanFull(),
                Select::make('status')
                    ->label(__('messages.fields.status'))
                    ->options([
                        'pending' => __('messages.status.pending'),
                        'approved' => 'Disetujui',
                        'rejected' => 'Ditolak',
                    ])
                    ->default('pending')
                    ->required(),
                SpatieMediaLibraryFileUpload::make('attachments')
                    ->label(__('messages.fields.image'))
                    ->collection('attachments')
                    ->multiple()
                    ->columnSpanFull(),
            ]);
    }
}
