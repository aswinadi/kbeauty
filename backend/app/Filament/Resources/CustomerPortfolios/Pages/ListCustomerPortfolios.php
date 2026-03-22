<?php

namespace App\Filament\Resources\CustomerPortfolios\Pages;

use App\Filament\Resources\CustomerPortfolios\CustomerPortfolioResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;

class ListCustomerPortfolios extends ListRecords
{
    protected static string $resource = CustomerPortfolioResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make(),
        ];
    }
}
