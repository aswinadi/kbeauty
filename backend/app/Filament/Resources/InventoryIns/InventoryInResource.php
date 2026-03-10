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

    public static function getNavigationGroup(): ?string
    {
        return __('messages.navigation_groups.transactions');
    }

    public static function getNavigationLabel(): string
    {
        return __('messages.models.inventory_in');
    }

    public static function getModelLabel(): string
    {
        return __('messages.models.inventory_in');
    }

    public static function getPluralModelLabel(): string
    {
        return __('messages.models.inventory_in');
    }

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedPlusCircle;

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                \Filament\Forms\Components\Select::make('location_id')
                    ->label(__('messages.fields.location'))
                    ->relationship('location', 'name')
                    ->required(),
                \Filament\Forms\Components\DateTimePicker::make('transaction_date')
                    ->label(__('messages.fields.transaction_date'))
                    ->default(now())
                    ->required(),
                \Filament\Forms\Components\Textarea::make('notes')
                    ->label(__('messages.fields.notes'))
                    ->columnSpanFull(),
                \Filament\Forms\Components\Repeater::make('items')
                    ->label(__('messages.fields.items'))
                    ->relationship()
                    ->schema([
                        \Filament\Forms\Components\Select::make('product_id')
                            ->label(__('messages.fields.product'))
                            ->relationship('product', 'name')
                            ->required()
                            ->searchable(),
                        \Filament\Forms\Components\TextInput::make('qty')
                            ->label(__('messages.fields.quantity'))
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
                    ->label(__('messages.fields.transaction_date'))
                    ->dateTime()
                    ->sortable(),
                \Filament\Tables\Columns\TextColumn::make('location.name')
                    ->label(__('messages.fields.location'))
                    ->sortable(),
                \Filament\Tables\Columns\TextColumn::make('user.name')
                    ->label(__('messages.fields.responsible_user'))
                    ->sortable(),
                \Filament\Tables\Columns\TextColumn::make('items_count')
                    ->counts('items')
                    ->label(__('messages.fields.items')),
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
