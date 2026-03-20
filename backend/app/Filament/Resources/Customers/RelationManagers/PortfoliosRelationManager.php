<?php

namespace App\Filament\Resources\Customers\RelationManagers;

use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\Select;
use Filament\Tables\Columns\ImageColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Schemas\Schema;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Actions\CreateAction;
use Filament\Actions\EditAction;
use Filament\Actions\DeleteAction;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;

class PortfoliosRelationManager extends RelationManager
{
    protected static string $relationship = 'portfolios';

    protected static ?string $recordTitleAttribute = 'notes';

    public function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                \Filament\Forms\Components\SpatieMediaLibraryFileUpload::make('image')
                    ->collection('portfolio_images')
                    ->multiple()
                    ->image()
                    ->label('Photos')
                    ->columnSpanFull(),
                Textarea::make('notes')
                    ->maxLength(65535)
                    ->columnSpanFull(),
                Select::make('pos_transaction_id')
                    ->relationship('posTransaction', 'transaction_number')
                    ->label('Related Transaction')
                    ->placeholder('Select transaction (optional)'),
            ]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->columns([
                \Filament\Tables\Columns\SpatieMediaLibraryImageColumn::make('images')
                    ->collection('portfolio_images')
                    ->label('Photos')
                    ->circular()
                    ->stacked(),
                TextColumn::make('notes')
                    ->limit(50),
                TextColumn::make('posTransaction.transaction_number')
                    ->label('Transaction'),
                TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable(),
            ])
            ->filters([
                //
            ])
            ->headerActions([
                CreateAction::make(),
            ])
            ->recordActions([
                EditAction::make(),
                DeleteAction::make(),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ]);
    }
}
