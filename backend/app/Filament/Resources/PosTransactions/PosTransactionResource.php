<?php

namespace App\Filament\Resources\PosTransactions;

use App\Filament\Resources\PosTransactions\Pages\CreatePosTransaction;
use App\Filament\Resources\PosTransactions\Pages\EditPosTransaction;
use App\Filament\Resources\PosTransactions\Pages\ListPosTransactions;
use App\Filament\Resources\PosTransactions\Schemas\PosTransactionForm;
use App\Filament\Resources\PosTransactions\Tables\PosTransactionsTable;
use App\Models\PosTransaction;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;

class PosTransactionResource extends Resource
{
    protected static ?string $model = PosTransaction::class;

    public static function getNavigationGroup(): ?string
    {
        return 'POS';
    }

    public static function getModelLabel(): string
    {
        return 'Transaction';
    }

    public static function getPluralModelLabel(): string
    {
        return 'Transactions';
    }

    protected static string|\BackedEnum|null $navigationIcon = 'heroicon-o-shopping-cart';

    public static function form(Schema $schema): Schema
    {
        return PosTransactionForm::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return PosTransactionsTable::configure($table);
    }

    public static function getRelations(): array
    {
        return [
            //
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListPosTransactions::route('/'),
            'create' => CreatePosTransaction::route('/create'),
            'edit' => EditPosTransaction::route('/{record}/edit'),
        ];
    }
}
