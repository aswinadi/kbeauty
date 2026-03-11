<?php

namespace App\Filament\Resources\Shifts;

use App\Filament\Resources\Shifts\Pages\ListShifts;
use App\Models\Shift;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Tables\Table;
use Filament\Tables\Columns\TextColumn;
use Filament\Forms\Form;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\TimePicker;
use Filament\Forms\Components\CheckboxList;
use Filament\Schemas\Schema;
use Filament\Actions\EditAction;
use Filament\Actions\DeleteAction;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use App\Filament\Resources\Shifts\Pages\ManageShifts;

class ShiftResource extends Resource
{
    protected static ?string $model = Shift::class;

    protected static string|BackedEnum|null $navigationIcon = 'heroicon-o-clock';

    public static function getNavigationGroup(): ?string
    {
        return __('messages.navigation_groups.attendance');
    }

    public static function getModelLabel(): string
    {
        return 'Shift';
    }

    public static function getPluralModelLabel(): string
    {
        return 'Shift';
    }

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('name')
                    ->label('Nama Shift')
                    ->required()
                    ->maxLength(255),
                TimePicker::make('start_time')
                    ->label('Jam Masuk')
                    ->required(),
                TimePicker::make('end_time')
                    ->label('Jam Pulang')
                    ->required(),
                CheckboxList::make('working_days')
                    ->label('Hari Kerja')
                    ->options([
                        'Monday' => 'Senin',
                        'Tuesday' => 'Selasa',
                        'Wednesday' => 'Rabu',
                        'Thursday' => 'Kamis',
                        'Friday' => 'Jumat',
                        'Saturday' => 'Sabtu',
                        'Sunday' => 'Minggu',
                    ])
                    ->required()
                    ->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('name')
                    ->label('Nama Shift')
                    ->sortable()
                    ->searchable(),
                TextColumn::make('start_time')
                    ->label('Mulai')
                    ->time('H:i'),
                TextColumn::make('end_time')
                    ->label('Selesai')
                    ->time('H:i'),
                TextColumn::make('working_days')
                    ->label('Hari Kerja')
                    ->badge(),
            ])
            ->filters([])
            ->actions([
                EditAction::make(),
                DeleteAction::make(),
            ])
            ->bulkActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => ManageShifts::route('/'),
        ];
    }
}
