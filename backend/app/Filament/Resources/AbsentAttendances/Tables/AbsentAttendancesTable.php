<?php

namespace App\Filament\Resources\AbsentAttendances\Tables;

use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Tables\Filters\SelectFilter;

class AbsentAttendancesTable
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
                TextColumn::make('type')
                    ->label(__('messages.attendance.type'))
                    ->badge()
                    ->formatStateUsing(fn (string $state): string => __("messages.attendance.{$state}")),
                TextColumn::make('status')
                    ->label(__('messages.fields.status'))
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'pending' => 'warning',
                        'approved' => 'success',
                        'rejected' => 'danger',
                        default => 'gray',
                    }),
                TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                SelectFilter::make('office_id')
                    ->label(__('messages.models.office'))
                    ->relationship('office', 'name'),
                SelectFilter::make('type')
                    ->label(__('messages.attendance.type'))
                    ->options([
                        'sick' => __('messages.attendance.sick'),
                        'leave' => __('messages.attendance.leave'),
                        'late' => __('messages.attendance.late'),
                        'early_out' => __('messages.attendance.early_out'),
                    ]),
                SelectFilter::make('status')
                    ->label(__('messages.fields.status'))
                    ->options([
                        'pending' => __('messages.status.pending'),
                        'approved' => 'Disetujui',
                        'rejected' => 'Ditolak',
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
