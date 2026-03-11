<?php

namespace App\Filament\Resources\Employees\Tables;

use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Columns\SpatieMediaLibraryImageColumn;
use Filament\Tables\Table;

class EmployeesTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                SpatieMediaLibraryImageColumn::make('photo')
                    ->label(__('messages.fields.image'))
                    ->collection('photo')
                    ->circular(),
                TextColumn::make('user.name')
                    ->label(__('messages.models.user'))
                    ->searchable()
                    ->sortable(),
                TextColumn::make('office.name')
                    ->label(__('messages.models.office'))
                    ->searchable()
                    ->sortable(),
                TextColumn::make('nik')
                    ->label(__('messages.attendance.nik'))
                    ->searchable()
                    ->sortable(),
                TextColumn::make('phone')
                    ->label(__('messages.fields.phone'))
                    ->searchable(),
                TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                //
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
