<?php

namespace App\Filament\Resources\Units\Pages;

use App\Filament\Resources\Units\UnitResource;
use App\Traits\HasStandardPageActions;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;

class EditUnit extends EditRecord
{
    use HasStandardPageActions;

    protected static string $resource = UnitResource::class;

    protected function getHeaderActions(): array
    {
        return [
            $this->getBackAction(),
            DeleteAction::make(),
        ];
    }
}
