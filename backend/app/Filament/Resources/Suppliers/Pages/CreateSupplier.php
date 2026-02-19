<?php

namespace App\Filament\Resources\Suppliers\Pages;

use App\Traits\HasStandardPageActions;
use Filament\Resources\Pages\CreateRecord;

class CreateSupplier extends CreateRecord
{
    use HasStandardPageActions;

    protected static string $resource = SupplierResource::class;

    protected function getHeaderActions(): array
    {
        return [
            $this->getBackAction(),
        ];
    }
}
