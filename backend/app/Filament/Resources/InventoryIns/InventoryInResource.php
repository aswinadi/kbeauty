<?php

namespace App\Filament\Resources\InventoryIns;

use App\Filament\Resources\InventoryIns\Pages\ManageInventoryIns;
use App\Models\InventoryTransaction;
use App\Models\InventoryTransactionItem;
use App\Models\InventoryMovement;
use BackedEnum;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteAction;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;

class InventoryInResource extends Resource
{
    protected static ?string $model = InventoryTransaction::class;

    protected static \UnitEnum|string|null $navigationGroup = 'Transaction';

    protected static ?string $navigationLabel = 'Inventory In';

    protected static ?string $modelLabel = 'Stock In';

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedPlusCircle;

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                \Filament\Forms\Components\Select::make('location_id')
                    ->relationship('location', 'name')
                    ->required(),
                \Filament\Forms\Components\DateTimePicker::make('transaction_date')
                    ->default(now())
                    ->required(),
                \Filament\Forms\Components\Textarea::make('notes')
                    ->columnSpanFull(),
                \Filament\Forms\Components\Repeater::make('items')
                    ->relationship()
                    ->schema([
                        \Filament\Forms\Components\Select::make('product_id')
                            ->relationship('product', 'name')
                            ->required()
                            ->searchable(),
                        \Filament\Forms\Components\TextInput::make('qty')
                            ->numeric()
                            ->required()
                            ->minValue(1),
                    ])
                    ->columns(2)
                    ->columnSpanFull()
                    ->grid(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                \Filament\Tables\Columns\TextColumn::make('transaction_date')
                    ->dateTime()
                    ->sortable(),
                \Filament\Tables\Columns\TextColumn::make('location.name')
                    ->sortable(),
                \Filament\Tables\Columns\TextColumn::make('user.name')
                    ->label('Responsible User')
                    ->sortable(),
                \Filament\Tables\Columns\TextColumn::make('items_count')
                    ->counts('items')
                    ->label('Items'),
            ])
            ->filters([
                //
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

    public static function getEloquentQuery(): \Illuminate\Database\Eloquent\Builder
    {
        return parent::getEloquentQuery()
            ->where('type', 'in');
    }

    public static function getPages(): array
    {
        return [
            'index' => ManageInventoryIns::route('/'),
        ];
    }
}
