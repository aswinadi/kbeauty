<?php

namespace App\Filament\Resources\CustomerPortfolios\Pages;

use App\Filament\Resources\CustomerPortfolios\CustomerPortfolioResource;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;

class EditCustomerPortfolio extends EditRecord
{
    protected static string $resource = CustomerPortfolioResource::class;

    protected function getHeaderActions(): array
    {
        return [
            DeleteAction::make(),
        ];
    }
}
