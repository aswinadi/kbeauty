<?php

namespace App\Filament\Resources\Units\Pages;

use App\Traits\HasStandardPageActions;
use Filament\Resources\Pages\CreateRecord;

class CreateUnit extends CreateRecord
{
    use HasStandardPageActions;

    protected static string $resource = UnitResource::class;

    protected function getHeaderActions(): array
    {
        return [
            $this->getBackAction(),
        ];
    }
}
