<?php

namespace App\Filament\Resources\InventoryMovements\Pages;

use App\Traits\HasStandardPageActions;
use Filament\Resources\Pages\CreateRecord;

class CreateInventoryMovement extends CreateRecord
{
    use HasStandardPageActions;

    protected static string $resource = InventoryMovementResource::class;

    protected function getHeaderActions(): array
    {
        return [
            $this->getBackAction(),
        ];
    }
}
