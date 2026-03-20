<?php

namespace App\Filament\Resources\PosShifts\Pages;

use App\Filament\Resources\PosShifts\PosShiftResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;

class ListPosShifts extends ListRecords
{
    protected static string $resource = PosShiftResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make(),
        ];
    }
}
