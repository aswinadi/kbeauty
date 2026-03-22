<?php

namespace App\Filament\Resources\CustomerPortfolios\Pages;

use App\Filament\Resources\CustomerPortfolios\CustomerPortfolioResource;
use Filament\Resources\Pages\CreateRecord;

class CreateCustomerPortfolio extends CreateRecord
{
    protected static string $resource = CustomerPortfolioResource::class;
}
