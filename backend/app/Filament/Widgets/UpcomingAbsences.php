<?php

namespace App\Filament\Widgets;

use App\Models\AbsentAttendance;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget;
use Illuminate\Database\Eloquent\Builder;

class UpcomingAbsences extends TableWidget
{
    protected static ?string $heading = 'Izin Mendatang';

    protected int | string | array $columnSpan = 'half';

    public function table(Table $table): Table
    {
        return $table
            ->query(
                AbsentAttendance::query()
                    ->where('date', '>=', now()->toDateString())
                    ->orderBy('date', 'asc')
                    ->limit(5)
            )
            ->columns([
                TextColumn::make('date')
                    ->label('Tanggal')
                    ->date('d M Y')
                    ->sortable(),
                TextColumn::make('employee.full_name')
                    ->label('Karyawan')
                    ->weight('bold'),
                TextColumn::make('type')
                    ->label('Tipe')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'sick' => 'danger',
                        'leave' => 'info',
                        'izin' => 'warning',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'sick' => 'Sakit',
                        'leave' => 'Cuti',
                        'izin' => 'Izin',
                        default => $state,
                    }),
            ])
            ->paginated(false);
    }
}
