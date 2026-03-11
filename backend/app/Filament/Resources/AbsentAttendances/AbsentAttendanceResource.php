<?php

namespace App\Filament\Resources\AbsentAttendances;

use App\Filament\Resources\AbsentAttendances\Pages\CreateAbsentAttendance;
use App\Filament\Resources\AbsentAttendances\Pages\EditAbsentAttendance;
use App\Filament\Resources\AbsentAttendances\Pages\ListAbsentAttendances;
use App\Filament\Resources\AbsentAttendances\Schemas\AbsentAttendanceForm;
use App\Filament\Resources\AbsentAttendances\Tables\AbsentAttendancesTable;
use App\Models\AbsentAttendance;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;

class AbsentAttendanceResource extends Resource
{
    protected static ?string $model = AbsentAttendance::class;

    protected static string|BackedEnum|null $navigationIcon = 'heroicon-o-document-text';

    public static function getNavigationGroup(): ?string
    {
        return __('messages.navigation_groups.attendance_transactions');
    }

    public static function getModelLabel(): string
    {
        return __('messages.models.absent_attendance');
    }

    public static function getPluralModelLabel(): string
    {
        return __('messages.models.absent_attendance');
    }

    public static function form(Schema $schema): Schema
    {
        return AbsentAttendanceForm::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return AbsentAttendancesTable::configure($table);
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
            'index' => ListAbsentAttendances::route('/'),
            'create' => CreateAbsentAttendance::route('/create'),
            'edit' => EditAbsentAttendance::route('/{record}/edit'),
        ];
    }
}
