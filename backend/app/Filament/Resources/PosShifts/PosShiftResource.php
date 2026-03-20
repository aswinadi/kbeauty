<?php

namespace App\Filament\Resources\PosShifts;

use App\Filament\Resources\PosShifts\Pages\CreatePosShift;
use App\Filament\Resources\PosShifts\Pages\EditPosShift;
use App\Filament\Resources\PosShifts\Pages\ListPosShifts;
use App\Models\PosShift;
use Filament\Resources\Resource;
use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Actions\EditAction;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;

class PosShiftResource extends Resource
{
    protected static ?string $model = PosShift::class;

    public static function getNavigationGroup(): ?string
    {
        return 'Operations';
    }

    public static function getModelLabel(): string
    {
        return 'Cashier Shift';
    }

    protected static string|\BackedEnum|null $navigationIcon = 'heroicon-o-clock';

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Shift Details')
                    ->components([
                        Select::make('user_id')
                            ->relationship('user', 'name')
                            ->required()
                            ->searchable()
                            ->preload(),
                        DateTimePicker::make('start_time')
                            ->required(),
                        DateTimePicker::make('end_time'),
                        TextInput::make('starting_cash')
                            ->numeric()
                            ->required()
                            ->default(0)
                            ->prefix('Rp'),
                        TextInput::make('ending_cash')
                            ->numeric()
                            ->prefix('Rp'),
                        Select::make('status')
                            ->options([
                                'open' => 'Open',
                                'closed' => 'Closed',
                            ])
                            ->required()
                            ->default('open'),
                    ])->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('user.name')
                    ->label('Cashier')
                    ->sortable(),
                TextColumn::make('start_time')
                    ->dateTime()
                    ->sortable(),
                TextColumn::make('end_time')
                    ->dateTime()
                    ->sortable(),
                TextColumn::make('status')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'open' => 'success',
                        'closed' => 'gray',
                    }),
                TextColumn::make('starting_cash')
                    ->money('idr'),
                TextColumn::make('ending_cash')
                    ->money('idr'),
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

    public static function getPages(): array
    {
        return [
            'index' => ListPosShifts::route('/'),
            'create' => CreatePosShift::route('/create'),
            'edit' => EditPosShift::route('/{record}/edit'),
        ];
    }
}
