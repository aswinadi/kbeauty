<?php

namespace App\Filament\Resources\Bundles;

use App\Filament\Resources\Bundles\Pages\CreateBundle;
use App\Filament\Resources\Bundles\Pages\EditBundle;
use App\Filament\Resources\Bundles\Pages\ListBundles;
use App\Filament\Resources\Bundles\Schemas\BundleForm;
use App\Filament\Resources\Bundles\Tables\BundlesTable;
use App\Models\Bundle;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;

class BundleResource extends Resource
{
    protected static ?string $model = Bundle::class;

    public static function getNavigationGroup(): ?string
    {
        return 'POS';
    }

    public static function getModelLabel(): string
    {
        return 'Bundle';
    }

    public static function getPluralModelLabel(): string
    {
        return 'Bundles';
    }

    protected static string|\BackedEnum|null $navigationIcon = 'heroicon-o-gift';

    public static function form(Schema $schema): Schema
    {
        return BundleForm::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return BundlesTable::configure($table);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListBundles::route('/'),
            'create' => CreateBundle::route('/create'),
            'edit' => EditBundle::route('/{record}/edit'),
        ];
    }
}
