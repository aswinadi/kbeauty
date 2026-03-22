<?php

namespace App\Filament\Resources\Holidays\Pages;

use App\Filament\Resources\Holidays\HolidayResource;
use Filament\Resources\Pages\ListRecords;

class ListHolidays extends ListRecords
{
    protected static string $resource = HolidayResource::class;

    protected function getHeaderActions(): array
    {
        return [
            \Filament\CreateAction::make(),
        ];
    }
}
