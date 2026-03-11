<?php

namespace App\Filament\Resources\AttendanceRecaps;

use App\Filament\Resources\AttendanceRecaps\Pages\ListAttendanceRecaps;
use App\Models\AttendanceRecap;
use Filament\Resources\Resource;
use Filament\Tables\Table;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\Filter;
use Filament\Forms\Components\DatePicker;
use App\Models\Office;
use App\Models\Employee;
use Filament\Tables\Filters\SelectFilter;
use Illuminate\Database\Eloquent\Builder;
use BackedEnum;

class AttendanceRecapResource extends Resource
{
    protected static ?string $model = AttendanceRecap::class;

    protected static string|BackedEnum|null $navigationIcon = 'heroicon-o-document-chart-bar';

    public static function getNavigationGroup(): ?string
    {
        return __('messages.navigation_groups.reports');
    }

    public static function getModelLabel(): string
    {
        return 'Rekap Kehadiran';
    }

    public static function getPluralModelLabel(): string
    {
        return 'Rekap Kehadiran';
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('date')
                    ->label(__('messages.attendance.date'))
                    ->date()
                    ->sortable(),
                TextColumn::make('employee.full_name')
                    ->label(__('messages.models.employee'))
                    ->searchable()
                    ->sortable(),
                TextColumn::make('office.name')
                    ->label(__('messages.models.office'))
                    ->sortable(),
                TextColumn::make('type')
                    ->label(__('messages.attendance.type'))
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'present' => 'success',
                        'late' => 'warning',
                        'early_out' => 'info',
                        'sick' => 'danger',
                        'leave' => 'info',
                        'izin', 'sakit', 'cuti' => 'info', // Adjusting for actual values in mobile
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'present' => 'Hadir',
                        'late', 'datang terlambat' => 'Terlambat',
                        'early_out', 'pulang awal' => 'Pulang Awal',
                        'sick', 'sakit' => 'Sakit',
                        'leave', 'cuti' => 'Cuti',
                        'izin' => 'Izin',
                        default => $state,
                    }),
                TextColumn::make('check_in')
                    ->label(__('messages.attendance.check_in'))
                    ->time('H:i')
                    ->placeholder('-'),
                TextColumn::make('check_out')
                    ->label(__('messages.attendance.check_out'))
                    ->time('H:i')
                    ->placeholder('-'),
                TextColumn::make('remark')
                    ->label(__('messages.fields.notes'))
                    ->wrap()
                    ->placeholder('-'),
            ])
            ->filters([
                Filter::make('date_range')
                    ->form([
                        DatePicker::make('from')->label('Dari'),
                        DatePicker::make('to')->label('Hingga'),
                    ])
                    ->query(function (Builder $query, array $data): Builder {
                        return $query
                            ->when(
                                $data['from'],
                                fn (Builder $query, $date): Builder => $query->whereDate('date', '>=', $date),
                            )
                            ->when(
                                $data['to'],
                                fn (Builder $query, $date): Builder => $query->whereDate('date', '<=', $date),
                            );
                    }),
                SelectFilter::make('office_id')
                    ->label(__('messages.models.office'))
                    ->relationship('office', 'name'),
                SelectFilter::make('employee_id')
                    ->label(__('messages.models.employee'))
                    ->relationship('employee', 'full_name') // Using full_name added earlier
                    ->searchable()
                    ->preload(),
            ])
            ->actions([])
            ->bulkActions([])
            ->defaultSort('date', 'desc')
            ->groups([
                'date',
                'employee.full_name',
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListAttendanceRecaps::route('/'),
        ];
    }
}
