<?php

namespace App\Filament\Resources\PosTransactions\Pages;

use App\Filament\Resources\PosTransactions\PosTransactionResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListPosTransactions extends ListRecords
{
    protected static string $resource = PosTransactionResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make(),
        ];
    }
}
