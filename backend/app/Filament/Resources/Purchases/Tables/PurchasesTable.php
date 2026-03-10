<?php

namespace App\Filament\Resources\Purchases\Tables;

use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Tables\Table;

class PurchasesTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                \Filament\Tables\Columns\TextColumn::make('supplier.name')
                    ->label(__('messages.fields.supplier'))
                    ->searchable()
                    ->sortable(),
                \Filament\Tables\Columns\TextColumn::make('buying_date')
                    ->label(__('messages.fields.buying_date'))
                    ->date()
                    ->sortable(),
                \Filament\Tables\Columns\TextColumn::make('total_amount')
                    ->label(__('messages.fields.total_amount'))
                    ->money('idr')
                    ->sortable(),
                \Filament\Tables\Columns\TextColumn::make('items_count')
                    ->counts('items')
                    ->label(__('messages.fields.items')),
                \Filament\Tables\Columns\TextColumn::make('created_at')
                    ->label(__('messages.fields.created_at'))
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
