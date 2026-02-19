<?php

namespace App\Filament\Resources\Suppliers\Pages;

use App\Filament\Resources\Suppliers\SupplierResource;
use App\Traits\HasStandardPageActions;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;

class EditSupplier extends EditRecord
{
    use HasStandardPageActions;

    protected static string $resource = SupplierResource::class;

    protected function getHeaderActions(): array
    {
        return [
            $this->getBackAction(),
            DeleteAction::make(),
        ];
    }
}
