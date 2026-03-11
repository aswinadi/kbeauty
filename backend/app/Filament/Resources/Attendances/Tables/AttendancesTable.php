<?php

namespace App\Filament\Resources\Attendances\Tables;

use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Tables\Filters\SelectFilter;

class AttendancesTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('employee.user.name')
                    ->label(__('messages.models.employee'))
                    ->searchable()
                    ->sortable(),
                TextColumn::make('office.name')
                    ->label(__('messages.models.office'))
                    ->searchable()
                    ->sortable(),
                TextColumn::make('date')
                    ->label(__('messages.attendance.date'))
                    ->date()
                    ->sortable(),
                TextColumn::make('check_in')
                    ->label(__('messages.attendance.check_in'))
                    ->time(),
                TextColumn::make('check_out')
                    ->label(__('messages.attendance.check_out'))
                    ->time(),
                TextColumn::make('status')
                    ->label(__('messages.attendance.status'))
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'present' => 'success',
                        'late' => 'warning',
                        'early_out' => 'danger',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => __("messages.attendance.{$state}")),
            ])
            ->filters([
                SelectFilter::make('office_id')
                    ->label(__('messages.models.office'))
                    ->relationship('office', 'name'),
                SelectFilter::make('status')
                    ->label(__('messages.attendance.status'))
                    ->options([
                        'present' => __('messages.attendance.present'),
                        'late' => __('messages.attendance.late'),
                        'early_out' => __('messages.attendance.early_out'),
                    ]),
            ])
            ->recordActions([
                EditAction::make(),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ]);
    }
}
