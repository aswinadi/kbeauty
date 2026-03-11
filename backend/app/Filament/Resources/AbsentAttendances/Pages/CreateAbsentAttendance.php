<?php

namespace App\Filament\Resources\AbsentAttendances\Pages;

use App\Filament\Resources\AbsentAttendances\AbsentAttendanceResource;
use Filament\Resources\Pages\CreateRecord;

class CreateAbsentAttendance extends CreateRecord
{
    protected static string $resource = AbsentAttendanceResource::class;

    protected function getRedirectUrl(): string
    {
        return $this->getResource()::getUrl('index');
    }
}
