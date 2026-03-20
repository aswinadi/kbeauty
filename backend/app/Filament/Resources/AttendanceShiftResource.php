<?php

namespace App\Filament\Resources;

use App\Filament\Resources\AttendanceShifts\Pages\CreateAttendanceShift;
use App\Filament\Resources\AttendanceShifts\Pages\EditAttendanceShift;
use App\Filament\Resources\AttendanceShifts\Pages\ListAttendanceShifts;
use App\Models\Shift;
use Filament\Resources\Resource;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\TimePicker;
use Filament\Forms\Components\CheckboxList;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Actions\EditAction;
use Filament\Actions\DeleteAction;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;

class AttendanceShiftResource extends Resource
{
    protected static ?string $model = Shift::class;

    protected static string|\BackedEnum|null $navigationIcon = 'heroicon-o-calendar-days';

    public static function getNavigationGroup(): ?string
    {
        return 'Attendance';
    }

    public static function getModelLabel(): string
    {
        return 'Attendance Shift';
    }

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Attendance Shift Details')
                    ->components([
                        TextInput::make('name')
                            ->required()
                            ->maxLength(255),
                        TimePicker::make('start_time')
                            ->required(),
                        TimePicker::make('end_time')
                            ->required(),
                        CheckboxList::make('working_days')
                            ->options([
                                'monday' => 'Monday',
                                'tuesday' => 'Tuesday',
                                'wednesday' => 'Wednesday',
                                'thursday' => 'Thursday',
                                'friday' => 'Friday',
                                'saturday' => 'Saturday',
                                'sunday' => 'Sunday',
                            ])
                            ->required()
                            ->columns(2),
                    ])->columns(1),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('name')
                    ->sortable()
                    ->searchable(),
                TextColumn::make('start_time')
                    ->time(),
                TextColumn::make('end_time')
                    ->time(),
                TextColumn::make('working_days')
                    ->badge()
                    ->formatStateUsing(fn ($state) => is_array($state) ? implode(', ', array_map('ucfirst', $state)) : $state),
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
            'index' => ListAttendanceShifts::route('/'),
            'create' => CreateAttendanceShift::route('/create'),
            'edit' => EditAttendanceShift::route('/{record}/edit'),
        ];
    }
}
