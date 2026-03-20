<?php

namespace App\Filament\Resources\AttendanceShifts\Pages;

use App\Filament\Resources\AttendanceShiftResource;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;

class EditAttendanceShift extends EditRecord
{
    protected static string $resource = AttendanceShiftResource::class;

    protected function getHeaderActions(): array
    {
        return [
            DeleteAction::make(),
        ];
    }
}
