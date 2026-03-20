<?php

namespace App\Filament\Resources\PosShifts\Pages;

use App\Filament\Resources\PosShifts\PosShiftResource;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;

class EditPosShift extends EditRecord
{
    protected static string $resource = PosShiftResource::class;

    protected function getHeaderActions(): array
    {
        return [
            DeleteAction::make(),
        ];
    }
}
