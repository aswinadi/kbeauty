<?php

namespace App\Filament\Resources\StockOpnames\Tables;

use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Tables\Table;

class StockOpnamesTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                \Filament\Tables\Columns\TextColumn::make('location.name')
                    ->label(__('messages.fields.location'))
                    ->searchable()
                    ->sortable(),
                \Filament\Tables\Columns\TextColumn::make('user.name')
                    ->label(__('messages.fields.responsible_user'))
                    ->searchable()
                    ->sortable(),
                \Filament\Tables\Columns\TextColumn::make('status')
                    ->label(__('messages.fields.status'))
                    ->formatStateUsing(fn(string $state): string => __("messages.status.{$state}"))
                    ->badge()
                    ->color(fn(string $state): string => match ($state) {
                        'pending' => 'warning',
                        'completed' => 'success',
                        default => 'gray',
                    })
                    ->sortable(),
                \Filament\Tables\Columns\TextColumn::make('items_count')
                    ->counts('items')
                    ->label(__('messages.fields.items')),
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
