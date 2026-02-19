<?php

namespace App\Filament\Resources\StockOpnames\Pages;

use App\Traits\HasStandardPageActions;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;

class EditStockOpname extends EditRecord
{
    use HasStandardPageActions;

    protected static string $resource = StockOpnameResource::class;

    protected function getHeaderActions(): array
    {
        return [
            $this->getBackAction(),
            DeleteAction::make(),
        ];
    }
}
