<?php

namespace App\Filament\Resources\Offices\Tables;

use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class OfficesTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('name')
                    ->label(__('messages.fields.name'))
                    ->searchable()
                    ->sortable(),
                TextColumn::make('latitude')
                    ->label(__('messages.attendance.latitude'))
                    ->sortable(),
                TextColumn::make('longitude')
                    ->label(__('messages.attendance.longitude'))
                    ->sortable(),
                TextColumn::make('radius')
                    ->label(__('messages.attendance.radius'))
                    ->sortable(),
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
