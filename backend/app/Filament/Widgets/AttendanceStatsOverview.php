<?php

namespace App\Filament\Widgets;

use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class AttendanceStatsOverview extends StatsOverviewWidget
{
    protected function getStats(): array
    {
        $today = now()->toDateString();
        
        $presentCount = \App\Models\Attendance::whereDate('date', $today)->count();
        $lateCount = \App\Models\Attendance::whereDate('date', $today)->where('status', 'late')->count();
        $absentCount = \App\Models\AbsentAttendance::whereDate('date', $today)->count();
        
        return [
            Stat::make('Hadir Hari Ini', $presentCount)
                ->description('Total karyawan masuk')
                ->descriptionIcon('heroicon-m-user-group')
                ->color('success'),
            Stat::make('Terlambat', $lateCount)
                ->description('Karyawan datang terlambat')
                ->descriptionIcon('heroicon-m-clock')
                ->color('warning'),
            Stat::make('Izin/Sakit/Cuti', $absentCount)
                ->description('Total absen hari ini')
                ->descriptionIcon('heroicon-m-calendar')
                ->color('info'),
        ];
    }
}
