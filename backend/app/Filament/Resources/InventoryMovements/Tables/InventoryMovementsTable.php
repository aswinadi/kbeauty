<?php

namespace App\Filament\Resources\InventoryMovements\Tables;

use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Tables\Table;

class InventoryMovementsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                \Filament\Tables\Columns\TextColumn::make('product.name')
                    ->searchable()
                    ->sortable(),
                \Filament\Tables\Columns\TextColumn::make('type')
                    ->badge()
                    ->color(fn(string $state): string => match ($state) {
                        'IN', 'PURCHASE', 'manual_in' => 'success',
                        'OUT', 'manual_out' => 'danger',
                        'MOVE', 'TRANSFER' => 'info',
                        'OPNAME' => 'warning',
                        default => 'gray',
                    })
                    ->sortable(),
                \Filament\Tables\Columns\TextColumn::make('user.name')
                    ->label('Responsible User')
                    ->placeholder('System')
                    ->sortable(),
                \Filament\Tables\Columns\TextColumn::make('qty')
                    ->numeric()
                    ->sortable(),
                \Filament\Tables\Columns\TextColumn::make('fromLocation.name')
                    ->placeholder('N/A')
                    ->sortable(),
                \Filament\Tables\Columns\TextColumn::make('toLocation.name')
                    ->placeholder('N/A')
                    ->sortable(),
                \Filament\Tables\Columns\TextColumn::make('reference_type')
                    ->label('Reference')
                    ->formatStateUsing(fn($state, $record) => $state ? class_basename($state) . " #{$record->reference_id}" : 'Manual Adjustment'),
                \Filament\Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable(),
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
