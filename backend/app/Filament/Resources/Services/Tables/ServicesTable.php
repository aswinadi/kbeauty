<?php

namespace App\Filament\Resources\Services\Tables;

use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Table;
use Filament\Actions\EditAction;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;

class ServicesTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                IconColumn::make('is_active')
                    ->label('Status')
                    ->boolean()
                    ->sortable(),
                TextColumn::make('name')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('serviceCategory.name')
                    ->label('Category')
                    ->sortable(),
                TextColumn::make('price')
                    ->money('idr')
                    ->sortable(),
                TextColumn::make('commission_value')
                    ->label('Commission')
                    ->formatStateUsing(fn ($state, $record) => $record->commission_type === 'percentage' ? "{$state}%" : 'Rp ' . number_format($state, 0, ',', '.')),
                IconColumn::make('deduct_stock')
                    ->boolean()
                    ->label('Deduct Stock'),
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
