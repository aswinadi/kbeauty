<?php

namespace App\Filament\Resources\CustomerPortfolios;

use App\Filament\Resources\CustomerPortfolios\Pages\CreateCustomerPortfolio;
use App\Filament\Resources\CustomerPortfolios\Pages\EditCustomerPortfolio;
use App\Filament\Resources\CustomerPortfolios\Pages\ListCustomerPortfolios;
use App\Filament\Resources\CustomerPortfolios\Schemas\CustomerPortfolioForm;
use App\Filament\Resources\CustomerPortfolios\Tables\CustomerPortfoliosTable;
use App\Models\CustomerPortfolio;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Tables\Table;
use BackedEnum;

class CustomerPortfolioResource extends Resource
{
    protected static ?string $model = CustomerPortfolio::class;

    public static function getNavigationGroup(): ?string
    {
        return 'POS';
    }

    public static function getModelLabel(): string
    {
        return 'Customer Portfolio';
    }

    public static function getPluralModelLabel(): string
    {
        return 'Customer Portfolios';
    }

    protected static string|\BackedEnum|null $navigationIcon = 'heroicon-o-photo';

    public static function form(Schema $schema): Schema
    {
        return CustomerPortfolioForm::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return CustomerPortfoliosTable::configure($table);
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
            'index' => ListCustomerPortfolios::route('/'),
            'create' => CreateCustomerPortfolio::route('/create'),
            'edit' => EditCustomerPortfolio::route('/{record}/edit'),
        ];
    }
}
