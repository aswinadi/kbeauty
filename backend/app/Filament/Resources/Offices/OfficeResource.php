<?php

namespace App\Filament\Resources\Offices;

use App\Filament\Resources\Offices\Pages\CreateOffice;
use App\Filament\Resources\Offices\Pages\EditOffice;
use App\Filament\Resources\Offices\Pages\ListOffices;
use App\Filament\Resources\Offices\Schemas\OfficeForm;
use App\Filament\Resources\Offices\Tables\OfficesTable;
use App\Models\Office;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;

class OfficeResource extends Resource
{
    protected static ?string $model = Office::class;

    protected static string|BackedEnum|null $navigationIcon = 'heroicon-o-building-office';

    public static function getNavigationGroup(): ?string
    {
        return __('messages.navigation_groups.attendance');
    }

    public static function getModelLabel(): string
    {
        return __('messages.models.office');
    }

    public static function getPluralModelLabel(): string
    {
        return __('messages.models.office');
    }

    public static function form(Schema $schema): Schema
    {
        return OfficeForm::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return OfficesTable::configure($table);
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
            'index' => ListOffices::route('/'),
            'create' => CreateOffice::route('/create'),
            'edit' => EditOffice::route('/{record}/edit'),
        ];
    }
}
