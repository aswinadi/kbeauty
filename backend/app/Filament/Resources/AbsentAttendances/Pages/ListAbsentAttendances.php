<?php

namespace App\Filament\Resources\AbsentAttendances\Pages;

use App\Filament\Resources\AbsentAttendances\AbsentAttendanceResource;
use Filament\Resources\Pages\ListRecords;

class ListAbsentAttendances extends ListRecords
{
    protected static string $resource = AbsentAttendanceResource::class;

    protected function getHeaderActions(): array
    {
        return [
            \Filament\CreateAction::make(),
        ];
    }
}
