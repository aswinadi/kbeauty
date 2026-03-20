<?php

namespace App\Filament\Resources\AttendanceShifts\Pages;

use App\Filament\Resources\AttendanceShiftResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;

class ListAttendanceShifts extends ListRecords
{
    protected static string $resource = AttendanceShiftResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make(),
        ];
    }
}
