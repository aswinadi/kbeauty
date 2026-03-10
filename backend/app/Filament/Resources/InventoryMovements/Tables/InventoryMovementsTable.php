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
                    ->label(__('messages.fields.responsible_user'))
                    ->placeholder(__('messages.placeholders.system'))
                    ->sortable(),
                \Filament\Tables\Columns\TextColumn::make('qty')
                    ->numeric()
                    ->sortable(),
                \Filament\Tables\Columns\TextColumn::make('fromLocation.name')
                    ->label(__('messages.fields.from_location'))
                    ->placeholder(__('messages.placeholders.n_a'))
                    ->sortable(),
                \Filament\Tables\Columns\TextColumn::make('toLocation.name')
                    ->label(__('messages.fields.to_location'))
                    ->placeholder(__('messages.placeholders.n_a'))
                    ->sortable(),
                \Filament\Tables\Columns\TextColumn::make('reference_type')
                    ->label(__('messages.fields.reference'))
                    ->formatStateUsing(fn($state, $record) => $state ? class_basename($state) . " #{$record->reference_id}" : __('messages.placeholders.manual_adjustment')),
                \Filament\Tables\Columns\TextColumn::make('created_at')
                    ->label(__('messages.fields.created_at'))
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
