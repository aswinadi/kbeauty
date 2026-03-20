<?php

namespace App\Filament\Resources\Products\Tables;

use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Tables\Table;

class ProductsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                \Filament\Tables\Columns\IconColumn::make('is_active')
                    ->label('Status')
                    ->boolean()
                    ->sortable(),
                \Filament\Tables\Columns\SpatieMediaLibraryImageColumn::make('image')
                    ->label(__('messages.fields.image'))
                    ->collection('product_images')
                    ->circular(),
                \Filament\Tables\Columns\TextColumn::make('name')
                    ->label(__('messages.fields.name'))
                    ->searchable()
                    ->sortable(),
                \Filament\Tables\Columns\TextColumn::make('sku')
                    ->label(__('messages.fields.sku'))
                    ->searchable()
                    ->sortable(),
                \Filament\Tables\Columns\TextColumn::make('category.name')
                    ->label(__('messages.fields.category'))
                    ->searchable()
                    ->sortable(),
                \Filament\Tables\Columns\TextColumn::make('unit.name')
                    ->label(__('messages.fields.unit'))
                    ->searchable()
                    ->sortable(),
                \Filament\Tables\Columns\TextColumn::make('price')
                    ->label(__('messages.fields.price'))
                    ->money('idr')
                    ->sortable()
                    ->visible(fn() => auth()->user()->hasRole('Super Admin')),
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
